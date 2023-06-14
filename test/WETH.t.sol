// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {WETH} from "src/examples/WETH.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

/// @notice tests from solmate
contract WETHTest is Test {
    WETH weth;

    function setUp() external {
        weth = new WETH();
    }

    function testFallbackDeposit() external {
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        SafeTransferLib.safeTransferETH(address(weth), 1 ether);

        assertEq(weth.balanceOf(address(this)), 1 ether);
        assertEq(weth.totalSupply(), 1 ether);
    }

    function testDeposit() external {
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        weth.deposit{value: 1 ether}();

        assertEq(weth.balanceOf(address(this)), 1 ether);
        assertEq(weth.totalSupply(), 1 ether);
    }

    function testWithdraw() external {
        uint256 startingBalance = address(this).balance;

        weth.deposit{value: 1 ether}();

        weth.withdraw(1 ether);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, startingBalance);
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);
    }

    function testPartialWithdraw() external {
        weth.deposit{value: 1 ether}();

        uint256 balanceBeforeWithdraw = address(this).balance;

        weth.withdraw(0.5 ether);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, balanceBeforeWithdraw + 0.5 ether);
        assertEq(weth.balanceOf(address(this)), 0.5 ether);
        assertEq(weth.totalSupply(), 0.5 ether);
    }

    function testFallbackDeposit(uint256 amount) external {
        amount = bound(amount, 0, address(this).balance);

        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        SafeTransferLib.safeTransferETH(address(weth), amount);

        assertEq(weth.balanceOf(address(this)), amount);
        assertEq(weth.totalSupply(), amount);
    }

    function testDeposit(uint256 amount) external {
        amount = bound(amount, 0, address(this).balance);

        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        weth.deposit{value: amount}();

        assertEq(weth.balanceOf(address(this)), amount);
        assertEq(weth.totalSupply(), amount);
    }

    function testWithdraw(uint256 depositAmount, uint256 withdrawAmount) external {
        depositAmount = bound(depositAmount, 0, address(this).balance);
        withdrawAmount = bound(withdrawAmount, 0, depositAmount);

        weth.deposit{value: depositAmount}();

        uint256 balanceBeforeWithdraw = address(this).balance;

        weth.withdraw(withdrawAmount);

        uint256 balanceAfterWithdraw = address(this).balance;

        assertEq(balanceAfterWithdraw, balanceBeforeWithdraw + withdrawAmount);
        assertEq(weth.balanceOf(address(this)), depositAmount - withdrawAmount);
        assertEq(weth.totalSupply(), depositAmount - withdrawAmount);
    }

    receive() external payable {}
}
