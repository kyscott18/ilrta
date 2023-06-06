// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EIP712} from "src/EIP712.sol";
import {ILRTA} from "src/ILRTA.sol";

contract MockILRTA is ILRTA {
    constructor() ILRTA("TransferDetails()") EIP712(keccak256(bytes("Test"))) {}

    function dataOf(address) external pure override returns (bytes memory) {
        return bytes("");
    }

    function transfer(address to, bytes calldata transferDetailsBytes) external virtual override returns (bool) {
        emit Transfer(msg.sender, to, transferDetailsBytes);

        return true;
    }

    function transferBySignature(
        address from,
        SignatureTransfer calldata signatureTransfer,
        RequestedTransfer calldata requestedTransfer,
        bytes calldata signature
    )
        external
        virtual
        override
        returns (bool)
    {
        verifySignature(from, signatureTransfer, signature);

        emit Transfer(from, requestedTransfer.to, requestedTransfer.transferDetails);

        return true;
    }
}
