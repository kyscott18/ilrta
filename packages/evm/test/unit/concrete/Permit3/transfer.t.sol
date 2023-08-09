// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Permit3} from "src/Permit3.sol";
import {IERC1271} from "src/IERC1271.sol";

contract TransferTest is Test, IERC1271 {
    Permit3 private permit3;

    enum Ret {
        False,
        True,
        Fail
    }

    Ret private ret;

    function setUp() external {
        permit3 = new Permit3();
    }

    function test_Transfer_Fail() external {
        ret = Ret.Fail;

        vm.expectRevert(Permit3.TransferFailed.selector);
        permit3.transferBySignature(
            address(this),
            Permit3.SignatureTransfer(
                Permit3.TransferDetails(address(this), Permit3.TokenType.ILRTA, 0x811c34d3, bytes("")),
                0,
                block.timestamp
            ),
            Permit3.RequestedTransferDetails(address(0), bytes("")),
            bytes("")
        );
    }

    function test_Transfer_ReturnTrue() external {
        ret = Ret.True;

        permit3.transferBySignature(
            address(this),
            Permit3.SignatureTransfer(
                Permit3.TransferDetails(address(this), Permit3.TokenType.ILRTA, 0x811c34d3, bytes("")),
                0,
                block.timestamp
            ),
            Permit3.RequestedTransferDetails(address(0), bytes("")),
            bytes("")
        );
    }

    function test_Transfer_ReturnFalse() external {
        ret = Ret.False;

        vm.expectRevert(Permit3.TransferFailed.selector);
        permit3.transferBySignature(
            address(this),
            Permit3.SignatureTransfer(
                Permit3.TransferDetails(address(this), Permit3.TokenType.ILRTA, 0x811c34d3, bytes("")),
                0,
                block.timestamp
            ),
            Permit3.RequestedTransferDetails(address(0), bytes("")),
            bytes("")
        );
    }

    function isValidSignature(bytes32, bytes memory) external pure returns (bytes4) {
        return IERC1271.isValidSignature.selector;
    }

    function validateRequest() external pure returns (bool) {
        return true;
    }

    function transferFrom() external view returns (bool) {
        if (ret == Ret.False) return false;
        if (ret == Ret.True) return true;
        assert(false);
    }
}
