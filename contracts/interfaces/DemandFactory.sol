// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract DemandFactory{
  struct Demand {
    uint id;          //需求编号
    string username;  //发起人 or 机构 名称
    address sender;   //发起人address
    string content;   //需求内容
    string contact;   //联系方式
    uint status;      //状态号 0:初始 1：通过 2：捐赠中 3：捐赠完成 4：失败
  }
  Demand[] public demands;
  function update(uint index) virtual public;
  function failed(uint index) virtual public;
}