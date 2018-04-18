pragma solidity ^0.4.18;


/*

An ERC20 token wallet which dispenses tokens via Proof of Work mining.
Based on recommendation from /u/diego_91

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

     bool mintSuccess = mintMiningLeader(nonce, challenge_digest);
     if(!mintSuccess) revert();

     for (uint i = 0; i < tokens.length; i++)
     {
       giveReward(tokens[i],msg.sender);
     }

     epochCount = epochCount.add(1);

     Mined(msg.sender,  epochCount, challengeNumber );

    return true;

 }


function mintMiningLeader(uint256 nonce, bytes32 challenge_digest) public constant returns (bool) {
  return EIP918Interface(miningLeader).mint(nonce,challenge_digest);
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
