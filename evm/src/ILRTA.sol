// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "./EIP712.sol";
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
                            METADATA STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    string public name;

    string public symbol;

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                           SIGNATURE STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    SuperSignature internal immutable superSignature;

    string private constant TRANSFER_ENCODE_TYPE =
        "Transfer(TransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)";

    string private constant SUPER_SIGNATURE_TRANSFER_ENCODE_TYPE =
        "Transfer(TransferDetails transferDetails,address spender)";

    bytes32 internal immutable TRANSFER_TYPEHASH;

    bytes32 internal immutable SUPER_SIGNATURE_TRANSFER_TYPEHASH;

    bytes32 internal immutable TRANSFER_DETAILS_TYPEHASH;

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
}
