// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "./EIP712.sol";
import {SignatureVerification} from "permit2/libraries/SignatureVerification.sol";

abstract contract ILRTA is EIP712 {
    /*(((((((((((((((((((((((((((EVENTS)))))))))))))))))))))))))))*/

    event Transfer(address indexed from, address indexed to, bytes data);

    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /*(((((((((((((((((((((((((((ERRORS)))))))))))))))))))))))))))*/

    error SignatureExpired(uint256 signatureDeadline);

    error InvalidRequest(bytes transferDetailsBytes);

    error InvalidNonce();

    /*(((((((((((((((((((((((((DATA TYPES)))))))))))))))))))))))))*/

    struct SignatureTransfer {
        uint256 nonce;
        uint256 deadline;
        bytes transferDetails;
    }

    struct RequestedTransfer {
        address to;
        bytes transferDetails;
    }

    string private constant TRANSFER_ENCODE_TYPE =
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)";

    bytes32 internal immutable TRANSFER_TYPEHASH;

    bytes32 internal immutable TRANSFER_DETAILS_TYPEHASH;

    /*(((((((((((((((((((((((((((STORAGE))))))))))))))))))))))))))*/

    mapping(address => mapping(uint256 => uint256)) public nonceBitmap;

    constructor(string memory transferDetailsEncodeType) {
        TRANSFER_TYPEHASH = keccak256(bytes(string.concat(TRANSFER_ENCODE_TYPE, transferDetailsEncodeType)));
        TRANSFER_DETAILS_TYPEHASH = keccak256(bytes(transferDetailsEncodeType));
    }

    /*((((((((((((((((((((((((((((LOGIC)))))))))))))))))))))))))))*/

    function dataOf(address owner) external view virtual returns (bytes memory);

    function transfer(address to, bytes calldata transferDetails) external virtual returns (bool);

    function transferBySignature(
        address from,
        SignatureTransfer calldata signatureTransfer,
        RequestedTransfer calldata requestedTransfer,
        bytes calldata signature
    )
        external
        virtual
        returns (bool);

    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external {
        nonceBitmap[msg.sender][wordPos] |= mask;

        emit UnorderedNonceInvalidation(msg.sender, wordPos, mask);
    }

    function verifySignature(
        address from,
        SignatureTransfer memory signatureTransfer,
        bytes calldata signature
    )
        internal
    {
        if (block.timestamp > signatureTransfer.deadline) revert SignatureExpired(signatureTransfer.deadline);

        useUnorderedNonce(from, signatureTransfer.nonce);

        bytes32 signatureHash;

        signatureHash = hashTypedData(
            keccak256(
                abi.encode(
                    TRANSFER_TYPEHASH,
                    keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, signatureTransfer.transferDetails)),
                    msg.sender,
                    signatureTransfer.nonce,
                    signatureTransfer.deadline
                )
            )
        );

        SignatureVerification.verify(signature, signatureHash, from);
    }

    /// @notice Returns the index of the bitmap and the bit position within the bitmap. Used for unordered nonces
    /// @param nonce The nonce to get the associated word and bit positions
    /// @return wordPos The word position or index into the nonceBitmap
    /// @return bitPos The bit position
    /// @dev The first 248 bits of the nonce value is the index of the desired bitmap
    /// @dev The last 8 bits of the nonce value is the position of the bit in the bitmap
    function bitmapPositions(uint256 nonce) private pure returns (uint256 wordPos, uint256 bitPos) {
        wordPos = uint248(nonce >> 8);
        bitPos = uint8(nonce);
    }

    /// @notice Checks whether a nonce is taken and sets the bit at the bit position in the bitmap at the word position
    /// @param from The address to use the nonce at
    /// @param nonce The nonce to spend
    function useUnorderedNonce(address from, uint256 nonce) internal {
        (uint256 wordPos, uint256 bitPos) = bitmapPositions(nonce);
        uint256 bit = 1 << bitPos;
        uint256 flipped = nonceBitmap[from][wordPos] ^= bit;

        if (flipped & bit == 0) revert InvalidNonce();
    }
}
