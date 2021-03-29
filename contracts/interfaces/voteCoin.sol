// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.7.0;


abstract contract voteCoin{
  function transfer(address _to, uint _value) virtual public;
  function transferFrom(address _from, address _to, uint _value) virtual public;
  function balanceOf(address who) virtual  public  returns (uint);
  function allowance(address owner, address spender) virtual public returns (uint);
}