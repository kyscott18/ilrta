// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockFungibleToken} from "./mocks/MockFungibleToken.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";

contract FungibleTokenTest is Test {
    MockFungibleToken private ft;

    function setUp() external {
        ft = new MockFungibleToken();
    }

    function testMetadata() external {
        assertEq(ft.name(), "Test FT");
        assertEq(ft.symbol(), "TEST");
        assertEq(ft.decimals(), 18);
    }

    function testMint() external {
        ft.mint(address(0xC0FFEE), 1e18);

        assertEq(ft.totalSupply(), 1e18);
        assertEq(ft.balanceOf(address(0xC0FFEE)), 1e18);
    }

    function testBurn() external {
        ft.mint(address(0xC0FFEE), 1e18);
        ft.burn(address(0xC0FFEE), 0.9e18);

        assertEq(ft.totalSupply(), 1e18 - 0.9e18);
        assertEq(ft.balanceOf(address(0xC0FFEE)), 0.1e18);
    }

    function testTransfer() external {
        ft.mint(address(this), 1e18);

        assertTrue(ft.transfer(address(0xC0FFEE), abi.encode(ILRTAFungibleToken.ILRTATransferDetails({amount: 1e18}))));
        assertEq(ft.totalSupply(), 1e18);

        assertEq(ft.balanceOf(address(this)), 0);
        assertEq(ft.balanceOf(address(0xC0FFEE)), 1e18);
    }

    function testGasTransfer() external {
        vm.pauseGasMetering();
        ft.mint(address(this), 1e18);
        vm.resumeGasMetering();

        ft.transfer(address(0xC0FFEE), abi.encode(ILRTAFungibleToken.ILRTATransferDetails({amount: 1e18})));
    }
}
