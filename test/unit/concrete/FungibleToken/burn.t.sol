// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {MockFungibleToken} from "../../../mocks/MockFungibleToken.sol";

contract BurnTest is Test {
    MockFungibleToken private mockft;

    function setUp() external {
        mockft = new MockFungibleToken();

        mockft.mint(address(this), 2e18);
    }

    function test_Burn_Full() external {
        mockft.burn(address(this), 2e18);
        vm.pauseGasMetering();

        assertEq(mockft.balanceOf(address(this)), 0);
        assertEq(mockft.totalSupply(), 0);
        vm.resumeGasMetering();
    }

    function test_Burn_Partial() external {
        mockft.burn(address(this), 1e18);
        vm.pauseGasMetering();

        assertEq(mockft.balanceOf(address(this)), 1e18);
        assertEq(mockft.totalSupply(), 1e18);
        vm.resumeGasMetering();
    }

    function test_Burn_Overflow() external {
        vm.expectRevert();
        mockft.burn(address(this), 2e18 + 1);
    }
}
