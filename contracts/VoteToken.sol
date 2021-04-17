// contracts/VoteToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "./interfaces/CharityFactory.sol";
import "./interfaces/Charity.sol";
import "./lib/Ownable.sol";

contract VoteToken is ERC20 , Ownable{

  struct voteInfo{
    uint voteNum; //投票数
    address[] voters; //投票人
  }
  mapping(uint => voteInfo) public votes_agree; //同意票
  mapping(uint => voteInfo) public votes_against; //反对票
  mapping(address => mapping(uint => bool)) public is_voted; //是否投过票
  uint8 public passVoteNum = 2; //超过此票数应通过
  uint8 public failVoteNum = 2; //超过此票数应失败
  address receiver = address(0); //接受vote币的地址
  CharityFactory charityFactory; 
  address public admin; 

  event addAgree(uint _id,address sender,uint voteTime); //投同意票事件
  event addAgainst(uint _id,address sender,uint voteTime); //投反对票事件
  event voteThrough(uint _id,uint voteTime); //投票通过事件
  event voteNotThrough(uint _id,uint voteTime); //投票不通过事件

  constructor(uint256 initialSupply,address charityFactoryAddress) public ERC20("VoteToken", "Vote") {
    _mint(msg.sender, initialSupply * 1 ether);
    //_setupDecimals(1);
    receiver=msg.sender;
    charityFactory = CharityFactory(charityFactoryAddress);
    admin = msg.sender;
  }

  function getCharity(uint _id) public view returns(Charity charity) {
    address charityAddress = charityFactory.charities(_id);
    charity = Charity(charityAddress);
  }

  // 从合约获取投票状态 0:初始 1：通过 2：捐赠中 3：捐赠完成 9：失败
  function getVoteStatus(uint _id) public view returns(uint status) {
    Charity charity = getCharity(_id);
    status = charity.getStatus();
  }

  // 获取投票更新后的状态
  function getVoteNextStatus(uint _id) public view returns(uint status) {
    status = getVoteStatus(_id);
    if(status!=0){
      return status;
    }else{
      //还能投票
      if(
        votes_agree[_id].voteNum<passVoteNum &&
        votes_against[_id].voteNum<failVoteNum
      ){ 
        //没通过也没失败
        return 0;
      }else if(votes_agree[_id].voteNum>=passVoteNum){
        // 成功
        return 1;
      }
      // 失败
      return 9;
    }
  }

  // 投同意票
  function agree(uint _id) public{
    require(getVoteStatus(_id)==0,"vote closed");
    require(is_voted[msg.sender][_id]==false,"You've already voted!");
    require(balanceOf(msg.sender)>=1 ether,"You don't have enough tokens!");
    
    transfer(receiver, 1 ether);
    is_voted[msg.sender][_id]=true;
    votes_agree[_id].voters.push(msg.sender);
    votes_agree[_id].voteNum++;
    
    emit addAgree(_id,msg.sender,now);
    if(getVoteNextStatus(_id)==1){
      getCharity(_id).update();
      emit voteThrough(_id,now);
    }
  }
  
  // 投反对票
  function against(uint _id) public{
    require(getVoteStatus(_id)==0,"vote closed");
    require(is_voted[msg.sender][_id]==false,"You've already voted!");
    require(balanceOf(msg.sender)>=1 ether,"You don't have enough tokens!");

    transfer(receiver, 1 ether);
    is_voted[msg.sender][_id]=true;
    votes_against[_id].voters.push(msg.sender);
    votes_against[_id].voteNum++;

    emit addAgainst(_id,msg.sender,now);
    if(getVoteNextStatus(_id)==9){
      getCharity(_id).failed();
      emit voteNotThrough(_id,now);
    }
  }

  function updatePassVoteNum(uint _num) public onlyOwner {
    passVoteNum = uint8(_num);
  }

  function updateFailVoteNum(uint _num) public onlyOwner {
    failVoteNum = uint8(_num);
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