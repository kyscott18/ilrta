// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Permit3} from "src/Permit3.sol";
import {SignatureVerification} from "src/SignatureVerification.sol";

contract ValidateRequestTest is Test {
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

    function test_ValidateRequest_InvalidRequestERC20() external {
        vm.expectRevert(abi.encodeWithSelector(Permit3.InvalidRequest.selector, abi.encode(uint256(1))));
        permit3.transferBySignature1(
            address(0),
            Permit3.SignatureTransfer(
                Permit3.TransferDetails(address(0), Permit3.TokenType.ERC20, bytes4(0), abi.encode(uint256(0))),
                0,
                block.timestamp
            ),
            Permit3.RequestedTransferDetails(address(0), abi.encode(uint256(1))),
            bytes("")
        );
    }

    function test_ValidateRequest_ValidRequestERC20() external {
        vm.expectRevert(SignatureVerification.InvalidContractSignature.selector);
        permit3.transferBySignature1(
            address(this),
            Permit3.SignatureTransfer(
                Permit3.TransferDetails(address(0), Permit3.TokenType.ERC20, bytes4(0), abi.encode(uint256(1))),
                0,
                block.timestamp
            ),
            Permit3.RequestedTransferDetails(address(0), abi.encode(uint256(1))),
            bytes("")
        );
    }

    function test_ValidateRequest_DifferentTransferDetailsLength() external {
        vm.expectRevert(abi.encodeWithSelector(Permit3.InvalidRequest.selector, bytes("")));
        permit3.transferBySignature1(
            address(0),
            Permit3.SignatureTransfer(
                Permit3.TransferDetails(address(0), Permit3.TokenType.ILRTA, bytes4(0), abi.encode(uint256(0))),
                0,
                block.timestamp
            ),
            Permit3.RequestedTransferDetails(address(0), bytes("")),
            bytes("")
        );
    }

    function test_ValidateRequest_ReturnFalse() external {
        ret = Ret.False;

        vm.expectRevert(abi.encodeWithSelector(Permit3.InvalidRequest.selector, bytes("")));
        permit3.transferBySignature1(
            address(this),
            Permit3.SignatureTransfer(
                Permit3.TransferDetails(address(0), Permit3.TokenType.ILRTA, bytes4(0), bytes("")), 0, block.timestamp
            ),
            Permit3.RequestedTransferDetails(address(0), bytes("")),
            bytes("")
        );
    }

    function test_ValidateRequest_CallFail() external {
        ret = Ret.Fail;

        vm.expectRevert(abi.encodeWithSelector(Permit3.InvalidRequest.selector, bytes("")));
        permit3.transferBySignature1(
            address(this),
            Permit3.SignatureTransfer(
                Permit3.TransferDetails(address(this), Permit3.TokenType.ILRTA, bytes4(0), bytes("")),
                0,
                block.timestamp
            ),
            Permit3.RequestedTransferDetails(address(0), bytes("")),
            bytes("")
        );
    }

    function test_ValidateRequest_ReturnTrue() external {
        ret = Ret.True;

        vm.expectRevert(SignatureVerification.InvalidContractSignature.selector);
        permit3.transferBySignature1(
            address(this),
            Permit3.SignatureTransfer(
                Permit3.TransferDetails(address(this), Permit3.TokenType.ILRTA, bytes4(0), bytes("")),
                0,
                block.timestamp
            ),
            Permit3.RequestedTransferDetails(address(0), bytes("")),
            bytes("")
        );
    }

    function isValidSignature(bytes32, bytes memory) external pure returns (bytes4) {
        return bytes4(0);
    }

    function validateRequest() external view returns (bool) {
        if (ret == Ret.False) return false;
        if (ret == Ret.True) return true;
        assert(false);
    }
}
