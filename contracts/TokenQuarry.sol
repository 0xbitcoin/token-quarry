pragma solidity ^0.4.18;


/*

An ERC20 token wallet which dispenses tokens via Proof of Work mining.

Anyone can deposit any ERC20 token in this contract and they will be locked inside.   0xBitcoin miners can submit their solutions to this contract when they submit their solutions to the 0xBitcoin contract and they will then be rewarded with 5% of the ERC20 tokens of their choice which are stored in this contract. 

*/

import "./SafeMath.sol";


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract EIP918Interface {
  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);
  function getChallengeNumber() public constant returns (bytes32);
  function getMiningDifficulty() public constant returns (uint);
  function getMiningTarget() public constant returns (uint);
  function getMiningReward() public constant returns (uint);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

}

contract TokenQuarry {


  using SafeMath for uint;


  //address of the token contract
  address miningLeader = 0x0;

  //A value of 20 means the reward is 1/20 (5%) of current tokens held in the quarry
  uint rewardDivisor = 20;

  //number of times this has been mined
  uint epochCount = 0;

  mapping(bytes32 => bytes32) solutionForChallenge;



  function TokenQuarry(address leader) public  {
    miningLeader = leader;

  }


  function tokenBalance(address tokenContract) public constant returns (uint balance) {
       return ERC20Interface(tokenContract).balanceOf(this);
   }


   event Mined(address indexed from,  uint epochCount, bytes32 newChallengeNumber);


   function mineQuarry(uint256 nonce, bytes32 challenge_digest, address[] tokens) public returns (bool success) {

     bytes32 challengeNumber = getChallengeNumber();
     uint miningTarget = getMiningTarget();

     //the PoW must contain work that includes a recent ethereum block hash (challenge number) and the msg.sender's address to prevent MITM attacks
     bytes32 digest =  keccak256(challengeNumber, msg.sender, nonce );

     //the challenge digest must match the expected
     if (digest != challenge_digest) revert();

     //the digest must be smaller than the target
     if(uint256(digest) > miningTarget) revert();

     //only allow one reward for each challenge
      bytes32 solution = solutionForChallenge[challengeNumber];
      solutionForChallenge[challengeNumber] = digest;
      if(solution != 0x0) revert();  //prevent the same answer from awarding twice

      for (uint i = 0; i < tokens.length; i++)
      {
        giveReward(tokens[i],msg.sender);
      }


      /*
     uint reward_amount = getMiningReward();

     balances[msg.sender] = balances[msg.sender].add(reward_amount);

     tokensMinted = tokensMinted.add(reward_amount);

     //Cannot mint more tokens than there are
     assert(tokensMinted <= maxSupplyForEra);




     //set readonly diagnostics data
     lastRewardTo = msg.sender;
     lastRewardAmount = reward_amount;
     lastRewardEthBlockNumber = block.number;

     */

      //_startNewMiningEpoch();

      epochCount = epochCount.add(1);

       Mined(msg.sender,  epochCount, challengeNumber );

    return true;

 }



function getChallengeNumber() public constant returns (bytes32) {
  return EIP918Interface(miningLeader).getChallengeNumber();
}

function getMiningTarget() public constant returns (uint) {
  return EIP918Interface(miningLeader).getMiningTarget();
}

/*
  Could this be attacked with multiple tx in rapid succession ?
  Could check for unique eth block number
*/
function getRewardAmount(address token) public constant returns (uint)
{
  var totalBalance = tokenBalance(token);

  return totalBalance.div(rewardDivisor);
}

function giveReward(address tokenAddress,address recipient)
{
     uint amount = getRewardAmount(tokenAddress);

     ERC20Interface(tokenAddress).transfer(recipient,amount);
}


}
