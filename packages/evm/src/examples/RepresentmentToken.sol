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

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                                STORAGE
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    mapping(address owner => ILRTAData data) private _dataOf;

    /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
                              ILRTA LOGIC
    <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

    function dataOf(address owner, bytes32) external view returns (ILRTAData memory) {
        return _dataOf[owner];
    }

    function transfer_XXXXXX(address to, ILRTATransferDetails calldata transferDetails) external returns (bool) {
        Data memory fromData = transferDetails.fromData;
        Data memory toData = transferDetails.toData;

        if (_dataOf[msg.sender].hash != keccak256(abi.encode(fromData))) revert InvalidDataHash();
        if (_dataOf[to].hash != keccak256(abi.encode(toData))) revert InvalidDataHash();

        for (uint256 i; i < 8; i++) {
            for (uint256 j; j < 8; j++) {
                fromData.rgb[i][j] -= transferDetails.transferData.rgb[i][j];
                toData.rgb[i][j] += transferDetails.transferData.rgb[i][j];
            }
        }

        _dataOf[msg.sender].hash = keccak256(abi.encode(fromData));
        _dataOf[to].hash = keccak256(abi.encode(toData));

        emit Transfer(msg.sender, to, abi.encode(transferDetails));

        return true;
    }
}
