// contracts/VoteToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/DemandFactory.sol";

contract VoteToken is ERC20 {

  struct Demand {
    uint id;          //需求编号
    string username;  //发起人 or 机构 名称
    address sender;   //发起人address
    string content;   //需求内容
    string contact;   //联系方式
    uint status;      //状态号 0:初始 1：通过 2：捐赠中 3：捐赠完成 4：失败
  }
  struct voteInfo{
    uint voteNum; //投票数
    address[] voters; //投票人
  }
  mapping(uint => voteInfo) public votes_aggree; //同意票
  mapping(uint => voteInfo) public votes_against; //反对票
  mapping(address => mapping(uint => bool)) public is_voted; //是否投过票
  address receiver = address(0);
  DemandFactory demandFactory;

  event addAggree(uint _id,address sender,uint voteTime); //投同意票事件
  event addAgainst(uint _id,address sender,uint voteTime); //投反对票事件
  event voteThrough(uint _id,uint voteTime); //投票通过事件
  event voteNotThrough(uint _id,uint voteTime); //投票不通过事件

  constructor(uint256 initialSupply,address demandFactoryAddress) public ERC20("VoteToken", "Vote") {
    _mint(msg.sender, initialSupply);
    receiver=msg.sender;
    demandFactory = DemandFactory(demandFactoryAddress);
    
  }

  // 获取投票状态 0:初始 1：通过 2：捐赠中 3：捐赠完成 4：失败
  function getVoteStatus(uint _id) private view returns(uint8 status) {
    uint  id;          //需求编号
    string memory username;  //发起人 or 机构 名称
    address  sender;   //发起人address
    string memory content;   //需求内容
    string memory contact;   //联系方式
    uint  getStatus;      //状态号 0:初始 1：通过 2：捐赠中 3：捐赠完成 4：失败
    (id,username,sender,content,contact,getStatus) = demandFactory.demands(_id);
    uint8 passBaseLineNum = 2;
    uint8 failBaseLineNum = 2;

    if(getStatus!=0 && getStatus!=2){
      return uint8(getStatus);
    }else{
      //还能投票
      if(
        votes_aggree[_id].voteNum<passBaseLineNum &&
        votes_against[_id].voteNum<failBaseLineNum
      ){
        return 2;
      }else if(votes_aggree[_id].voteNum>=passBaseLineNum){
        return 1;
      }
    }
    
    return 4;

  }


  // 投同意票
  function aggree(uint _id) public{
    require(getVoteStatus(_id)==0 || getVoteStatus(_id)==2,"vote closed");
    require(is_voted[msg.sender][_id]==false,"You've already voted!");
    require(balanceOf(msg.sender)>=1,"You don't have enough tokens!");

    _burn(msg.sender, 1);
    //_mint(receiver, 1);
    is_voted[msg.sender][_id]=true;
    votes_aggree[_id].voters.push(msg.sender);
    votes_aggree[_id].voteNum++;

    emit addAggree(_id,msg.sender,now);
    if(getVoteStatus(_id)==1){
      demandFactory.update(_id);
      emit voteThrough(_id,now);
    }
  }
  
  // 投反对票
  function against(uint _id) public{
    require(getVoteStatus(_id)==0 || getVoteStatus(_id)==2,"vote closed");
    require(is_voted[msg.sender][_id]==false,"You've already voted!");
    require(balanceOf(msg.sender)>=1,"You don't have enough tokens!");

    _burn(msg.sender, 1);
    //_mint(receiver, 1);
    is_voted[msg.sender][_id]=true;
    votes_against[_id].voters.push(msg.sender);
    votes_against[_id].voteNum++;

    emit addAgainst(_id,msg.sender,now);
    if(getVoteStatus(_id)==4){
      demandFactory.failed(_id);
      emit voteNotThrough(_id,now);
    }
  }

  // 获取对应需求的投票总数
  function getVotesCount(uint _id) public view returns(uint aggreeNum ,uint againstNum){
    aggreeNum=votes_aggree[_id].voteNum;
    againstNum=votes_against[_id].voteNum;
  }

  // 获取总共有哪些人投了对应的需求
  function getAllVoters(uint _id) public view returns(address[] memory aggree_voters,address[] memory against_voters){
    aggree_voters=votes_aggree[_id].voters;
    against_voters=votes_against[_id].voters;
  }
}