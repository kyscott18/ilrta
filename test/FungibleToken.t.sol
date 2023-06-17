// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockFungibleToken} from "./mocks/MockFungibleToken.sol";
import {ILRTA} from "src/ILRTA.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";
import {SuperSignature} from "src/SuperSignature.sol";

contract FungibleTokenTest is Test {
    MockFungibleToken private ft;
    SuperSignature private superSignature;

    bytes32 private constant VERIFY_TYPEHASH = keccak256("Verify(bytes32[] dataHash,uint256 nonce,uint256 deadline)");

    bytes32 private constant SUPER_SIGNATURE_TRANSFER_TYPEHASH =
        keccak256(bytes("Transfer(TransferDetails transferDetails,address spender)TransferDetails(uint256 amount)"));

    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        bytes(
            /* solhint-disable-next-line max-line-length */
            "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(uint256 amount)"
        )
    );

    bytes32 private constant TRANSFER_DETAILS_TYPEHASH = keccak256(bytes("TransferDetails(uint256 amount)"));

    function setUp() external {
        superSignature = new SuperSignature();
        ft = new MockFungibleToken(address(superSignature));
    }

    function testMetadata() external {
        assertEq(ft.name(), "Test FT");
        assertEq(ft.symbol(), "TEST");
        assertEq(ft.decimals(), 18);
    }

    function testMint() external {
        ft.mint(address(0xC0FFEE), 1e18);

        assertEq(ft.totalSupply(), 1e18);
        assertEq(ft.balanceOf(address(0xC0FFEE)), 1e18);
    }

    function testBurn() external {
        ft.mint(address(0xC0FFEE), 1e18);
        ft.burn(address(0xC0FFEE), 0.9e18);

        assertEq(ft.totalSupply(), 1e18 - 0.9e18);
        assertEq(ft.balanceOf(address(0xC0FFEE)), 0.1e18);
    }

    function testTransfer() external {
        ft.mint(address(this), 1e18);

        assertTrue(ft.transfer(address(0xC0FFEE), abi.encode(ILRTAFungibleToken.ILRTATransferDetails({amount: 1e18}))));
        assertEq(ft.totalSupply(), 1e18);

        assertEq(ft.balanceOf(address(this)), 0);
        assertEq(ft.balanceOf(address(0xC0FFEE)), 1e18);
    }

    function testTransferBySignature() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        ft.mint(address(owner), 1e18);

        ILRTAFungibleToken.ILRTATransferDetails memory transferDetails =
            ILRTAFungibleToken.ILRTATransferDetails({amount: 1e18});

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    ft.DOMAIN_SEPARATOR(),
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
            ft.transferBySignature(
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
        assertEq(ft.totalSupply(), 1e18);

        assertEq(ft.balanceOf(address(this)), 1e18);
        assertEq(ft.balanceOf(address(owner)), 0);
    }

    function testTransferBySuperSignature() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        ft.mint(owner, 1e18);

        ILRTAFungibleToken.ILRTATransferDetails memory transferDetails =
            ILRTAFungibleToken.ILRTATransferDetails({amount: 1e18});

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = keccak256(
            abi.encode(
                SUPER_SIGNATURE_TRANSFER_TYPEHASH,
                keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, abi.encode(transferDetails))),
                address(this)
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
            ft.transferBySuperSignature(
                owner,
                abi.encode(transferDetails),
                ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)}),
                dataHash
            )
        );
    }

    function testGasTransfer() external {
        vm.pauseGasMetering();
        ft.mint(address(this), 1e18);
        vm.resumeGasMetering();

        ft.transfer(address(0xC0FFEE), abi.encode(ILRTAFungibleToken.ILRTATransferDetails({amount: 1e18})));
    }

    function testGasTransferBySignature() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        ft.mint(address(owner), 1e18);

        ILRTAFungibleToken.ILRTATransferDetails memory transferDetails =
            ILRTAFungibleToken.ILRTATransferDetails({amount: 1e18});

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    ft.DOMAIN_SEPARATOR(),
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
        ILRTA.SignatureTransfer memory transfer =
        /* solhint-disable-next-line max-line-length */
         ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp, transferDetails: abi.encode(transferDetails)});
        ILRTA.RequestedTransfer memory request =
            ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)});

        vm.resumeGasMetering();

        ft.transferBySignature(owner, transfer, request, signature);
    }

    function testGasTransferBySuperSignature() external {
        vm.pauseGasMetering();

        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        ft.mint(owner, 1e18);

        ILRTAFungibleToken.ILRTATransferDetails memory transferDetails =
            ILRTAFungibleToken.ILRTATransferDetails({amount: 1e18});

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = keccak256(
            abi.encode(
                SUPER_SIGNATURE_TRANSFER_TYPEHASH,
                keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, abi.encode(transferDetails))),
                address(this)
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
        ft.transferBySuperSignature(
            owner,
            abi.encode(transferDetails),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)}),
            dataHash
        );
    }
}
