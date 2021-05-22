// contracts/VoteToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./lib/Ownable.sol";

contract VoteToken is ERC20 , Ownable{

  struct voteInfo{
    uint voteNum; //投票数
    address[] voters; //投票人
  }
  mapping(uint => voteInfo) public votes_agree; //同意票
  mapping(uint => voteInfo) public votes_against; //反对票
  mapping(address => mapping(uint => bool)) public is_voted; //是否投过票
  address receiver = address(0); //接受vote币的地址
  address public admin; 

  event addAgree(uint _id,address sender,uint voteTime); //投同意票事件
  event addAgainst(uint _id,address sender,uint voteTime); //投反对票事件
  event voteThrough(uint _id,uint voteTime); //投票通过事件
  event voteNotThrough(uint _id,uint voteTime); //投票不通过事件

  constructor(uint256 initialSupply) public ERC20("VoteToken", "Vote") {
    _mint(msg.sender, initialSupply * 1 ether);
    receiver=msg.sender;
    admin = msg.sender;
  }



  // 投同意票
  function agree(uint _id) public{
    require(is_voted[msg.sender][_id]==false,"You've already voted!");
    require(balanceOf(msg.sender)>=1 ether,"You don't have enough tokens!");
    
    transfer(receiver, 1 ether);
    is_voted[msg.sender][_id]=true;
    votes_agree[_id].voters.push(msg.sender);
    votes_agree[_id].voteNum++;
  }
  
  // 投反对票
  function against(uint _id) public{
    require(is_voted[msg.sender][_id]==false,"You've already voted!");
    require(balanceOf(msg.sender)>=1 ether,"You don't have enough tokens!");

    transfer(receiver, 1 ether);
    is_voted[msg.sender][_id]=true;
    votes_against[_id].voters.push(msg.sender);
    votes_against[_id].voteNum++;
  }

  function updateReceiver(address receiverAddress) public onlyOwner {
    receiver = receiverAddress;
  }

  function addSupply(uint _num) public onlyOwner {
    _mint(msg.sender,_num * 1 ether);
  }

  // 获取对应需求的投票总数
  function getVotesCount(uint _id) public view returns(uint agreeNum ,uint againstNum){
    agreeNum=votes_agree[_id].voteNum;
    againstNum=votes_against[_id].voteNum;
  }

  // 获取总共有哪些人投了对应的需求
  function getAllVoters(uint _id) public view returns(address[] memory agree_voters,address[] memory against_voters){
    agree_voters=votes_agree[_id].voters;
    against_voters=votes_against[_id].voters;
  }
  
  //合约销毁
  function destroy() public{
    require(admin == msg.sender,"not permit");
    selfdestruct(msg.sender);
  }
}