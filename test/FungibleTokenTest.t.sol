// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockFungibleToken} from "./mocks/MockFungibleToken.sol";
import {ILRTA} from "src/ILRTA.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";

contract FungibleTokenTest is Test {
    MockFungibleToken private ft;
    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        bytes(
            /* solhint-disable-next-line max-line-length */
            "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(uint256 amount)"
        )
    );
    bytes32 private constant TRANSFER_DETAILS_TYPEHASH = keccak256(bytes("TransferDetails(uint256 amount)"));

    function setUp() public {
        ft = new MockFungibleToken();
    }

    function testMetadata() public {
        assertEq(ft.name(), "Test FT");
        assertEq(ft.symbol(), "TEST");
        assertEq(ft.decimals(), 18);
    }

    function testMint() public {
        ft.mint(address(0xC0FFEE), 1e18);

        assertEq(ft.totalSupply(), 1e18);
        assertEq(ft.balanceOf(address(0xC0FFEE)), 1e18);
    }

    function testBurn() public {
        ft.mint(address(0xC0FFEE), 1e18);
        ft.burn(address(0xC0FFEE), 0.9e18);

        assertEq(ft.totalSupply(), 1e18 - 0.9e18);
        assertEq(ft.balanceOf(address(0xC0FFEE)), 0.1e18);
    }

    function testTransfer() public {
        ft.mint(address(this), 1e18);

        assertTrue(ft.transfer(address(0xC0FFEE), abi.encode(ILRTAFungibleToken.ILRTATransferDetails({amount: 1e18}))));
        assertEq(ft.totalSupply(), 1e18);

        assertEq(ft.balanceOf(address(this)), 0);
        assertEq(ft.balanceOf(address(0xC0FFEE)), 1e18);
    }

    function testTransferBySignature() public {
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

    function testTransferGas() public {
        vm.pauseGasMetering();
        ft.mint(address(this), 1e18);
        vm.resumeGasMetering();

        ft.transfer(address(0xC0FFEE), abi.encode(ILRTAFungibleToken.ILRTATransferDetails({amount: 1e18})));
    }

    function testTransferBySignatureGas() public {
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
        vm.resumeGasMetering();

        ft.transferBySignature(
            owner,
            /* solhint-disable-next-line max-line-length */
            ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp, transferDetails: abi.encode(transferDetails)}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)}),
            signature
        );
    }
}
