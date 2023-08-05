// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";
import {MockFungibleToken} from "./mocks/MockFungibleToken.sol";
import {Permit3} from "src/Permit3.sol";

contract Permit3Test is Test {
    MockERC20 private mockERC20;
    MockFungibleToken private mockFT;
    Permit3 private permit3;

    bytes32 private constant TRANSFER_DETAILS_TYPEHASH =
        keccak256("TransferDetails(address token,uint8 tokenType,bytes4 functionSelector,bytes transferDetails)");

    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        // solhint-disable-next-line max-line-length
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint8 tokenType,bytes4 functionSelector,bytes transferDetails)"
    );

    bytes32 private constant TRANSFER_BATCH_TYPEHASH = keccak256(
        // solhint-disable-next-line max-line-length
        "Transfer(TransferDetails[] transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint8 tokenType,bytes4 functionSelector,bytes transferDetails)"
    );

    function setUp() external {
        mockERC20 = new MockERC20("Mock ERC20", "MOCK", 18);
        mockFT = new MockFungibleToken();
        permit3 = new Permit3();
    }

    function testTransferBySignature() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        mockERC20.mint(owner, 1e18);
        vm.prank(owner);
        mockERC20.approve(address(permit3), 1e18);

        Permit3.TransferDetails memory transferDetails =
            Permit3.TransferDetails(abi.encode(1e18), address(mockERC20), Permit3.TokenType.ERC20, 0x23b872dd);

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

        permit3.transferBySignature(
            owner,
            Permit3.SignatureTransfer(transferDetails, 0, block.timestamp),
            Permit3.RequestedTransferDetails(abi.encode(1e18), address(this)),
            signature
        );
    }

    function testILRTAValidate() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        mockFT.mint(owner, 1e18);
        vm.prank(owner);
        mockFT.approve(address(permit3), ILRTAFungibleToken.ILRTATransferDetails(1e18));

        Permit3.TransferDetails memory transferDetails = Permit3.TransferDetails(
            abi.encode(ILRTAFungibleToken.ILRTATransferDetails(1e18)),
            address(mockFT),
            Permit3.TokenType.ILRTA,
            0x811c34d3
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

        permit3.transferBySignature(
            owner,
            Permit3.SignatureTransfer(transferDetails, 0, block.timestamp),
            Permit3.RequestedTransferDetails(abi.encode(ILRTAFungibleToken.ILRTATransferDetails(0.5e18)), address(this)),
            signature
        );
    }

    function testGasTransferBySignature() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        mockERC20.mint(owner, 1e18);
        vm.prank(owner);
        mockERC20.approve(address(permit3), type(uint256).max);

        Permit3.TransferDetails memory transferDetails =
            Permit3.TransferDetails(abi.encode(1e18), address(mockERC20), Permit3.TokenType.ERC20, 0x23b872dd);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
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
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);
        vm.resumeGasMetering();

        permit3.transferBySignature(
            owner,
            Permit3.SignatureTransfer(transferDetails, 0, block.timestamp),
            Permit3.RequestedTransferDetails(abi.encode(1e18), address(this)),
            signature
        );
    }
}
