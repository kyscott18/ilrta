// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILRTA} from "../ILRTA.sol";

/// @notice Template for what an instance of ILRTA should implement
abstract contract ILRTATemplate is ILRTA {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                               DATA TYPES
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    /// @notice data is a filler to silence compiler errors, developer should replace this
    /// @dev this may be optional, if all tokens are completely fungible
    struct ILRTADataID {
        bytes32 data;
    }

    /// @notice data is a filler to silence compiler errors, developer should replace this
    struct ILRTAData {
        bytes32 data;
    }

    /// @notice data is a filler to silence compiler errors, developer should replace this
    struct ILRTATransferDetails {
        bytes32 data;
    }

    /// @notice data is a filler to silence compiler errors, developer should replace this
    struct ILRTAApprovalDetails {
        bytes32 data;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              CONSTRUCTOR
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    constructor(string memory _name, string memory _symbol) ILRTA(_name, _symbol) {}

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              ILRTA LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    /// @notice return the data of the owner, with the specific id
    function dataOf(address owner, bytes32 id) external view virtual returns (ILRTAData memory);

    /// @notice return the spenders allowance of the data owned by owner, with the specific id
    function allowanceOf(
        address owner,
        address spender,
        bytes32 id
    )
        external
        view
        virtual
        returns (ILRTAApprovalDetails memory);

    /// @notice check that the request is valid
    /// @dev Replace XXXXXX such that the function selector is 0x95a41eb5
    function validateRequest_XXXXXX(
        ILRTATransferDetails memory signedTransferDetails,
        ILRTATransferDetails memory requestedTransferDetails
    )
        external
        pure
        virtual
        returns (bool);

    /// @notice transfer tokens to the specified address
    /// @dev Replace XXXXXX such that the function selector is 0x8a4068dd
    function transfer_XXXXXX(
        address to,
        ILRTATransferDetails calldata transferDetails
    )
        external
        virtual
        returns (bool);

    /// @notice approve the spender to spend the specified tokens
    /// @dev type(uint256).max is a special value that is never decreased, leading to gas savings
    /// @dev Replace XXXXXX such that the function selector is 0x12424e3f
    function approve_XXXXXX(
        address spender,
        ILRTAApprovalDetails calldata approvalDetails
    )
        external
        virtual
        returns (bool);

    /// @notice transfer tokens if the caller has enough allowance
    /// @dev Replace XXXXXX such that the function selector is 0x811c34d3
    function transferFrom_XXXXXX(
        address from,
        address to,
        ILRTATransferDetails calldata transferDetails
    )
        external
        virtual
        returns (bool);
}
