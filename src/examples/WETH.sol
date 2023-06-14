// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "./ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

/// @notice Wrapped Ether implementation with ilrta
/// @author Kyle Scott
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 EVENTS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    receive() external payable virtual {
        deposit();
    }
}
