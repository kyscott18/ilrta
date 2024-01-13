// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILRTA} from "src/ILRTA.sol";

/// @notice Token that stores only the hash of all data rather than the data itself
/// @author Kyle Scott
/// @dev See https://github.com/AstariaXYZ/starport-whitepaper
abstract contract ILRTARepresentmentToken is ILRTA {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 ERRORS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    error InvalidDataHash();

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                               DATA TYPES
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    struct Data {
        uint24[8][8] rgb;
    }

    struct ILRTAData {
        bytes32 hash;
    }

    struct ILRTATransferDetails {
        Data fromData;
        Data toData;
        Data transferData;
    }

    struct ILRTAApprovalDetails {
        bool approved;
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    mapping(address owner => ILRTAData data) private _dataOf;

    mapping(address owner => mapping(address spender => ILRTAApprovalDetails approvalDetails)) private _allowanceOf;

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              ILRTA LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function dataOf(address owner, bytes32) external view returns (ILRTAData memory) {
        return _dataOf[owner];
    }

    function allowanceOf(address owner, address spender, bytes32) external view returns (ILRTAApprovalDetails memory) {
        return _allowanceOf[owner][spender];
    }

    function validateRequest_XXXXXX(
        ILRTATransferDetails calldata signedTransferDetails,
        ILRTATransferDetails calldata requestedTransferDetails
    )
        external
        pure
        returns (bool)
    {
        return keccak256(abi.encode(signedTransferDetails)) == keccak256(abi.encode(requestedTransferDetails));
    }

    function transfer_XXXXXX(address to, ILRTATransferDetails calldata transferDetails) external returns (bool) {
        return _transfer(msg.sender, to, transferDetails);
    }

    function approve_XXXXXX(address spender, ILRTAApprovalDetails calldata approvalDetails) external returns (bool) {
        _allowanceOf[msg.sender][spender] = approvalDetails;

        emit Approval(msg.sender, spender, abi.encode(approvalDetails));

        return true;
    }

    function transferFrom_XXXXXX(
        address from,
        address to,
        ILRTATransferDetails calldata transferDetails
    )
        external
        returns (bool)
    {
        ILRTAApprovalDetails memory allowed = _allowanceOf[from][msg.sender];

        if (!allowed.approved) revert();

        return _transfer(from, to, transferDetails);
    }

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                             INTERNAL LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function _transfer(address from, address to, ILRTATransferDetails memory transferDetails) internal returns (bool) {
        Data memory fromData = transferDetails.fromData;
        Data memory toData = transferDetails.toData;

        if (_dataOf[from].hash != keccak256(abi.encode(fromData))) revert InvalidDataHash();
        if (_dataOf[to].hash != keccak256(abi.encode(toData))) revert InvalidDataHash();

        for (uint256 i; i < 8; i++) {
            for (uint256 j; j < 8; j++) {
                fromData.rgb[i][j] -= transferDetails.transferData.rgb[i][j];
                toData.rgb[i][j] += transferDetails.transferData.rgb[i][j];
            }
        }

        _dataOf[from].hash = keccak256(abi.encode(fromData));
        _dataOf[to].hash = keccak256(abi.encode(toData));

        emit Transfer(from, to, abi.encode(transferDetails));

        return true;
    }
}
