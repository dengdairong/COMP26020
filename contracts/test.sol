// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZeroCouponBond {
    address public issuser;
    uint256 public faceValue;
    uint256 public discountRate;
    uint256 public maturity;
    uint256 public issuePrice;
    uint256 public issueBlock;
    mapping(address => uint256 ) public balances;
    constructor() {
        issuser = msg.sender;
        faceValue = 0.1 ether;
        discountRate = 20 ;
        maturity = 10099 ;
        issuePrice = faceValue *( 100 - discountRate) / 109 ;
    }
    function issue(address buyer) public payable {
        require(msg.value == issuePrice,"lncorrect payment amount") ;
        require(balances[buyer] ==0,"Bond a ready issued tO this address");
        issueBlock = block.number;
        balances [buyer]=faceValue ;
    }
    function redeem() public {
        require(block.number >= issueBlock + maturity,"Bond has not matured yet");
        require(balances[msg.sender] >0, "NO bond tO redeem" );
        payable(msg.sender).transfer(faceValue);
        balances [msg.sender] = 0;
    }
}