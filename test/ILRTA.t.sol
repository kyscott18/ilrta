// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockILRTA} from "./mocks/MockILRTA.sol";
import {ILRTA} from "src/ILRTA.sol";
import {SignatureVerification} from "src/SignatureVerification.sol";
import {Bytes32AddressLib} from "solmate/src/utils/Bytes32AddressLib.sol";

contract ILRTATest is Test {
    MockILRTA private ilrta;

    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        bytes(
            "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails()"
        )
    );
    bytes32 private constant TRANSFER_DETAILS_TYPEHASH = keccak256(bytes("TransferDetails()"));

    function setUp() external {
        ilrta = new MockILRTA();
    }

    function testDataOf() external {
        assertEq(ilrta.dataOf(address(0xC0FFEE), bytes32(0)), bytes(""));
    }

    function testTransfer() external {
        assertTrue(ilrta.transfer(address(0xC0FFEE), ""));
    }

    function testTransferBySignature() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    ilrta.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TRANSFER_TYPEHASH,
                            keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, bytes(""))),
                            address(this),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        assertTrue(
            ilrta.transferBySignature(
                owner,
                ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp, transferDetails: bytes("")}),
                ILRTA.RequestedTransfer({to: address(this), transferDetails: bytes("")}),
                signature
            )
        );

        assertEq(ilrta.nonceBitmap(owner, 0), 1);
    }

    function testGasTransfer() external {
        ilrta.transfer(address(0xC0FFEE), "");
    }

    function testGasTransferBySignature() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    ilrta.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TRANSFER_TYPEHASH,
                            keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, bytes(""))),
                            address(this),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.resumeGasMetering();

        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp, transferDetails: bytes("")}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: bytes("")}),
            signature
        );
    }

    function testSignatureBadNonce1() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    ilrta.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TRANSFER_TYPEHASH,
                            keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, bytes(""))),
                            address(this),
                            1,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(SignatureVerification.InvalidSigner.selector);
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp, transferDetails: bytes("")}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: bytes("")}),
            signature
        );
    }

    function testSignatureBadNonce2() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    ilrta.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TRANSFER_TYPEHASH,
                            keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, bytes(""))),
                            address(this),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(SignatureVerification.InvalidSigner.selector);
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({nonce: 1, deadline: block.timestamp, transferDetails: bytes("")}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: bytes("")}),
            signature
        );
    }

    function testSignatureBadDeadline() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    ilrta.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TRANSFER_TYPEHASH,
                            keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, bytes(""))),
                            address(this),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(SignatureVerification.InvalidSigner.selector);
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp + 1, transferDetails: bytes("")}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: bytes("")}),
            signature
        );
    }

    function testSignaturePastDeadline() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    ilrta.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TRANSFER_TYPEHASH,
                            keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, bytes(""))),
                            address(this),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.warp(block.timestamp + 1);

        vm.expectRevert(abi.encodeWithSelector(ILRTA.SignatureExpired.selector, block.timestamp - 1));
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp - 1, transferDetails: bytes("")}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: bytes("")}),
            signature
        );
    }

    function testSignatureReplay() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    ilrta.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TRANSFER_TYPEHASH,
                            keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, bytes(""))),
                            address(this),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp, transferDetails: bytes("")}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: bytes("")}),
            signature
        );
        vm.expectRevert(ILRTA.InvalidNonce.selector);
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp, transferDetails: bytes("")}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: bytes("")}),
            signature
        );
    }

    function testSignatureInvalidation() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    ilrta.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TRANSFER_TYPEHASH,
                            keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, bytes(""))),
                            address(this),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(owner);
        ilrta.invalidateUnorderedNonces(0, 1);

        assertEq(ilrta.nonceBitmap(owner, 0), 1);

        vm.expectRevert(ILRTA.InvalidNonce.selector);
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp, transferDetails: bytes("")}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: bytes("")}),
            signature
        );
    }
}
