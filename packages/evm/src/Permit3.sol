// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "./EIP712.sol";
import {SignatureVerification} from "./SignatureVerification.sol";
import {UnorderedNonce} from "./UnorderedNonce.sol";

/// @title Next generation permit with support for signature transfer of multiple token types
/// @author Kyle Scott
contract Permit3 is EIP712, UnorderedNonce {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 ERRORS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    error SignatureExpired(uint256 signatureDeadline);

    error LengthMismatch();

    error InvalidRequest(bytes transferDetailsBytes);

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                               DATA TYPES
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    enum TokenType {
        ERC20,
        // ERC721,
        // ERC1155,
        ILRTA
    }

    struct TransferDetails {
        address token;
        TokenType tokenType;
        bytes4 functionSelector;
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
        keccak256("TransferDetails(address token,uint8 tokenType,bytes4 functionSelector,bytes transferDetails)");

    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        // solhint-disable-next-line max-line-length
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint8 tokenType,bytes4 functionSelector,bytes transferDetails)"
    );

    bytes32 private constant TRANSFER_BATCH_TYPEHASH = keccak256(
        // solhint-disable-next-line max-line-length
        "Transfer(TransferDetails[] transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint8 tokenType,bytes4 functionSelector,bytes transferDetails)"
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

        _validateRequest(signatureTransfer.transferDetails, requestedTransfer.transferDetails);

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

        _transfer(signer, requestedTransfer.to, signatureTransfer.transferDetails, requestedTransfer.transferDetails);
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

            _validateRequest(transferDetails, requestedTransfer[i].transferDetails);

            _transfer(signer, requestedTransfer[i].to, transferDetails, requestedTransfer[i].transferDetails);

            unchecked {
                i++;
            }
        }
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                             INTERNAL LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function _validateRequest(
        TransferDetails memory signedTransferDetails,
        bytes memory requestedTransferDetails
    )
        private
        view
    {
        if (signedTransferDetails.tokenType == TokenType.ERC20) {
            // revert InvalidRequest(requestedTransferDetails);
        } else {
            // revert InvalidRequest(requestedTransferDetails);
            // call to ilrta
            // mine the function selector
        }
    }

    function _transfer(
        address from,
        address to,
        TransferDetails memory signedTransferDetails,
        bytes memory requestedTransferDetails
    )
        private
    {}
}
