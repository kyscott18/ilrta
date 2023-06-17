// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "./EIP712.sol";
import {SignatureVerification} from "./SignatureVerification.sol";
import {UnorderedNonce} from "./UnorderedNonce.sol";

/// @author Kyle Scott
/// @custom:question Is there a potential vulnerability with using a dirty root
contract SuperSignature is EIP712, UnorderedNonce {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 ERRORS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    error SignatureExpired(uint256 signatureDeadline);

    error InvalidSignature();

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                               DATA TYPES
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    struct Verify {
        bytes32[] dataHash;
        uint256 nonce;
        uint256 deadline;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                           TRANSIENT STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    bytes32 private root;

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                           SIGNATURE STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    bytes32 private constant TYPEHASH = keccak256("Verify(bytes32[] dataHash,uint256 nonce,uint256 deadline)");

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              CONSTRUCTOR
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    constructor() EIP712(keccak256(bytes("SuperSignatureV1"))) {}

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function verifyAndStoreRoot(address signer, Verify calldata verify, bytes calldata signature) external {
        if (block.timestamp > verify.deadline) revert SignatureExpired(verify.deadline);

        useUnorderedNonce(signer, verify.nonce);

        bytes32 signatureHash = hashTypedData(
            keccak256(abi.encode(TYPEHASH, keccak256(abi.encodePacked(verify.dataHash)), verify.nonce, verify.deadline))
        );

        SignatureVerification.verify(signature, signatureHash, signer);

        root = buildRoot(signer, verify.dataHash);
    }

    function verifyData(address signer, bytes32[] calldata dataHash) external {
        if (buildRoot(signer, dataHash) != root) revert InvalidSignature();

        if (dataHash.length > 1) root = buildRoot(signer, dataHash[1:]);
        else delete root;
    }

    function verifyData(address signer, bytes32[] calldata dataHash, uint256 offset) external {
        if (buildRoot(signer, dataHash) != root) revert InvalidSignature();

        if (dataHash.length > offset) root = buildRoot(signer, dataHash[offset:]);
        else delete root;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                             INTERNAL LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function buildRoot(address signer, bytes32[] calldata dataHash) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(signer, dataHash));
    }
}
