// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {SuperSignature} from "src/SuperSignature.sol";
import {SignatureVerification} from "src/SignatureVerification.sol";
import {UnorderedNonce} from "src/UnorderedNonce.sol";

contract SuperSignerTest is Test {
    SuperSignature private superSignature;

    bytes32 private constant TYPEHASH = keccak256("Verify(bytes32[] dataHash,uint256 nonce,uint256 deadline)");

    function signSuperSignature(
        SuperSignature.Verify memory verify,
        uint256 privateKey
    )
        private
        view
        returns (bytes memory signature)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    superSignature.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            TYPEHASH, keccak256(abi.encodePacked(verify.dataHash)), verify.nonce, verify.deadline
                        )
                    )
                )
            )
        );

        return abi.encodePacked(r, s, v);
    }

    function setUp() external {
        superSignature = new SuperSignature();
    }

    function testVerifyAndStoreRoot() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = bytes32(uint256(0x69));

        SuperSignature.Verify memory verify = SuperSignature.Verify(dataHash, 0, block.timestamp);

        bytes memory signature = signSuperSignature(verify, privateKey);

        superSignature.verifyAndStoreRoot(owner, verify, signature);

        assertEq(vm.load(address(superSignature), bytes32(uint256(1))), keccak256(abi.encodePacked(owner, dataHash)));
    }

    function testVerifyData() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = bytes32(uint256(0x69));

        SuperSignature.Verify memory verify = SuperSignature.Verify(dataHash, 0, block.timestamp);

        bytes memory signature = signSuperSignature(verify, privateKey);

        superSignature.verifyAndStoreRoot(owner, verify, signature);

        superSignature.verifyData(owner, dataHash);

        assertEq(vm.load(address(superSignature), bytes32(uint256(1))), 0);
    }

    function testGas() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = bytes32(uint256(0x69));

        SuperSignature.Verify memory verify = SuperSignature.Verify(dataHash, 0, block.timestamp);

        bytes memory signature = signSuperSignature(verify, privateKey);

        vm.resumeGasMetering();

        superSignature.verifyAndStoreRoot(owner, verify, signature);

        superSignature.verifyData(owner, dataHash);
    }

    function testGasTwoData() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](2);
        dataHash[0] = bytes32(uint256(0x68));
        dataHash[1] = bytes32(uint256(0x69));

        bytes32[] memory dataHash1 = new bytes32[](1);
        dataHash1[0] = dataHash[1];

        SuperSignature.Verify memory verify = SuperSignature.Verify(dataHash, 0, block.timestamp);

        bytes memory signature = signSuperSignature(verify, privateKey);

        vm.resumeGasMetering();

        superSignature.verifyAndStoreRoot(owner, verify, signature);

        superSignature.verifyData(owner, dataHash);
        superSignature.verifyData(owner, dataHash1);
    }

    function testGasTwoDataWithOffset() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](2);
        dataHash[0] = bytes32(uint256(0x68));
        dataHash[1] = bytes32(uint256(0x69));

        bytes32[] memory dataHash1 = new bytes32[](1);
        dataHash1[0] = dataHash[1];

        SuperSignature.Verify memory verify = SuperSignature.Verify(dataHash, 0, block.timestamp);

        bytes memory signature = signSuperSignature(verify, privateKey);

        vm.resumeGasMetering();

        superSignature.verifyAndStoreRoot(owner, verify, signature);

        superSignature.verifyData(owner, dataHash, 2);
    }

    function testSignatureBadNonce1() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = bytes32(uint256(0x69));

        bytes memory signature = signSuperSignature(SuperSignature.Verify(dataHash, 1, block.timestamp), privateKey);

        vm.expectRevert(SignatureVerification.InvalidSigner.selector);
        superSignature.verifyAndStoreRoot(owner, SuperSignature.Verify(dataHash, 0, block.timestamp), signature);
    }

    function testSignatureBadNonce2() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = bytes32(uint256(0x69));

        bytes memory signature = signSuperSignature(SuperSignature.Verify(dataHash, 0, block.timestamp), privateKey);

        vm.expectRevert(SignatureVerification.InvalidSigner.selector);
        superSignature.verifyAndStoreRoot(owner, SuperSignature.Verify(dataHash, 1, block.timestamp), signature);
    }

    function testSignatureBadDeadline() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = bytes32(uint256(0x69));

        bytes memory signature = signSuperSignature(SuperSignature.Verify(dataHash, 0, block.timestamp), privateKey);

        vm.expectRevert(SignatureVerification.InvalidSigner.selector);
        superSignature.verifyAndStoreRoot(owner, SuperSignature.Verify(dataHash, 0, block.timestamp + 1), signature);
    }

    function testSignaturePastDeadline() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = bytes32(uint256(0x69));

        bytes memory signature = signSuperSignature(SuperSignature.Verify(dataHash, 0, block.timestamp), privateKey);

        vm.warp(block.timestamp + 1);

        vm.expectRevert(abi.encodeWithSelector(SuperSignature.SignatureExpired.selector, block.timestamp - 1));
        superSignature.verifyAndStoreRoot(owner, SuperSignature.Verify(dataHash, 0, block.timestamp - 1), signature);
    }

    function testSignatureReplay() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = bytes32(uint256(0x69));

        bytes memory signature = signSuperSignature(SuperSignature.Verify(dataHash, 0, block.timestamp), privateKey);

        superSignature.verifyAndStoreRoot(owner, SuperSignature.Verify(dataHash, 0, block.timestamp), signature);

        vm.expectRevert(abi.encodeWithSelector(UnorderedNonce.InvalidNonce.selector, 0));
        superSignature.verifyAndStoreRoot(owner, SuperSignature.Verify(dataHash, 0, block.timestamp), signature);
    }

    function testVerifyDataInvalid() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = bytes32(uint256(0x69));

        bytes memory signature = signSuperSignature(SuperSignature.Verify(dataHash, 0, block.timestamp), privateKey);

        superSignature.verifyAndStoreRoot(owner, SuperSignature.Verify(dataHash, 0, block.timestamp), signature);

        vm.expectRevert(SuperSignature.InvalidSignature.selector);
        superSignature.verifyData(address(this), dataHash);
    }

    function testVerifyDataOffsetInvalid() external {
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory dataHash = new bytes32[](1);
        dataHash[0] = bytes32(uint256(0x69));

        bytes memory signature = signSuperSignature(SuperSignature.Verify(dataHash, 0, block.timestamp), privateKey);

        superSignature.verifyAndStoreRoot(owner, SuperSignature.Verify(dataHash, 0, block.timestamp), signature);

        vm.expectRevert(SuperSignature.InvalidSignature.selector);
        superSignature.verifyData(address(this), dataHash, 1);
    }
}
