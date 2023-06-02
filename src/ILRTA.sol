// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { EIP712 } from "./EIP712.sol";

abstract contract ILRTA is EIP712 {
    /*(((((((((((((((((((((((((((EVENTS)))))))))))))))))))))))))))*/

    event Transfer(address indexed from, address indexed to, bytes data);

    /*(((((((((((((((((((((((((((ERRORS)))))))))))))))))))))))))))*/

    error SignatureExpired(uint256 signatureDeadline);

    error InvalidRequest(bytes transferDetailsBytes);

    /*(((((((((((((((((((((((((((STORAGE))))))))))))))))))))))))))*/

    mapping(address => uint256) public nonces;

    /// @custom:team problem is that when data takes up more than one slot but we don't want to read all of it, it may
    /// do an extra SLOAD
    mapping(address owner => bytes data) internal dataOf;

    /*((((((((((((((((((((((((((((LOGIC)))))))))))))))))))))))))))*/

    function transfer(address to, bytes calldata transferDetails) external virtual returns (bool);

    function transferBySignature(
        address from,
        bytes calldata signatureTransferBytes,
        bytes calldata requestedTransferBytes,
        bytes calldata signature
    )
        external
        virtual
        returns (bool);
}
