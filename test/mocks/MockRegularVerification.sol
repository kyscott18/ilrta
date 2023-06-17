// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {EIP712} from "src/EIP712.sol";
import {SignatureVerification} from "src/SignatureVerification.sol";
import {SuperSignature} from "src/SuperSignature.sol";

contract MockRegularVerfication is EIP712 {
    constructor() EIP712(keccak256(bytes("MockVerification"))) {}

    bytes32 private constant TYPEHASH = keccak256("Verify(bytes32[] dataHash,uint256 nonce,uint256 deadline)");

    mapping(address => mapping(uint256 => uint256)) public nonceBitmap;

    function verifySignature(address signer, SuperSignature.Verify memory verify, bytes calldata signature) external {
        if (block.timestamp > verify.deadline) revert SuperSignature.SignatureExpired(verify.deadline);

        useUnorderedNonce(signer, verify.nonce);

        bytes32 signatureHash =
            hashTypedData(keccak256(abi.encode(TYPEHASH, verify.dataHash, verify.nonce, verify.deadline)));

        SignatureVerification.verify(signature, signatureHash, signer);
    }

    function bitmapPositions(uint256 nonce) private pure returns (uint256 wordPos, uint256 bitPos) {
        wordPos = uint248(nonce >> 8);
        bitPos = uint8(nonce);
    }

    function useUnorderedNonce(address from, uint256 nonce) private {
        (uint256 wordPos, uint256 bitPos) = bitmapPositions(nonce);
        uint256 bit = 1 << bitPos;
        uint256 flipped = nonceBitmap[from][wordPos] ^= bit;

        if (flipped & bit == 0) revert SuperSignature.InvalidNonce(nonce);
    }
}
