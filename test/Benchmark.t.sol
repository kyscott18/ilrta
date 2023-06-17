// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {SuperSignature} from "src/SuperSignature.sol";
import {MockRegularVerfication} from "./mocks/MockRegularVerification.sol";

contract SuperSignerTest is Test {
    MockRegularVerfication private verifier;

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
                    verifier.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(TYPEHASH, verify.dataHash, verify.nonce, verify.deadline))
                )
            )
        );

        return abi.encodePacked(r, s, v);
    }

    function setUp() external {
        verifier = new MockRegularVerfication();
    }

    function testGasBenchmark() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);

        bytes32[] memory leafs = new bytes32[](1);
        leafs[0] = bytes32(uint256(0x69));

        SuperSignature.Verify memory superSignature = SuperSignature.Verify(leafs, 0, block.timestamp);

        bytes memory signature = signSuperSignature(superSignature, privateKey);

        vm.resumeGasMetering();

        verifier.verifySignature(owner, superSignature, signature);
    }
}
