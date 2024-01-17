// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";
import {MockFungibleToken} from "../../mocks/MockFungibleToken.sol";
import {Permit3} from "src/Permit3.sol";

contract TransferBySignatureILRTABatchTest is Test {
    MockFungibleToken private mockFT;
    Permit3 private permit3;

    bytes32 private constant TRANSFER_DETAILS_TYPEHASH =
        keccak256("TransferDetails(address token,uint8 tokenType,uint32 functionSelector,bytes transferDetails)");

    bytes32 private constant TRANSFER_BATCH_TYPEHASH = keccak256(
        "Transfer(TransferDetails[] transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint8 tokenType,uint32 functionSelector,bytes transferDetails)"
    );

    function setUp() external {
        mockFT = new MockFungibleToken();
        permit3 = new Permit3();
    }

    function test_TransferBySignature() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        mockFT.mint(owner, 2e18);
        vm.prank(owner);
        mockFT.approve_cMebqQ(address(permit3), ILRTAFungibleToken.ILRTAApprovalDetails(type(uint256).max));

        Permit3.TransferDetails[] memory transferDetails = new Permit3.TransferDetails[](2);
        transferDetails[0] = Permit3.TransferDetails(
            address(mockFT),
            Permit3.TokenType.ILRTA,
            0x811c34d3,
            abi.encode(ILRTAFungibleToken.ILRTATransferDetails(1e18))
        );
        transferDetails[1] = Permit3.TransferDetails(
            address(mockFT),
            Permit3.TokenType.ILRTA,
            0x811c34d3,
            abi.encode(ILRTAFungibleToken.ILRTATransferDetails(1e18))
        );

        Permit3.RequestedTransferDetails[] memory requestedTransfers = new Permit3.RequestedTransferDetails[](2);
        requestedTransfers[0] =
            Permit3.RequestedTransferDetails(address(this), abi.encode(ILRTAFungibleToken.ILRTATransferDetails(1e18)));
        requestedTransfers[1] =
            Permit3.RequestedTransferDetails(address(this), abi.encode(ILRTAFungibleToken.ILRTATransferDetails(1e18)));

        bytes32[] memory transferDetailsHashes = new bytes32[](transferDetails.length);
        for (uint256 i = 0; i < transferDetailsHashes.length; i++) {
            transferDetailsHashes[i] = keccak256(
                abi.encode(
                    TRANSFER_DETAILS_TYPEHASH,
                    transferDetails[i].token,
                    transferDetails[i].tokenType,
                    transferDetails[i].functionSelector,
                    keccak256(transferDetails[i].transferDetails)
                )
            );
        }

        bytes32 signatureHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                permit3.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        TRANSFER_BATCH_TYPEHASH,
                        keccak256(abi.encodePacked(transferDetailsHashes)),
                        address(this),
                        0,
                        block.timestamp
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, signatureHash);

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.resumeGasMetering();

        permit3.transferBySignature(
            owner, Permit3.SignatureTransferBatch(transferDetails, 0, block.timestamp), requestedTransfers, signature
        );
        vm.pauseGasMetering();

        assertEq(mockFT.balanceOf(address(this)), 2e18);
        vm.resumeGasMetering();
    }
}
