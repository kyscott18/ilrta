// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILRTA} from "../ILRTA.sol";

/// @notice Implement both ERC20 and ILRTA
/// @author Kyle Scott
abstract contract ILRTAERC20 is ILRTA {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 EVENTS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

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

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    mapping(address owner => ILRTAData data) private _dataOf;

    mapping(address owner => mapping(address spender => ILRTATransferDetails transferDetails)) private _allowanceOf;

    uint256 public totalSupply;

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              CONSTRUCTOR
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ILRTA(_name, _symbol) {
        decimals = _decimals;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              ERC20 LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function balanceOf(address owner) external view returns (uint256 balance) {
        return _dataOf[owner].balance;
    }

    function allowance(address owner, address spender) external view returns (uint256 amount) {
        return _allowanceOf[owner][spender].amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowanceOf[msg.sender][spender] = ILRTATransferDetails(amount);

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, ILRTATransferDetails({amount: amount}));
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = _allowanceOf[from][msg.sender].amount;

        if (allowed != type(uint256).max) {
            _allowanceOf[from][msg.sender] = ILRTATransferDetails(allowed - amount);
        }

        return _transfer(from, to, ILRTATransferDetails({amount: amount}));
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              ILRTA LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function dataOf(address owner, bytes32) external view override returns (bytes memory) {
        return abi.encode(_dataOf[owner]);
    }

    function allowanceOf(address owner, address spender, bytes32) external view override returns (bytes memory) {
        return abi.encode(_allowanceOf[owner][spender]);
    }

    function validateRequest(
        bytes memory signedTransferDetailsBytes,
        bytes memory requestedTransferDetailsBytes
    )
        external
        pure
        override
    {
        ILRTATransferDetails memory signedTransferDetails =
            abi.decode(signedTransferDetailsBytes, (ILRTATransferDetails));

        ILRTATransferDetails memory requestedTransferDetails =
            abi.decode(requestedTransferDetailsBytes, (ILRTATransferDetails));

        if (requestedTransferDetails.amount > signedTransferDetails.amount) {
            revert InvalidRequest(requestedTransferDetailsBytes);
        }
    }

    function transfer(address to, bytes calldata transferDetailsBytes) external override returns (bool) {
        return _transfer(msg.sender, to, abi.decode(transferDetailsBytes, (ILRTATransferDetails)));
    }

    function approve(address spender, bytes calldata transferDetailsBytes) external override returns (bool) {
        _allowanceOf[msg.sender][spender] = abi.decode(transferDetailsBytes, (ILRTATransferDetails));

        emit Approval(msg.sender, spender, transferDetailsBytes);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        bytes calldata transferDetailsBytes
    )
        external
        override
        returns (bool)
    {
        ILRTATransferDetails memory allowed = _allowanceOf[from][msg.sender];
        ILRTATransferDetails memory transferDetails = abi.decode(transferDetailsBytes, (ILRTATransferDetails));

        if (allowed.amount != type(uint256).max) {
            _allowanceOf[from][msg.sender] = ILRTATransferDetails(allowed.amount - transferDetails.amount);
        }

        return _transfer(from, to, transferDetails);
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                             INTERNAL LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function _transfer(address from, address to, ILRTATransferDetails memory transferDetails) internal returns (bool) {
        _dataOf[from].balance -= transferDetails.amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value.
        unchecked {
            _dataOf[to].balance += transferDetails.amount;
        }

        emit Transfer(from, to, transferDetails.amount);
        emit Transfer(from, to, abi.encode(transferDetails));

        return true;
    }

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value.
        unchecked {
            _dataOf[to].balance += amount;
        }

        emit Transfer(address(0), to, amount);
        emit Transfer(address(0), to, abi.encode(ILRTATransferDetails({amount: amount})));
    }

    function _burn(address from, uint256 amount) internal virtual {
        _dataOf[from].balance -= amount;

        // Cannot underflow because a user's balance will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
        emit Transfer(from, address(0), abi.encode(ILRTATransferDetails({amount: amount})));
    }
}
