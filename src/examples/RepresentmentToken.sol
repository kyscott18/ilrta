// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILRTA} from "../ILRTA.sol";

/// @notice Token that stores only the hash of all data rather than the data itself
/// @dev See https://github.com/AstariaXYZ/starport-whitepaper
abstract contract ILRTARepresentmentToken is ILRTA {
    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                 ERRORS
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    error InvalidDataHash();

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                               DATA TYPES
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    struct ILRTAData {
        bytes32 hash;
    }

    struct ILRTATransferDetails {
        uint8[8][8][3] fromRBG;
        uint8[8][8][3] toRBG;
        uint8[8][8][3] transferRBG;
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

    function dataOf_XXXXXX(address owner) external view returns (ILRTAData memory) {
        return _dataOf[owner];
    }

    function allowanceOf_XXXXXX(address owner, address spender) external view returns (ILRTAApprovalDetails memory) {
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
        uint8[8][8][3] memory fromRBG = transferDetails.fromRBG;
        uint8[8][8][3] memory toRBG = transferDetails.toRBG;

        if (_dataOf[from].hash != keccak256(abi.encode(fromRBG))) revert InvalidDataHash();
        if (_dataOf[to].hash != keccak256(abi.encode(toRBG))) revert InvalidDataHash();

        for (uint256 i = 0; i < 8; i++) {
            for (uint256 j = 0; j < 8; j++) {
                for (uint256 l = 0; l < 3; l++) {
                    fromRBG[i][j][l] -= transferDetails.transferRBG[i][j][l];
                    toRBG[i][j][l] += transferDetails.transferRBG[i][j][l];
                }
            }
        }

        _dataOf[from].hash = keccak256(abi.encode(fromRBG));
        _dataOf[to].hash = keccak256(abi.encode(toRBG));

        emit Transfer(from, to, abi.encode(transferDetails));

        return true;
    }
}
