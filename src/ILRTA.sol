// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "./EIP712.sol";
import {SignatureVerification} from "./SignatureVerification.sol";
import {SuperSignature} from "./SuperSignature.sol";
import {UnorderedNonce} from "./UnorderedNonce.sol";

/// @notice Custom and composable token standard with signature capabilities
/// @author Kyle Scott
abstract contract ILRTA is EIP712, UnorderedNonce {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 EVENTS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    event Transfer(address indexed from, address indexed to, bytes data);

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 ERRORS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    error SignatureExpired(uint256 signatureDeadline);

    error InvalidRequest(bytes transferDetailsBytes);

    error DataHashMismatch();

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                               DATA TYPES
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    struct SignatureTransfer {
        uint256 nonce;
        uint256 deadline;
        bytes transferDetails;
    }

    struct RequestedTransfer {
        address to;
        bytes transferDetails;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                            METADATA STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    string public name;

    string public symbol;

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                           SIGNATURE STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    SuperSignature private immutable superSignature;

    string private constant TRANSFER_ENCODE_TYPE =
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)";

    string private constant SUPER_SIGNATURE_TRANSFER_ENCODE_TYPE =
        "Transfer(TransferDetails transferDetails,address spender)";

    bytes32 private immutable TRANSFER_TYPEHASH;

    bytes32 private immutable SUPER_SIGNATURE_TRANSFER_TYPEHASH;

    bytes32 private immutable TRANSFER_DETAILS_TYPEHASH;

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              CONSTRUCTOR
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    constructor(
        address _superSignature,
        string memory _name,
        string memory _symbol,
        string memory transferDetailsEncodeType
    )
        EIP712(_name)
    {
        superSignature = SuperSignature(_superSignature);

        name = _name;
        symbol = _symbol;

        TRANSFER_TYPEHASH = keccak256(bytes(string.concat(TRANSFER_ENCODE_TYPE, transferDetailsEncodeType)));
        SUPER_SIGNATURE_TRANSFER_TYPEHASH =
            keccak256(bytes(string.concat(SUPER_SIGNATURE_TRANSFER_ENCODE_TYPE, transferDetailsEncodeType)));
        TRANSFER_DETAILS_TYPEHASH = keccak256(bytes(transferDetailsEncodeType));
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function dataOf(address owner, bytes32 id) external view virtual returns (bytes memory);

    function dataID(bytes calldata id) external pure virtual returns (bytes32);

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

    function transferBySuperSignature(
        address from,
        bytes calldata transferDetails,
        RequestedTransfer calldata requestedTransfer,
        bytes32[] calldata dataHash
    )
        external
        virtual
        returns (bool);

    function verifySignature(
        address from,
        SignatureTransfer calldata signatureTransfer,
        bytes calldata signature
    )
        internal
    {
        if (block.timestamp > signatureTransfer.deadline) revert SignatureExpired(signatureTransfer.deadline);

        useUnorderedNonce(from, signatureTransfer.nonce);

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

        SignatureVerification.verify(signature, signatureHash, from);
    }

    function verifySuperSignature(address from, bytes calldata transferDetails, bytes32[] calldata dataHash) internal {
        bytes32 signatureHash = keccak256(
            abi.encode(
                SUPER_SIGNATURE_TRANSFER_TYPEHASH,
                keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, transferDetails)),
                msg.sender
            )
        );

        if (dataHash[0] != signatureHash) revert DataHashMismatch();

        superSignature.verifyData(from, dataHash);
    }
}
