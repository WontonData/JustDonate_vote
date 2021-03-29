// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.7.0;

import "./interfaces/voteCoin.sol";


contract vote {
  struct voteInfo{
    uint voteNum;
    address[] voters;
  }
  mapping(uint => voteInfo) public votes_aggree;
  mapping(uint => voteInfo) public votes_against;
  mapping(address => mapping(uint => bool)) public is_voted;

  address public voteCoinaddr;
  address public receiver;

  event addAggree(uint _id,address sender,uint voteTime);
  event addAgainst(uint _id,address sender,uint voteTime);
  event voteThrough(uint _id,uint voteTime);


  voteCoin public voteCoinToken;
  uint public coinNum = 0;
  //bbCoin bbCoin;

  constructor(address _voteCoinaddr,address _voteReceiver) public {
    voteCoinaddr = _voteCoinaddr;
    voteCoinToken = voteCoin(_voteCoinaddr);
    receiver=_voteReceiver;
  }

  function isVoteThrough(uint _id) private view returns(bool) {
    uint8 baseLineNum = 2;
    if(votes_aggree[_id].voteNum>=baseLineNum){
      return true;
    }
    return false;
  }

  function agree(uint _id) public{
    require(is_voted[msg.sender][_id]==false,"You've already voted!");
    require(voteCoinToken.balanceOf(msg.sender)>=1,"You don't have enough tokens!");
    require(voteCoinToken.allowance(msg.sender,address(this))>=1,"The allowance of the contract is insufficient!");

    voteCoinToken.transferFrom(msg.sender,receiver,1);
    is_voted[msg.sender][_id]=true;
    votes_aggree[_id].voters.push(msg.sender);
    votes_aggree[_id].voteNum++;

    emit addAggree(_id,msg.sender,now);
    if(isVoteThrough(_id)){
      emit voteThrough(_id,now);
    }
  }
  
  function against(uint _id) public{
    require(is_voted[msg.sender][_id]==false,"You've already voted!");
    require(voteCoinToken.balanceOf(msg.sender)>=1,"You don't have enough tokens!");
    require(voteCoinToken.allowance(msg.sender,address(this))>=1,"The allowance of the contract is insufficient!");

    voteCoinToken.transferFrom(msg.sender,receiver,1);
    is_voted[msg.sender][_id]=true;
    votes_against[_id].voters.push(msg.sender);
    votes_against[_id].voteNum++;

    emit addAgainst(_id,msg.sender,now);
  }

  function getVotes(uint _id) public view returns(uint aggreeNum ,uint againstNum){
    aggreeNum=votes_aggree[_id].voteNum;
    againstNum=votes_against[_id].voteNum;
  }

  function getVoters(uint _id) public view returns(address[] memory aggree_voters,address[] memory against_voters ){
    aggree_voters=votes_aggree[_id].voters;
    against_voters=votes_against[_id].voters;
  }
}