// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {ILRTA} from "src/ILRTA.sol";
import {ERC20} from "src/examples/ERC20.sol";
import {SuperSignature} from "src/SuperSignature.sol";

contract ERC20Test is Test {
    MockERC20 private erc20;
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
        erc20 = new MockERC20(address(superSignature));
    }

    function testMetadata() external {
        assertEq(erc20.name(), "Test ERC20");
        assertEq(erc20.symbol(), "TEST");
        assertEq(erc20.decimals(), 18);
    }

    function testMint() external {
        erc20.mint(address(0xC0FFEE), 1e18);

        assertEq(erc20.totalSupply(), 1e18);
        assertEq(erc20.balanceOf(address(0xC0FFEE)), 1e18);
    }

    function testBurn() external {
        erc20.mint(address(0xC0FFEE), 1e18);
        erc20.burn(address(0xC0FFEE), 0.9e18);

        assertEq(erc20.totalSupply(), 1e18 - 0.9e18);
        assertEq(erc20.balanceOf(address(0xC0FFEE)), 0.1e18);
    }

    function testTransfer() external {
        erc20.mint(address(this), 1e18);

        assertTrue(erc20.transfer(address(0xC0FFEE), 1e18));
        assertEq(erc20.totalSupply(), 1e18);

        assertEq(erc20.balanceOf(address(this)), 0);
        assertEq(erc20.balanceOf(address(0xC0FFEE)), 1e18);
    }

    function testTransferBySignature() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        erc20.mint(address(owner), 1e18);

        ERC20.ILRTATransferDetails memory transferDetails = ERC20.ILRTATransferDetails({amount: 1e18});

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    erc20.DOMAIN_SEPARATOR(),
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
            erc20.transferBySignature(
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
        assertEq(erc20.totalSupply(), 1e18);

        assertEq(erc20.balanceOf(address(this)), 1e18);
        assertEq(erc20.balanceOf(address(owner)), 0);
    }

    function testTransferBySuperSignature() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        erc20.mint(owner, 1e18);

        ERC20.ILRTATransferDetails memory transferDetails = ERC20.ILRTATransferDetails({amount: 1e18});

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
            erc20.transferBySuperSignature(
                owner,
                abi.encode(transferDetails),
                ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)}),
                dataHash
            )
        );
    }

    function testGasTransfer() external {
        vm.pauseGasMetering();
        erc20.mint(address(this), 1e18);
        vm.resumeGasMetering();

        erc20.transfer(address(0xC0FFEE), 1e18);
    }

    function testGasTransferBySignature() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        erc20.mint(address(owner), 1e18);

        ERC20.ILRTATransferDetails memory transferDetails = ERC20.ILRTATransferDetails({amount: 1e18});

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    erc20.DOMAIN_SEPARATOR(),
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

        erc20.transferBySignature(
            owner,
            /* solhint-disable-next-line max-line-length */
            ILRTA.SignatureTransfer({nonce: 0, deadline: block.timestamp, transferDetails: abi.encode(transferDetails)}),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)}),
            signature
        );
    }

    function testGasTransferBySuperSignature() external {
        vm.pauseGasMetering();

        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        erc20.mint(owner, 1e18);

        ERC20.ILRTATransferDetails memory transferDetails = ERC20.ILRTATransferDetails({amount: 1e18});

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

        erc20.transferBySuperSignature(
            owner,
            abi.encode(transferDetails),
            ILRTA.RequestedTransfer({to: address(this), transferDetails: abi.encode(transferDetails)}),
            dataHash
        );
    }
}
