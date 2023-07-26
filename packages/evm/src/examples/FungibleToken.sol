// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILRTA} from "../ILRTA.sol";
import {SignatureVerification} from "../SignatureVerification.sol";

/// @notice Implement a fungible token with ilrta
/// @author Kyle Scott
abstract contract ILRTAFungibleToken is ILRTA {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                            METADATA STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    uint8 public immutable decimals;

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                               DATA TYPES
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    struct ILRTAData {
        uint256 balance;
    }

    struct ILRTATransferDetails {
        uint256 amount;
    }

    struct SignatureTransfer {
        uint256 nonce;
        uint256 deadline;
        ILRTATransferDetails transferDetails;
    }

    struct RequestedTransfer {
        address to;
        ILRTATransferDetails transferDetails;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    mapping(address owner => ILRTAData data) private _dataOf;

    uint256 public totalSupply;

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              CONSTRUCTOR
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    constructor(
        address _superSignature,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        ILRTA(_superSignature, _name, _symbol, "TransferDetails(uint256 amount)")
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function balanceOf(address owner) external view returns (uint256 balance) {
        return _dataOf[owner].balance;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              ILRTA LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function dataID(bytes calldata) external pure returns (bytes32) {
        return bytes32(0);
    }

    /// @dev because this standard is completely fungible, there is no need for an id
    function dataOf(address owner, bytes32) external view returns (ILRTAData memory) {
        return _dataOf[owner];
    }

    function transfer(address to, ILRTATransferDetails calldata transferDetails) external returns (bool) {
        return _transfer(msg.sender, to, transferDetails);
    }

    function transferBySignature(
        address from,
        SignatureTransfer calldata signatureTransfer,
        RequestedTransfer calldata requestedTransfer,
        bytes calldata signature
    )
        external
        returns (bool)
    {
        if (requestedTransfer.transferDetails.amount > signatureTransfer.transferDetails.amount) {
            revert InvalidRequest(abi.encode(signatureTransfer.transferDetails));
        }

        _verifySignature(from, signatureTransfer, signature);

        return _transfer(from, requestedTransfer.to, requestedTransfer.transferDetails);
    }

    function transferBySuperSignature(
        address from,
        ILRTATransferDetails calldata transferDetails,
        RequestedTransfer calldata requestedTransfer,
        bytes32[] calldata dataHash
    )
        external
        returns (bool)
    {
        if (requestedTransfer.transferDetails.amount > transferDetails.amount) {
            revert InvalidRequest(abi.encode(transferDetails));
        }

        _verifySuperSignature(from, transferDetails, dataHash);

        return _transfer(from, requestedTransfer.to, requestedTransfer.transferDetails);
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                             INTERNAL LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function _verifySignature(
        address from,
        SignatureTransfer calldata signatureTransfer,
        bytes calldata signature
    )
        private
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

    function _verifySuperSignature(
        address from,
        ILRTATransferDetails calldata transferDetails,
        bytes32[] calldata dataHash
    )
        private
    {
        bytes32 signatureHash = hashTypedData(
            keccak256(
                abi.encode(
                    SUPER_SIGNATURE_TRANSFER_TYPEHASH,
                    keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, transferDetails)),
                    msg.sender
                )
            )
        );

        if (dataHash[0] != signatureHash) revert DataHashMismatch();

        superSignature.verifyData(from, dataHash);
    }

    function _transfer(address from, address to, ILRTATransferDetails memory transferDetails) internal returns (bool) {
        _dataOf[from].balance -= transferDetails.amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value.
        unchecked {
            _dataOf[to].balance += transferDetails.amount;
        }

        emit Transfer(from, to, abi.encode(transferDetails));

        return true;
    }

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value.
        unchecked {
            _dataOf[to].balance += amount;
        }

        emit Transfer(address(0), to, abi.encode(ILRTATransferDetails({amount: amount})));
    }

    function _burn(address from, uint256 amount) internal virtual {
        _dataOf[from].balance -= amount;

        // Cannot underflow because a user's balance will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), abi.encode(ILRTATransferDetails({amount: amount})));
    }
}
