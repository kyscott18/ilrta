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
        return abi.decode(dataOf[owner], (ILRTAData)).balance;
    }

    /*(((((((((((((((((((((((((ILRTA LOGIC))))))))))))))))))))))))*/

    struct ILRTAData {
        uint256 balance;
    }

    struct ILRTATransferDetails {
        uint256 amount;
    }

    function transfer(address to, bytes calldata transferDetailsBytes) external override returns (bool) {
        ILRTATransferDetails memory transferDetails = abi.decode(transferDetailsBytes, (ILRTATransferDetails));
        return _transfer(msg.sender, to, transferDetails);
    }

    /// @custom:team How do we use signature transfer nonce
    /// @custom:team Is there a way to simplifiy the signature verification step and move it to ILRTA.sol
    function transferBySignature(
        address from,
        bytes calldata signatureTransferBytes,
        bytes calldata requestedTransferBytes,
        bytes calldata signature
    )
        external
        override
        returns (bool)
    {
        SignatureTransfer memory signatureTransfer = abi.decode(signatureTransferBytes, (SignatureTransfer));
        RequestedTransfer memory requestedTransfer = abi.decode(requestedTransferBytes, (RequestedTransfer));

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
        ILRTAData memory dataFrom = abi.decode(dataOf[from], (ILRTAData));
        dataFrom.balance -= transferDetails.amount;
        dataOf[from] = abi.encode(dataFrom);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        ILRTAData memory dataTo = abi.decode(dataOf[to], (ILRTAData));
        unchecked {
            dataTo.balance += transferDetails.amount;
        }
        dataOf[to] = abi.encode(dataTo);

        emit Transfer(from, to, abi.encode(transferDetails));

        return true;
    }

    function _mint(address to, ILRTATransferDetails calldata details) internal virtual {
        totalSupply += details.amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        ILRTAData memory dataTo = abi.decode(dataOf[to], (ILRTAData));
        unchecked {
            dataTo.balance += details.amount;
        }
        dataOf[to] = abi.encode(dataTo);

        emit Transfer(address(0), to, abi.encode(details));
    }

    function _burn(address from, ILRTATransferDetails calldata details) internal virtual {
        ILRTAData memory dataFrom = abi.decode(dataOf[from], (ILRTAData));
        dataFrom.balance -= details.amount;
        dataOf[from] = abi.encode(dataFrom);

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= details.amount;
        }

        emit Transfer(from, address(0), abi.encode(details));
    }
}
