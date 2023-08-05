// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockFungibleToken} from "./mocks/MockFungibleToken.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";

import {console2} from "forge-std/console2.sol";

contract C {
    struct S {
        address a;
        address b;
    }

    function t1(S calldata s) external pure {
        console2.log(s.a);
        return;
    }

    function t2(address a) external pure {
        console2.log(a);
        return;
    }
}

contract AssemblyTest is Test {
    address private c;
    MockFungibleToken private mockFT;

    function setUp() external {
        c = address(new C());
        mockFT = new MockFungibleToken();
    }

    function testAssembly() external {
        console2.log("%x", uint32(C.t1.selector));
        console2.log("%x", uint32(bytes4(keccak256("t1((address,address))"))));
        console2.log("%x", uint32(C.t2.selector));

        // bool success;
        // address to = address(0x69);
        // address i = c;

        // C(c).t1(C.S(to));
        address a = address(mockFT);

        console2.log("%x", uint32(ILRTAFungibleToken.transferFrom.selector));

        // assembly {
        //     let freeMemoryPointer := mload(0x40)
        //     // Write the abi-encoded calldata into memory, beginning with the function selector.
        //     mstore(freeMemoryPointer, 0x6c22be7500000000000000000000000000000000000000000000000000000000)
        //     // Append and mask the "to" argument.
        //     mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
        //     success := call(gas(), i, 0, freeMemoryPointer, 36, 0, 0)
        // }

        // assertTrue(success);
    }
}
