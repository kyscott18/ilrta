// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {SuperSignature} from "src/examples/TransferBatch.sol";
import {MockFungibleToken} from "./mocks/MockFungibleToken.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";
import {Permit3} from "src/Permit3.sol";
import {TransferBatch} from "src/examples/TransferBatch.sol";

contract TransferBatchTest is Test {
    SuperSignature private superSignature;
    MockFungibleToken private ft1;
    MockFungibleToken private ft2;
    TransferBatch private transferBatch;

    bytes32 private constant VERIFY_TYPEHASH = keccak256("Verify(bytes32[] dataHash,uint256 nonce,uint256 deadline)");

    bytes32 private constant SUPER_SIGNATURE_TRANSFER_TYPEHASH =
        keccak256(bytes("Transfer(TransferDetails transferDetails,address spender)TransferDetails(uint256 amount)"));

    bytes32 private constant TRANSFER_DETAILS_TYPEHASH = keccak256(bytes("TransferDetails(uint256 amount)"));

    function setUp() external {
        superSignature = new Permit3();
        ft1 = new MockFungibleToken(address(superSignature));
        ft2 = new MockFungibleToken(address(superSignature));
        transferBatch = new TransferBatch(address(superSignature));
    }

    function testTransferBatch() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        ft1.mint(owner, 1e18);
        ft2.mint(owner, 1e18);

        address[] memory tokens = new address[](2);
        tokens[0] = address(ft1);
        tokens[1] = address(ft2);

        ILRTAFungibleToken.ILRTATransferDetails[] memory transferDetails =
            new ILRTAFungibleToken.ILRTATransferDetails[](2);
        transferDetails[0] = ILRTAFungibleToken.ILRTATransferDetails(1e18);
        transferDetails[1] = ILRTAFungibleToken.ILRTATransferDetails(1e18);

        ILRTAFungibleToken.RequestedTransfer[] memory requestedTransfers = new ILRTAFungibleToken.RequestedTransfer[](2);
        requestedTransfers[0] =
            ILRTAFungibleToken.RequestedTransfer(address(this), ILRTAFungibleToken.ILRTATransferDetails(0.5e18));
        requestedTransfers[1] =
            ILRTAFungibleToken.RequestedTransfer(address(this), ILRTAFungibleToken.ILRTATransferDetails(0.5e18));

        bytes32[] memory datahash = new bytes32[](2);
        datahash[0] = keccak256(
            abi.encodePacked(
                "\x19\x01",
                ft1.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        SUPER_SIGNATURE_TRANSFER_TYPEHASH,
                        keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, transferDetails[0])),
                        address(transferBatch)
                    )
                )
            )
        );
        datahash[1] = keccak256(
            abi.encodePacked(
                "\x19\x01",
                ft2.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        SUPER_SIGNATURE_TRANSFER_TYPEHASH,
                        keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, transferDetails[1])),
                        address(transferBatch)
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
                    keccak256(abi.encode(VERIFY_TYPEHASH, keccak256(abi.encodePacked(datahash)), 0, block.timestamp))
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.resumeGasMetering();

        transferBatch.transferBatch(owner, tokens, transferDetails, requestedTransfers, 0, block.timestamp, signature);
    }
}
