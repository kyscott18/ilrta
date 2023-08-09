// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";
import {MockFungibleToken} from "../../mocks/MockFungibleToken.sol";
import {Permit3} from "src/Permit3.sol";

contract TransferBySignatureILRTATest is Test {
    MockFungibleToken private mockFT;
    Permit3 private permit3;

    bytes32 private constant TRANSFER_DETAILS_TYPEHASH =
        keccak256("TransferDetails(address token,uint8 tokenType,bytes4 functionSelector,bytes transferDetails)");

    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        // solhint-disable-next-line max-line-length
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint8 tokenType,bytes4 functionSelector,bytes transferDetails)"
    );

    function setUp() external {
        mockFT = new MockFungibleToken();
        permit3 = new Permit3();
    }

    function test_TransferBySignature() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        mockFT.mint(owner, 1e18);
        vm.prank(owner);
        mockFT.approve_cMebqQ(address(permit3), ILRTAFungibleToken.ILRTAApprovalDetails(1e18));

        Permit3.TransferDetails memory transferDetails = Permit3.TransferDetails(
            address(mockFT),
            Permit3.TokenType.ILRTA,
            0x811c34d3,
            abi.encode(ILRTAFungibleToken.ILRTATransferDetails(1e18))
        );

        bytes32 signatureHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                permit3.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        TRANSFER_TYPEHASH,
                        keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, transferDetails)),
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
            owner,
            Permit3.SignatureTransfer(transferDetails, 0, block.timestamp),
            Permit3.RequestedTransferDetails(address(this), abi.encode(ILRTAFungibleToken.ILRTATransferDetails(1e18))),
            signature
        );
        vm.pauseGasMetering();

        assertEq(mockFT.balanceOf(address(this)), 1e18);
        vm.resumeGasMetering();
    }
}
