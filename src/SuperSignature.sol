// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "./EIP712.sol";
import {SignatureVerification} from "./SignatureVerification.sol";

/// @author Kyle Scott
/// @custom:question Is there a potential vulnerability with using a dirty root
contract SuperSignature is EIP712 {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 EVENTS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 ERRORS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    error SignatureExpired(uint256 signatureDeadline);

    error InvalidNonce(uint256 nonce);

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

    mapping(address => mapping(uint256 => uint256)) public nonceBitmap;

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

        bytes32 signatureHash =
            hashTypedData(keccak256(abi.encode(TYPEHASH, verify.dataHash, verify.nonce, verify.deadline)));

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

    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external {
        nonceBitmap[msg.sender][wordPos] |= mask;

        emit UnorderedNonceInvalidation(msg.sender, wordPos, mask);
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                             INTERNAL LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function bitmapPositions(uint256 nonce) private pure returns (uint256 wordPos, uint256 bitPos) {
        wordPos = uint248(nonce >> 8);
        bitPos = uint8(nonce);
    }

    function useUnorderedNonce(address from, uint256 nonce) private {
        (uint256 wordPos, uint256 bitPos) = bitmapPositions(nonce);
        uint256 bit = 1 << bitPos;
        uint256 flipped = nonceBitmap[from][wordPos] ^= bit;

        if (flipped & bit == 0) revert InvalidNonce(nonce);
    }

    function buildRoot(address signer, bytes32[] calldata dataHash) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(signer, dataHash));
    }
}
