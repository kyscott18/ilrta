// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { EIP712 } from "./EIP712.sol";
import { SignatureVerification } from "permit2/libraries/SignatureVerification.sol";

abstract contract ILRTAFungibleToken is EIP712 {
    /*(((((((((((((((((((((((((((EVENTS)))))))))))))))))))))))))))*/

    event Transfer(address from, address to, ILRTATransferDetails transferDetails);

    /*(((((((((((((((((((((((((((ERRORS)))))))))))))))))))))))))))*/

    error SignatureExpired(uint256 signatureDeadline);

    error InvalidAmount(uint256 maxAmount);

    /*((((((((((((((((((((((METADATA STORAGE))))))))))))))))))))))*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*(((((((((((((((((((((((((((STORAGE))))))))))))))))))))))))))*/

    uint256 public totalSupply;

    mapping(address owner => ILRTAData data) public dataOf;

    /*((((((((((((((((((((((SIGNATURE STORAGE)))))))))))))))))))))*/

    mapping(address => uint256) public nonces;

    /*(((((((((((((((((((((((((CONSTRUCTOR))))))))))))))))))))))))*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) EIP712(keccak256(bytes(_name))) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return dataOf[owner].balance;
    }

    /*(((((((((((((((((((((((((ILRTA LOGIC))))))))))))))))))))))))*/

    struct ILRTAData {
        uint256 balance;
    }

    struct ILRTATransferDetails {
        uint256 amount;
    }

    struct ILRTASignatureTransfer {
        ILRTATransferDetails transferDetails;
        uint256 nonce;
        uint256 deadline;
    }

    struct RequestedTransfer {
        address to;
        ILRTATransferDetails transferDetails;
    }

    bytes32 public constant ILRTA_DETAILS_TYPEHASH = keccak256("ILRTATransferDetails(uint256 amount)");

    bytes32 public constant ILRTA_TRANSFER_TYPEHASH = keccak256(
        /* solhint-disable-next-line max-line-length */
        "ILRTATransfer(ILRTATransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)ILRTATransferDetails(uint256 amount)"
    );

    function transfer(address to, ILRTATransferDetails calldata transferDetails) external returns (bool) {
        return _transfer(msg.sender, to, transferDetails);
    }

    /// @custom:team How do we use signature transfer nonce
    function transferBySignature(
        address from,
        ILRTASignatureTransfer calldata signatureTransfer,
        RequestedTransfer calldata requestedTransfer,
        bytes calldata signature
    )
        external
        returns (bool)
    {
        if (block.timestamp > signatureTransfer.deadline) revert SignatureExpired(signatureTransfer.deadline);
        if (requestedTransfer.transferDetails.amount > signatureTransfer.transferDetails.amount) {
            revert InvalidAmount(signatureTransfer.transferDetails.amount);
        }

        bytes32 signatureHash;
        unchecked {
            signatureHash = hashTypedData(
                keccak256(
                    abi.encode(
                        ILRTA_TRANSFER_TYPEHASH,
                        keccak256(abi.encode(ILRTA_DETAILS_TYPEHASH, signatureTransfer.transferDetails)),
                        msg.sender,
                        nonces[from]++,
                        signatureTransfer.deadline
                    )
                )
            );
        }

        SignatureVerification.verify(signature, signatureHash, from);

        return _transfer(from, requestedTransfer.to, requestedTransfer.transferDetails);
    }

    function _transfer(
        address from,
        address to,
        ILRTATransferDetails calldata transferDetails
    )
        internal
        returns (bool)
    {
        dataOf[from].balance -= transferDetails.amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            dataOf[to].balance += transferDetails.amount;
        }

        emit Transfer(from, to, transferDetails);

        return true;
    }

    /*(((((((((((((((((((((((INTERNAL LOGIC)))))))))))))))))))))))*/

    function _mint(address to, ILRTATransferDetails calldata details) internal virtual {
        totalSupply += details.amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            dataOf[to].balance += details.amount;
        }

        emit Transfer(address(0), to, details);
    }

    function _burn(address from, ILRTATransferDetails calldata details) internal virtual {
        dataOf[from].balance -= details.amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= details.amount;
        }

        emit Transfer(from, address(0), details);
    }
}
