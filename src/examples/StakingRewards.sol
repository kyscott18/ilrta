// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { SignatureVerification } from "permit2/libraries/SignatureVerification.sol";
import { EIP712 } from "./EIP712.sol";

abstract contract StakingRewards is EIP712 {
    /*(((((((((((((((((((((((((((EVENTS)))))))))))))))))))))))))))*/

    event Transfer(address from, address to, ILRTATransferDetails transferDetails);

    /*(((((((((((((((((((((((((((ERRORS)))))))))))))))))))))))))))*/

    error SignatureExpired(uint256 signatureDeadline);

    error InvalidAmount(uint256 maxAmount);

    /*(((((((((((((((((((((((((((STORAGE))))))))))))))))))))))))))*/

    address public immutable stakingToken;
    address public immutable rewardToken;

    /// @dev Because this is an example contract, used a fixed amount
    /// @dev units are (rewardToken / stakingToken) * 10**18
    uint256 public immutable rewardRate = 1e18;

    uint256 public totalSupply;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdate;

    mapping(address owner => ILRTAData data) public dataOf;

    /*((((((((((((((((((((((SIGNATURE STORAGE)))))))))))))))))))))*/

    mapping(address => uint256) public nonces;

    /*(((((((((((((((((((((((((CONSTRUCTOR))))))))))))))))))))))))*/

    constructor(
        address _stakingToken,
        address _rewardToken
    )
        EIP712(keccak256(abi.encodePacked(_stakingToken, _rewardToken)))
    {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }

    /*(((((((((((((((((((((((STAKING STORAGE))))))))))))))))))))))*/

    function getRewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (block.timestamp - lastUpdate) * ((rewardRate * 1e18) / totalSupply);
    }

    function getTokensOwed(address owner) public view returns (uint256) {
        ILRTAData memory data = dataOf[owner];

        return data.balance * (getRewardPerToken() - data.rewardPerTokenPaid) / 1e18 + data.tokensOwed;
    }

    /*(((((((((((((((((((((((((ILRTA LOGIC))))))))))))))))))))))))*/

    struct ILRTAData {
        uint256 balance;
        uint256 rewardPerTokenPaid;
        uint256 tokensOwed;
    }

    struct ILRTATransferDetails {
        uint256 balance;
        uint256 tokensOwed;
    }

    struct ILRTASignatureTransfer {
        ILRTATransferDetails transferDetails;
        uint256 nonce;
        uint256 deadline;
    }

    struct RequestedTransfer {
        address to;
        ILRTATransferDetails transferDetails;
    }

    bytes32 public constant ILRTA_DETAILS_TYPEHASH =
        keccak256("ILRTATransferDetails(uint256 balance, uint256 tokensOwed)");

    bytes32 public constant ILRTA_TRANSFER_TYPEHASH = keccak256(
        /* solhint-disable-next-line max-line-length */
        "ILRTATransfer(ILRTATransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)ILRTATransferDetails(uint256 balance, uint256 tokensOwed)"
    );

    function transfer(address to, ILRTATransferDetails calldata transferDetails) external returns (bool) {
        return _transfer(msg.sender, to, transferDetails);
    }

    function transferBySignature(
        address from,
        ILRTASignatureTransfer calldata signatureTransfer,
        RequestedTransfer calldata requestedTransfer,
        bytes calldata signature
    )
        external
        returns (bool)
    {
        if (block.timestamp > signatureTransfer.deadline) revert SignatureExpired(signatureTransfer.deadline);
        if (requestedTransfer.transferDetails.balance > signatureTransfer.transferDetails.balance) {
            revert InvalidAmount(signatureTransfer.transferDetails.balance);
        }
        if (requestedTransfer.transferDetails.tokensOwed > signatureTransfer.transferDetails.tokensOwed) {
            revert InvalidAmount(signatureTransfer.transferDetails.tokensOwed);
        }

        bytes32 signatureHash;
        unchecked {
            signatureHash = hashTypedData(
                keccak256(
                    abi.encode(
                        ILRTA_TRANSFER_TYPEHASH,
                        keccak256(abi.encode(ILRTA_DETAILS_TYPEHASH, signatureTransfer.transferDetails)),
                        msg.sender,
                        nonces[from]++,
                        signatureTransfer.deadline
                    )
                )
            );
        }

        SignatureVerification.verify(signature, signatureHash, from);

        return _transfer(from, requestedTransfer.to, requestedTransfer.transferDetails);
    }

    function _transfer(
        address from,
        address to,
        ILRTATransferDetails calldata transferDetails
    )
        internal
        returns (bool)
    {
        uint256 rewardPerToken = getRewardPerToken();

        ILRTAData memory fromData = dataOf[from];
        fromData.tokensOwed += fromData.balance * (rewardPerToken - fromData.rewardPerTokenPaid) / 1e18;

        ILRTAData memory toData = dataOf[from];
        toData.tokensOwed += toData.balance * (rewardPerToken - toData.rewardPerTokenPaid) / 1e18;

        fromData.balance -= transferDetails.balance;
        fromData.rewardPerTokenPaid = rewardPerToken;
        fromData.tokensOwed -= transferDetails.tokensOwed;
        dataOf[from] = fromData;

        // Cannot overflow because the sum of all user balances and tokens owed can't exceed the max uint256 value.
        unchecked {
            toData.tokensOwed += transferDetails.tokensOwed;
            toData.balance += transferDetails.balance;
        }

        toData.rewardPerTokenPaid = rewardPerToken;
        dataOf[to] = toData;

        emit Transfer(from, to, transferDetails);

        return true;
    }
}
