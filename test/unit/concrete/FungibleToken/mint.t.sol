// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {MockFungibleToken} from "../../../mocks/MockFungibleToken.sol";

contract MintTest is Test {
    MockFungibleToken private mockft;

    function setUp() external {
        mockft = new MockFungibleToken();
    }

    function test_Mint_Cold() external {
        mockft.mint(address(this), 1e18);
        vm.pauseGasMetering();

        assertEq(mockft.balanceOf(address(this)), 1e18);
        assertEq(mockft.totalSupply(), 1e18);
        vm.resumeGasMetering();
    }

    function test_Mint_Hot() external {
        vm.pauseGasMetering();
        mockft.mint(address(this), 1e18);
        vm.resumeGasMetering();
        mockft.mint(address(this), 1e18);
        vm.pauseGasMetering();

        assertEq(mockft.balanceOf(address(this)), 2e18);
        assertEq(mockft.totalSupply(), 2e18);
        vm.resumeGasMetering();
    }

    function test_Mint_Overflow() external {
        mockft.mint(address(this), type(uint256).max);
        vm.expectRevert();
        mockft.mint(address(this), 1);
    }
}
