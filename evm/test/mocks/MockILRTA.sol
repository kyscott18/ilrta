// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILRTA} from "src/ILRTA.sol";

contract MockILRTA is ILRTA {
    constructor(address _superSignature) ILRTA(_superSignature, "Test", "TEST", "TransferDetails()") {}

    function dataID(bytes calldata) external pure override returns (bytes32) {
        return bytes32(0);
    }

    function dataOf(address, bytes32) external pure override returns (bytes memory) {
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

    function transferBySuperSignature(
        address from,
        bytes calldata transferDetails,
        RequestedTransfer calldata requestedTransfer,
        bytes32[] calldata dataHash
    )
        external
        override
        returns (bool)
    {
        verifySuperSignature(from, transferDetails, dataHash);

        emit Transfer(from, requestedTransfer.to, requestedTransfer.transferDetails);

        return true;
    }
}