// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { MockILRTA } from "./mocks/MockILRTA.sol";
import { ILRTA } from "src/ILRTA.sol";

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
        assertEq(ilrta.dataOf(address(0xC0FFEE)), bytes(""));
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
                            address(0xCAFE),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(address(0xCAFE));
        assertTrue(
            ilrta.transferBySignature(
                owner,
                ILRTA.SignatureTransfer({ nonce: 0, deadline: block.timestamp, transferDetails: bytes("") }),
                ILRTA.RequestedTransfer({ to: address(0xCAFE), transferDetails: bytes("") }),
                signature
            )
        );

        assertEq(ilrta.nonces(owner), 1);
    }

    function testSignatureBadNonce() external {
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
                            address(0xCAFE),
                            1,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert();
        vm.prank(address(0xCAFE));
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({ nonce: 0, deadline: block.timestamp, transferDetails: bytes("") }),
            ILRTA.RequestedTransfer({ to: address(0xCAFE), transferDetails: bytes("") }),
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
                            address(0xCAFE),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert();
        vm.prank(address(0xCAFE));
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({ nonce: 0, deadline: block.timestamp + 1, transferDetails: bytes("") }),
            ILRTA.RequestedTransfer({ to: address(0xCAFE), transferDetails: bytes("") }),
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
                            address(0xCAFE),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.warp(block.timestamp + 1);

        vm.expectRevert();
        vm.prank(address(0xCAFE));
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({ nonce: 0, deadline: block.timestamp - 1, transferDetails: bytes("") }),
            ILRTA.RequestedTransfer({ to: address(0xCAFE), transferDetails: bytes("") }),
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
                            address(0xCAFE),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(address(0xCAFE));
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({ nonce: 0, deadline: block.timestamp, transferDetails: bytes("") }),
            ILRTA.RequestedTransfer({ to: address(0xCAFE), transferDetails: bytes("") }),
            signature
        );
        vm.expectRevert();
        vm.prank(address(0xCAFE));
        ilrta.transferBySignature(
            owner,
            ILRTA.SignatureTransfer({ nonce: 0, deadline: block.timestamp + 1, transferDetails: bytes("") }),
            ILRTA.RequestedTransfer({ to: address(0xCAFE), transferDetails: bytes("") }),
            signature
        );
    }
}
