// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AllowanceTransfer} from "./AllowanceTransfer.sol";
import {SignatureTransfer} from "./SignatureTransfer.sol";
import {EIP712} from "../EIP712.sol";

contract Permit3 is AllowanceTransfer, SignatureTransfer {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              CONSTRUCTOR
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    constructor() EIP712(keccak256(bytes("Permit3"))) {}
}
