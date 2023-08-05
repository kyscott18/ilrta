// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "./EIP712.sol";
import {ILRTA} from "./ILRTA.sol";
import {SignatureVerification} from "./SignatureVerification.sol";
import {UnorderedNonce} from "./UnorderedNonce.sol";

contract PermitILRTA is EIP712, UnorderedNonce {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 ERRORS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    error SignatureExpired(uint256 signatureDeadline);

    error LengthMismatch();

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                               DATA TYPES
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    struct TransferDetails {
        address token;
        bytes transferDetails;
    }

    struct SignatureTransfer {
        TransferDetails transferDetails;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferBatch {
        TransferDetails[] transferDetails;
        uint256 nonce;
        uint256 deadline;
    }

    struct RequestedTransferDetails {
        address to;
        bytes transferDetails;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                           SIGNATURE STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    bytes32 private constant TRANSFER_DETAILS_TYPEHASH =
        keccak256("TransferDetails(address token,bytes transferDetails)");

    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        // solhint-disable-next-line max-line-length
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,bytes transferDetails)"
    );

    bytes32 private constant TRANSFER_BATCH_TYPEHASH = keccak256(
        // solhint-disable-next-line max-line-length
        "Transfer(TransferDetails[] transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,bytes transferDetails)"
    );

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              CONSTRUCTOR
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    constructor() EIP712("PermitILRTA") {}

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    /// @notice transfer a token using a signed message
    function transferBySignature(
        address signer,
        SignatureTransfer calldata signatureTransfer,
        RequestedTransferDetails calldata requestedTransfer,
        bytes calldata signature
    )
        external
    {
        if (block.timestamp > signatureTransfer.deadline) revert SignatureExpired(signatureTransfer.deadline);

        ILRTA(signatureTransfer.transferDetails.token).validateRequest(
            signatureTransfer.transferDetails.transferDetails, requestedTransfer.transferDetails
        );

        // compute data hash
        bytes32 signatureHash = hashTypedData(
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

        // validate signature
        useUnorderedNonce(signer, signatureTransfer.nonce);
        SignatureVerification.verify(signature, signatureHash, signer);

        // transfer tokens
        ILRTA(signatureTransfer.transferDetails.token).transferFrom(
            signer, requestedTransfer.to, requestedTransfer.transferDetails
        );
    }

    /// @notice transfer a batch of tokens using a signed message
    function transferBySignature(
        address signer,
        SignatureTransferBatch calldata signatureTransfer,
        RequestedTransferDetails[] calldata requestedTransfer,
        bytes calldata signature
    )
        external
    {
        uint256 length = requestedTransfer.length;

        if (block.timestamp > signatureTransfer.deadline) revert SignatureExpired(signatureTransfer.deadline);
        if (length != signatureTransfer.transferDetails.length) {
            revert LengthMismatch();
        }

        // compute data hash
        bytes32[] memory transferDetailsHashes = new bytes32[](length);
        for (uint256 i = 0; i < length;) {
            transferDetailsHashes[i] =
                keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, signatureTransfer.transferDetails[i]));

            unchecked {
                i++;
            }
        }
        bytes32 signatureHash = hashTypedData(
            keccak256(
                abi.encode(
                    TRANSFER_BATCH_TYPEHASH,
                    keccak256(abi.encodePacked(transferDetailsHashes)),
                    msg.sender,
                    signatureTransfer.nonce,
                    signatureTransfer.deadline
                )
            )
        );

        // validate signature
        useUnorderedNonce(signer, signatureTransfer.nonce);
        SignatureVerification.verify(signature, signatureHash, signer);

        for (uint256 i = 0; i < length;) {
            TransferDetails memory transferDetails = signatureTransfer.transferDetails[i];

            // check request
            ILRTA(transferDetails.token).validateRequest(
                transferDetails.transferDetails, requestedTransfer[i].transferDetails
            );

            // transfer tokens
            ILRTA(transferDetails.token).transferFrom(
                signer, requestedTransfer[i].to, requestedTransfer[i].transferDetails
            );

            unchecked {
                i++;
            }
        }
    }
}
