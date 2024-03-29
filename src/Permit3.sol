// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "./EIP712.sol";
import {SignatureVerification} from "./SignatureVerification.sol";
import {UnorderedNonce} from "./UnorderedNonce.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

/// @title Next generation permit with support for signature transfer of multiple token types
/// @author Kyle Scott
contract Permit3 is EIP712, UnorderedNonce {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 ERRORS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    error SignatureExpired(uint256 signatureDeadline);

    error LengthMismatch();

    error InvalidRequest(bytes transferDetailsBytes);

    error InvalidRequestERC20(uint256 amount);

    error TransferFailed();

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                               DATA TYPES
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    enum TokenType {
        ERC20,
        ILRTA
    }

    struct TransferDetails {
        address token;
        TokenType tokenType;
        uint32 functionSelector;
        bytes transferDetails;
    }

    struct TransferDetailsERC20 {
        address token;
        uint256 amount;
    }

    struct SignatureTransfer {
        TransferDetails transferDetails;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferERC20 {
        TransferDetailsERC20 transferDetails;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferBatch {
        TransferDetails[] transferDetails;
        uint256 nonce;
        uint256 deadline;
    }

    struct SignatureTransferBatchERC20 {
        TransferDetailsERC20[] transferDetails;
        uint256 nonce;
        uint256 deadline;
    }

    struct RequestedTransferDetails {
        address to;
        bytes transferDetails;
    }

    struct RequestedTransferDetailsERC20 {
        address to;
        uint256 amount;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                           SIGNATURE STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    bytes32 private constant TRANSFER_DETAILS_TYPEHASH =
        keccak256("TransferDetails(address token,uint8 tokenType,uint32 functionSelector,bytes transferDetails)");

    bytes32 private constant TRANSFER_DETAILS_ERC20_TYPEHASH =
        keccak256("TransferDetails(address token,uint256 amount)");

    bytes32 private constant TRANSFER_TYPEHASH = keccak256(
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint8 tokenType,uint32 functionSelector,bytes transferDetails)"
    );

    bytes32 private constant TRANSFER_ERC20_TYPEHASH = keccak256(
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint256 amount)"
    );

    bytes32 private constant TRANSFER_BATCH_TYPEHASH = keccak256(
        "Transfer(TransferDetails[] transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint8 tokenType,uint32 functionSelector,bytes transferDetails)"
    );

    bytes32 private constant TRANSFER_BATCH_ERC20_TYPEHASH = keccak256(
        "Transfer(TransferDetails[] transferDetails,address spender,uint256 nonce,uint256 deadline)TransferDetails(address token,uint256 amount)"
    );

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              CONSTRUCTOR
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    constructor() EIP712("Permit3") {}

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    /// @notice Transfer a token using a signed message
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
                    keccak256(
                        abi.encode(
                            TRANSFER_DETAILS_TYPEHASH,
                            signatureTransfer.transferDetails.token,
                            signatureTransfer.transferDetails.tokenType,
                            signatureTransfer.transferDetails.functionSelector,
                            keccak256(signatureTransfer.transferDetails.transferDetails)
                        )
                    ),
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

    /// @notice Transfer an erc20 token using a signed message
    function transferBySignature(
        address signer,
        SignatureTransferERC20 calldata signatureTransfer,
        RequestedTransferDetailsERC20 calldata requestedTransfer,
        bytes calldata signature
    )
        external
    {
        if (block.timestamp > signatureTransfer.deadline) revert SignatureExpired(signatureTransfer.deadline);

        if (requestedTransfer.amount > signatureTransfer.transferDetails.amount) {
            revert InvalidRequestERC20(requestedTransfer.amount);
        }

        // compute data hash
        bytes32 signatureHash = hashTypedData(
            keccak256(
                abi.encode(
                    TRANSFER_ERC20_TYPEHASH,
                    keccak256(abi.encode(TRANSFER_DETAILS_ERC20_TYPEHASH, signatureTransfer.transferDetails)),
                    msg.sender,
                    signatureTransfer.nonce,
                    signatureTransfer.deadline
                )
            )
        );

        // validate signature
        useUnorderedNonce(signer, signatureTransfer.nonce);
        SignatureVerification.verify(signature, signatureHash, signer);

        SafeTransferLib.safeTransferFrom(
            ERC20(signatureTransfer.transferDetails.token), signer, requestedTransfer.to, requestedTransfer.amount
        );
    }

    /// @notice Transfer a batch of tokens using a signed message
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
            transferDetailsHashes[i] = keccak256(
                abi.encode(
                    TRANSFER_DETAILS_TYPEHASH,
                    signatureTransfer.transferDetails[i].token,
                    signatureTransfer.transferDetails[i].tokenType,
                    signatureTransfer.transferDetails[i].functionSelector,
                    keccak256(signatureTransfer.transferDetails[i].transferDetails)
                )
            );

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

    /// @notice Transfer a batch of erc20 tokens using a signed message
    function transferBySignature(
        address signer,
        SignatureTransferBatchERC20 calldata signatureTransfer,
        RequestedTransferDetailsERC20[] calldata requestedTransfer,
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
                keccak256(abi.encode(TRANSFER_DETAILS_ERC20_TYPEHASH, signatureTransfer.transferDetails[i]));

            unchecked {
                i++;
            }
        }
        bytes32 signatureHash = hashTypedData(
            keccak256(
                abi.encode(
                    TRANSFER_BATCH_ERC20_TYPEHASH,
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
            TransferDetailsERC20 memory transferDetails = signatureTransfer.transferDetails[i];

            if (requestedTransfer[i].amount > transferDetails.amount) {
                revert InvalidRequestERC20(requestedTransfer[i].amount);
            }

            SafeTransferLib.safeTransferFrom(
                ERC20(transferDetails.token), signer, requestedTransfer[i].to, requestedTransfer[i].amount
            );

            unchecked {
                i++;
            }
        }
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                             INTERNAL LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function _validateRequest(
        TransferDetails memory signatureTransfer,
        bytes memory requestedTransferDetails
    )
        private
        view
    {
        if (signatureTransfer.tokenType == TokenType.ERC20) {
            uint256 signedAmount = abi.decode(signatureTransfer.transferDetails, (uint256));
            uint256 requestedAmount = abi.decode(requestedTransferDetails, (uint256));
            if (requestedAmount > signedAmount) revert InvalidRequest(requestedTransferDetails);
        } else {
            bytes memory signedTransferDetails = signatureTransfer.transferDetails;

            uint256 signedTransferLength = signedTransferDetails.length;
            uint256 requestedTransferLength = requestedTransferDetails.length;

            if (signedTransferLength != requestedTransferLength) {
                revert InvalidRequest(requestedTransferDetails);
            }

            bool success;
            assembly {
                let freeMemoryPointer := mload(0x40)
                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(freeMemoryPointer, 0x95a41eb500000000000000000000000000000000000000000000000000000000)

                // Append the signature transfer details
                let offset := add(freeMemoryPointer, 4)
                let signedTransferLocation := add(signedTransferDetails, 0x20)
                for { let i := 0 } lt(i, signedTransferLength) { i := add(i, 0x20) } {
                    mstore(add(offset, i), mload(add(signedTransferLocation, i)))
                }

                // Append the requested transfer details
                let requestedTransferLocation := add(requestedTransferDetails, 0x20)
                offset := add(offset, signedTransferLength)
                for { let i := 0 } lt(i, signedTransferLength) { i := add(i, 0x20) } {
                    mstore(add(offset, i), mload(add(requestedTransferLocation, i)))
                }

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it
                        // returned exactly 1.
                        eq(mload(0), 1),
                        // Counterintuitively, this call must be positioned second to the or() call in the
                        // surrounding and() call or else returndatasize() will be zero during the computation.
                        staticcall(
                            gas(), mload(signatureTransfer), freeMemoryPointer, add(4, mul(2, signedTransferLength)), 0, 32
                        )
                    )
            }

            if (!success) revert InvalidRequest(requestedTransferDetails);
        }
    }

    function _transfer(
        address from,
        address to,
        TransferDetails memory signedTransferDetails,
        bytes memory requestedTransferDetails
    )
        private
    {
        bool success;
        assembly {
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            let functionSelector := shl(224, mload(add(signedTransferDetails, 0x40)))
            mstore(freeMemoryPointer, functionSelector)

            // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))

            // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))

            // Append the transfer details
            let transferDetailsLength := mload(requestedTransferDetails)
            let offset := add(freeMemoryPointer, 68)
            let requestedTransferLocation := add(requestedTransferDetails, 0x20)
            for { let i := 0 } lt(i, transferDetailsLength) { i := add(i, 0x20) } {
                mstore(add(offset, i), mload(add(requestedTransferLocation, i)))
            }

            success :=
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // Counterintuitively, this call must be positioned second to the or() call in the
                    // surrounding and() call or else returndatasize() will be zero during the computation.
                    call(gas(), mload(signedTransferDetails), 0, freeMemoryPointer, add(68, transferDetailsLength), 0, 32)
                )
        }

        if (!success) revert TransferFailed();
    }
}
