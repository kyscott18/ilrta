// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { EIP712 } from "../EIP712.sol";
import { ILRTA } from "../ILRTA.sol";
import { SignatureVerification } from "permit2/libraries/SignatureVerification.sol";

abstract contract ILRTAFungibleToken is ILRTA {
    /*((((((((((((((((((((((METADATA STORAGE))))))))))))))))))))))*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*(((((((((((((((((((((((((((STORAGE))))))))))))))))))))))))))*/

    mapping(address owner => ILRTAData data) public _dataOf;

    uint256 public totalSupply;

    /*(((((((((((((((((((((((((CONSTRUCTOR))))))))))))))))))))))))*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        ILRTA("TransferDetails(uint256 amount)")
        EIP712(keccak256(bytes(_name)))
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /*((((((((((((((((((((((((((((LOGIC)))))))))))))))))))))))))))*/

    function balanceOf(address owner) external view returns (uint256 balance) {
        return _dataOf[owner].balance;
    }

    /*(((((((((((((((((((((((((ILRTA LOGIC))))))))))))))))))))))))*/

    struct ILRTAData {
        uint256 balance;
    }

    struct ILRTATransferDetails {
        uint256 amount;
    }

    function dataOf(address owner) external view override returns (bytes memory) {
        return abi.encode(_dataOf[owner]);
    }

    function transfer(address to, bytes calldata transferDetailsBytes) external override returns (bool) {
        ILRTATransferDetails memory transferDetails = abi.decode(transferDetailsBytes, (ILRTATransferDetails));
        return _transfer(msg.sender, to, transferDetails);
    }

    /// @custom:team How do we use signature transfer nonce
    /// @custom:team Is there a way to simplifiy the signature verification step and move it to ILRTA.sol
    function transferBySignature(
        address from,
        SignatureTransfer calldata signatureTransfer,
        RequestedTransfer calldata requestedTransfer,
        bytes calldata signature
    )
        external
        override
        returns (bool)
    {
        if (
            abi.decode(requestedTransfer.transferDetails, (ILRTATransferDetails)).amount
                > abi.decode(signatureTransfer.transferDetails, (ILRTATransferDetails)).amount
        ) {
            revert InvalidRequest(abi.encode(signatureTransfer.transferDetails));
        }

        verifySignature(from, signatureTransfer, signature);

        return
        /* solhint-disable-next-line max-line-length */
        _transfer(from, requestedTransfer.to, abi.decode(requestedTransfer.transferDetails, (ILRTATransferDetails)));
    }

    /*(((((((((((((((((((((((INTERNAL LOGIC)))))))))))))))))))))))*/

    function _transfer(address from, address to, ILRTATransferDetails memory transferDetails) internal returns (bool) {
        _dataOf[from].balance -= transferDetails.amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _dataOf[to].balance += transferDetails.amount;
        }

        emit Transfer(from, to, abi.encode(transferDetails));

        return true;
    }

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _dataOf[to].balance += amount;
        }

        emit Transfer(address(0), to, abi.encode(ILRTATransferDetails({ amount: amount })));
    }

    function _burn(address from, uint256 amount) internal virtual {
        _dataOf[from].balance -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), abi.encode(ILRTATransferDetails({ amount: amount })));
    }
}
