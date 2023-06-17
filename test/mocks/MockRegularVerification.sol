// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {EIP712} from "src/EIP712.sol";
import {SignatureVerification} from "src/SignatureVerification.sol";
import {SuperSignature} from "src/SuperSignature.sol";
import {UnorderedNonce} from "src/UnorderedNonce.sol";

contract MockRegularVerfication is EIP712, UnorderedNonce {
    constructor() EIP712(keccak256(bytes("MockVerification"))) {}

    bytes32 private constant TYPEHASH = keccak256("Verify(bytes32[] dataHash,uint256 nonce,uint256 deadline)");

    function verifySignature(address signer, SuperSignature.Verify memory verify, bytes calldata signature) external {
        if (block.timestamp > verify.deadline) revert SuperSignature.SignatureExpired(verify.deadline);

        useUnorderedNonce(signer, verify.nonce);

        bytes32 signatureHash =
            hashTypedData(keccak256(abi.encode(TYPEHASH, verify.dataHash, verify.nonce, verify.deadline)));

        SignatureVerification.verify(signature, signatureHash, signer);
    }
}
