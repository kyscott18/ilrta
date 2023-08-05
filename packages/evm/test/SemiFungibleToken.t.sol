// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockSemiFungibleToken} from "./mocks/MockSemiFungibleToken.sol";
import {ILRTASemiFungibleToken} from "src/examples/SemiFungibleToken.sol";
import {Permit3} from "src/Permit3.sol";

contract SemiFungibleTokenTest is Test {
    MockSemiFungibleToken private sft;

    function setUp() external {
        sft = new MockSemiFungibleToken();
    }

    function testMetadata() external {
        assertEq(sft.name(), "Test SFT");
        assertEq(sft.symbol(), "TEST");
    }

    function testMint() external {
        sft.mint(address(0xC0FFEE), bytes32(uint256(69)), 1e18);

        assertEq(sft.balanceOf(address(0xC0FFEE), 69), 1e18);
    }

    function testBurn() external {
        sft.mint(address(0xC0FFEE), bytes32(uint256(69)), 1e18);
        sft.burn(address(0xC0FFEE), bytes32(uint256(69)), 0.9e18);

        assertEq(sft.balanceOf(address(0xC0FFEE), 69), 0.1e18);
    }

    function testTransfer() external {
        sft.mint(address(this), bytes32(uint256(69)), 1e18);

        assertTrue(
            sft.transfer_XXXXXX(
                address(0xC0FFEE), ILRTASemiFungibleToken.ILRTATransferDetails({amount: 1e18, id: bytes32(uint256(69))})
            )
        );

        assertEq(sft.balanceOf(address(this), 69), 0);
        assertEq(sft.balanceOf(address(0xC0FFEE), 69), 1e18);
    }

    function testGasTransfer() external {
        vm.pauseGasMetering();
        sft.mint(address(this), bytes32(uint256(69)), 1e18);
        vm.resumeGasMetering();

        sft.transfer_XXXXXX(
            address(0xC0FFEE), ILRTASemiFungibleToken.ILRTATransferDetails({amount: 1e18, id: bytes32(uint256(69))})
        );
    }
}
