// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SuperSignature} from "../SuperSignature.sol";
import {ILRTAFungibleToken} from "./FungibleToken.sol";

contract TransferBatch {
    bytes32 private constant SUPER_SIGNATURE_TRANSFER_TYPEHASH =
        keccak256(bytes("Transfer(TransferDetails transferDetails,address spender)TransferDetails(uint256 amount)"));

    bytes32 private constant TRANSFER_DETAILS_TYPEHASH = keccak256(bytes("TransferDetails(uint256 amount)"));

    SuperSignature private immutable superSignature;

    constructor(address _superSignature) {
        superSignature = SuperSignature(_superSignature);
    }

    function transferBatch(
        address from,
        address[] calldata tokens,
        ILRTAFungibleToken.ILRTATransferDetails[] calldata transferDetails,
        ILRTAFungibleToken.RequestedTransfer[] calldata requestedTransfers,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    )
        external
    {
        bytes32[] memory dataHash = new bytes32[](transferDetails.length);

        // calculate roots
        unchecked {
            for (uint256 i = 0; i < transferDetails.length; i++) {
                dataHash[i] = keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        ILRTAFungibleToken(tokens[i]).DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                SUPER_SIGNATURE_TRANSFER_TYPEHASH,
                                keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, transferDetails[i])),
                                address(this)
                            )
                        )
                    )
                );
            }
        }

        // verify root array
        superSignature.verifyAndStoreRoot(from, SuperSignature.Verify(dataHash, nonce, deadline), signature);

        // transfer tokens
        unchecked {
            for (uint256 i = 0; i < transferDetails.length; i++) {
                if (i != 0) dataHash = removeFirstElement(dataHash);
                ILRTAFungibleToken(tokens[i]).transferBySuperSignature(
                    from, transferDetails[i], requestedTransfers[i], dataHash
                );
            }
        }
    }

    function removeFirstElement(bytes32[] memory dataHash) private pure returns (bytes32[] memory) {
        unchecked {
            uint256 newLength = dataHash.length - 1;
            bytes32[] memory newArr = new bytes32[](newLength);
            for (uint256 i = 0; i < newLength; i++) {
                newArr[i] = dataHash[i + 1];
            }
            return newArr;
        }
    }
}
