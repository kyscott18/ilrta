// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockSemiFungibleToken} from "./mocks/MockSemiFungibleToken.sol";
import {ILRTA} from "src/ILRTA.sol";
import {ILRTASemiFungibleToken} from "src/examples/SemiFungibleToken.sol";
import {Permit3} from "src/Permit3.sol";
import {SuperSignature} from "src/SuperSignature.sol";

contract SemiFungibleTokenTest is Test {
    MockSemiFungibleToken private sft;
    SuperSignature private superSignature;

    bytes32 private constant VERIFY_TYPEHASH = keccak256("Verify(bytes32[] dataHash,uint256 nonce,uint256 deadline)");

    bytes32 private constant SUPER_SIGNATURE_TRANSFER_TYPEHASH = keccak256(
        bytes("Transfer(TransferDetails transferDetails,address spender)TransferDetails(uint256 id,uint256 amount)")
    );

    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        bytes(
            /* solhint-disable-next-line max-line-length */
            "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(uint256 id,uint256 amount)"
        )
    );

    bytes32 private constant TRANSFER_DETAILS_TYPEHASH = keccak256(bytes("TransferDetails(uint256 id,uint256 amount)"));

    function setUp() external {
        superSignature = new Permit3();
        sft = new MockSemiFungibleToken(address(superSignature));
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
            sft.transfer(
                address(0xC0FFEE),
                abi.encode(ILRTASemiFungibleToken.ILRTATransferDetails({amount: 1e18, id: bytes32(uint256(69))}))
            )
        );

        assertEq(sft.balanceOf(address(this), 69), 0);
        assertEq(sft.balanceOf(address(0xC0FFEE), 69), 1e18);
    }

    function testTransferBySignature() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        sft.mint(address(owner), bytes32(uint256(69)), 1e18);

        ILRTASemiFungibleToken.ILRTATransferDetails memory transferDetails =
            ILRTASemiFungibleToken.ILRTATransferDetails({amount: 1e18, id: bytes32(uint256(69))});

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    sft.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TRANSFER_TYPEHASH,
                            keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, abi.encode(transferDetails))),
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
            sft.transferBySignature(
                owner,
                ILRTA.SignatureTransfer({
                    nonce: 0,
                    deadline: block.timestamp,
                    transferDetails: abi.encode(transferDetails)
                }),
                ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)}),
                signature
            )
        );

        assertEq(sft.balanceOf(address(this), 69), 1e18);
        assertEq(sft.balanceOf(address(owner), 69), 0);
    }

    function testTransferBySuperSignature() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        sft.mint(address(owner), bytes32(uint256(69)), 1e18);

        ILRTASemiFungibleToken.ILRTATransferDetails memory transferDetails =
            ILRTASemiFungibleToken.ILRTATransferDetails({amount: 1e18, id: bytes32(uint256(69))});

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = keccak256(
            abi.encodePacked(
                "\x19\x01",
                sft.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        SUPER_SIGNATURE_TRANSFER_TYPEHASH,
                        keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, abi.encode(transferDetails))),
                        address(this)
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    superSignature.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(VERIFY_TYPEHASH, keccak256(abi.encodePacked(dataHash)), 0, block.timestamp))
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        superSignature.verifyAndStoreRoot(owner, SuperSignature.Verify(dataHash, 0, block.timestamp), signature);

        assertTrue(
            sft.transferBySuperSignature(
                owner,
                abi.encode(transferDetails),
                ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)}),
                dataHash
            )
        );
    }

    function testGasTransfer() external {
        vm.pauseGasMetering();
        sft.mint(address(this), bytes32(uint256(69)), 1e18);
        vm.resumeGasMetering();

        sft.transfer(
            address(0xC0FFEE),
            abi.encode(ILRTASemiFungibleToken.ILRTATransferDetails({amount: 1e18, id: bytes32(uint256(69))}))
        );
    }

    function testGasTransferBySignature() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        sft.mint(address(owner), bytes32(uint256(69)), 1e18);

        ILRTASemiFungibleToken.ILRTATransferDetails memory transferDetails =
            ILRTASemiFungibleToken.ILRTATransferDetails({amount: 1e18, id: bytes32(uint256(69))});

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    sft.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TRANSFER_TYPEHASH,
                            keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, abi.encode(transferDetails))),
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

        sft.transferBySignature(
            owner,
            // solhint-disable-next-line max-line-length
            ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp, transferDetails: abi.encode(transferDetails)}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)}),
            signature
        );
    }

    function testGasTransferBySuperSignature() external {
        vm.pauseGasMetering();

        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        sft.mint(address(owner), bytes32(uint256(69)), 1e18);

        ILRTASemiFungibleToken.ILRTATransferDetails memory transferDetails =
            ILRTASemiFungibleToken.ILRTATransferDetails({amount: 1e18, id: bytes32(uint256(69))});

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = keccak256(
            abi.encodePacked(
                "\x19\x01",
                sft.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        SUPER_SIGNATURE_TRANSFER_TYPEHASH,
                        keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, abi.encode(transferDetails))),
                        address(this)
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    superSignature.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(VERIFY_TYPEHASH, keccak256(abi.encodePacked(dataHash)), 0, block.timestamp))
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        superSignature.verifyAndStoreRoot(owner, SuperSignature.Verify(dataHash, 0, block.timestamp), signature);

        vm.resumeGasMetering();

        sft.transferBySuperSignature(
            owner,
            abi.encode(transferDetails),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)}),
            dataHash
        );
    }
}
