// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/deployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);]
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARING_BALANCE);
    }

    function testMiniumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public view {
        console.log(msg.sender);
        console.log(address(fundMe.i_owner()));
        assertEq(fundMe.i_owner(), msg.sender);
    }

    //what can we do to work with addresses outside our system?
    //1.unit  -testing a specific part of our code
    //2.integration - testing how our code works with other parts of our code
    //3.forked  -testing our code on a simulted real renvironment
    //4.staging -testing our code in a real environment that is not good

    function testPriceFeedVersionIsAccurate() public view {
        uint256 priceFeedVersion = fundMe.getVersion();
        assertEq(priceFeedVersion, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // the next line shoudl fail
        fundMe.fund(); //send 0 eth
    }

    function testFundUpdateFundedDataStructure() public {
        vm.prank(USER); // the next tx will be from user
        fundMe.fund{value: SEND_VALUE}();

        uint256 amoutFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amoutFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        // vm.prank(USER); // the next tx will be from user
        // fundMe.fund{value: SEND_VALUE}();
        address funders = fundMe.getFunder(0);
        assertEq(funders, USER);
    }

    modifier funded() {
        vm.prank(USER); // the next tx will be from user
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // the next line should fail
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeBalance);
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawFromMutipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE); //prank someuser with ethers
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assert(address(fundMe).balance == 0);
        assert(fundMe.getOwner().balance == startingOwnerBalance + startingFundMeBalance);
    }
}
