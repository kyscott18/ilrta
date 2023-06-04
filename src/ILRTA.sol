// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { EIP712 } from "./EIP712.sol";
import { SignatureVerification } from "permit2/libraries/SignatureVerification.sol";

abstract contract ILRTA is EIP712 {
    /*(((((((((((((((((((((((((((EVENTS)))))))))))))))))))))))))))*/

    event Transfer(address indexed from, address indexed to, bytes data);

    /*(((((((((((((((((((((((((((ERRORS)))))))))))))))))))))))))))*/

    error SignatureExpired(uint256 signatureDeadline);

    error InvalidRequest(bytes transferDetailsBytes);

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

    string internal constant TRANSFER_ENCODE_TYPE =
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)";

    bytes32 internal immutable TRANSFER_TYPEHASH;

    bytes32 internal immutable TRANSFER_DETAILS_TYPEHASH;

    /*(((((((((((((((((((((((((((STORAGE))))))))))))))))))))))))))*/

    /// @custom:team permit2 allows for unordered nonces, and includes a nonce bitmap
    mapping(address => uint256) public nonces;

    constructor(string memory transferDetailsEncodeType) {
        TRANSFER_TYPEHASH = keccak256(bytes(string.concat(transferDetailsEncodeType, TRANSFER_ENCODE_TYPE)));
        TRANSFER_DETAILS_TYPEHASH = keccak256(bytes(transferDetailsEncodeType));
    }

    /*((((((((((((((((((((((((((((LOGIC)))))))))))))))))))))))))))*/

    function transfer(address to, bytes calldata transferDetails) external virtual returns (bool);

    function transferBySignature(
        address from,
        bytes calldata signatureTransferBytes,
        bytes calldata requestedTransferBytes,
        bytes calldata signature
    )
        external
        virtual
        returns (bool);

    function verifySignature(
        address from,
        SignatureTransfer memory signatureTransfer,
        bytes calldata signature
    )
        internal
    {
        if (block.timestamp > signatureTransfer.deadline) revert SignatureExpired(signatureTransfer.deadline);

        bytes32 signatureHash;
        unchecked {
            signatureHash = hashTypedData(
                keccak256(
                    abi.encode(
                        TRANSFER_TYPEHASH,
                        keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, signatureTransfer.transferDetails)),
                        msg.sender,
                        nonces[from]++,
                        signatureTransfer.deadline
                    )
                )
            );
        }

        SignatureVerification.verify(signature, signatureHash, from);
    }
}
