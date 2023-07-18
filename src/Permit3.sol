// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "./EIP712.sol";
import {SignatureVerification} from "./SignatureVerification.sol";
import {SuperSignature} from "./SuperSignature.sol";
import {UnorderedNonce} from "./UnorderedNonce.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract Permit3 is EIP712, UnorderedNonce {
    using SafeTransferLib for ERC20;

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 ERRORS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    error SignatureExpired(uint256 signatureDeadline);

    error InvalidAmount(uint256 maxAmount);

    error DataHashMismatch();

    error LengthMismatch();

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                               DATA TYPES
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    struct TransferDetails {
        address token;
        uint256 amount;
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
        uint256 amount;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                           SIGNATURE STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    SuperSignature private immutable superSignature;

    bytes32 public constant TRANSFER_DETAILS_TYPEHASH = keccak256("TransferDetails(address token,uint256 amount)");

    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        // solhint-disable-next-line max-line-length
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint256 amount)"
    );

    bytes32 private constant TRANSFER_BATCH_TYPEHASH = keccak256(
        // solhint-disable-next-line max-line-length
        "Transfer(TransferDetails[] transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint256 amount)"
    );

    bytes32 private constant SUPER_SIGNATURE_TRANSFER_TYPEHASH = keccak256(
        "Transfer(TransferDetails transferDetails,address spender)TransferDetails(address token,uint256 amount)"
    );

    bytes32 private constant SUPER_SIGNATURE_TRANSFER_BATCH_TYPEHASH = keccak256(
        "Transfer(TransferDetails[] transferDetails,address spender)TransferDetails(address token,uint256 amount)"
    );

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              CONSTRUCTOR
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    constructor(address _superSignature) EIP712("Permit3") {
        superSignature = SuperSignature(_superSignature);
    }

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
        if (requestedTransfer.amount > signatureTransfer.transferDetails.amount) {
            revert InvalidAmount(signatureTransfer.transferDetails.amount);
        }

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

        ERC20(signatureTransfer.transferDetails.token).safeTransferFrom(
            signer, requestedTransfer.to, requestedTransfer.amount
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
        bytes32[] memory transfeDetailsHashes = new bytes32[](length);
        for (uint256 i = 0; i < length;) {
            transfeDetailsHashes[i] =
                keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, signatureTransfer.transferDetails[i]));

            unchecked {
                i++;
            }
        }
        bytes32 signatureHash = hashTypedData(
            keccak256(
                abi.encode(
                    TRANSFER_BATCH_TYPEHASH,
                    keccak256(abi.encodePacked(transfeDetailsHashes)),
                    msg.sender,
                    signatureTransfer.nonce,
                    signatureTransfer.deadline
                )
            )
        );

        // validate signature
        useUnorderedNonce(signer, signatureTransfer.nonce);
        SignatureVerification.verify(signature, signatureHash, signer);

        // check requests and transfer out tokens
        for (uint256 i = 0; i < length;) {
            TransferDetails memory transferDetails = signatureTransfer.transferDetails[i];

            if (requestedTransfer[i].amount > transferDetails.amount) {
                revert InvalidAmount(transferDetails.amount);
            }

            if (requestedTransfer[i].amount > 0) {
                ERC20(transferDetails.token).safeTransferFrom(
                    signer, requestedTransfer[i].to, requestedTransfer[i].amount
                );
            }

            unchecked {
                i++;
            }
        }
    }

    /// @notice transfer a token using a signed message, relying on the super signature contract to validate the data
    /// @dev assumes that the data has already been verified in the super signature contract
    function transferBySuperSignature(
        address signer,
        TransferDetails calldata transferDetails,
        RequestedTransferDetails calldata requestedTransfer,
        bytes32[] calldata dataHash
    )
        external
    {
        if (requestedTransfer.amount > transferDetails.amount) {
            revert InvalidAmount(transferDetails.amount);
        }

        // compute data hash
        bytes32 signatureHash = hashTypedData(
            keccak256(
                abi.encode(
                    SUPER_SIGNATURE_TRANSFER_TYPEHASH,
                    keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, transferDetails)),
                    msg.sender
                )
            )
        );

        // validate that this data was signed using super signature
        if (dataHash[0] != signatureHash) revert DataHashMismatch();
        superSignature.verifyData(signer, dataHash);

        // transfer out tokens
        ERC20(transferDetails.token).safeTransferFrom(signer, requestedTransfer.to, requestedTransfer.amount);
    }

    /// @notice transfer a batch of tokens using a signed message, relying on the super signature contract to validate
    /// the data
    /// @dev assumes that the data has already been verified in the super signature contract
    function transferBySuperSignature(
        address signer,
        TransferDetails[] calldata transferDetails,
        RequestedTransferDetails[] calldata requestedTransfer,
        bytes32[] calldata dataHash
    )
        external
    {
        uint256 length = requestedTransfer.length;

        if (length != transferDetails.length) {
            revert LengthMismatch();
        }

        // compute data hash
        bytes32[] memory transfeDetailsHashes = new bytes32[](length);
        for (uint256 i = 0; i < length;) {
            transfeDetailsHashes[i] =
                hashTypedData(keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, transferDetails[i])));

            unchecked {
                i++;
            }
        }
        bytes32 signatureHash = keccak256(
            abi.encode(
                SUPER_SIGNATURE_TRANSFER_BATCH_TYPEHASH, keccak256(abi.encodePacked(transfeDetailsHashes)), msg.sender
            )
        );

        // validate that this data was signed using super signature
        if (dataHash[0] != signatureHash) revert DataHashMismatch();
        superSignature.verifyData(signer, dataHash);

        // check requests and transfer out tokens
        for (uint256 i = 0; i < length;) {
            if (requestedTransfer[i].amount > transferDetails[i].amount) {
                revert InvalidAmount(transferDetails[i].amount);
            }

            if (requestedTransfer[i].amount > 0) {
                ERC20(transferDetails[i].token).safeTransferFrom(
                    signer, requestedTransfer[i].to, requestedTransfer[i].amount
                );
            }

            unchecked {
                i++;
            }
        }
    }
}
