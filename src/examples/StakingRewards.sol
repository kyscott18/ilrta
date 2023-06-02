// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { EIP712 } from "../EIP712.sol";
import { ILRTA } from "../ILRTA.sol";
import { SignatureVerification } from "permit2/libraries/SignatureVerification.sol";

abstract contract StakingRewards is ILRTA {
    /*(((((((((((((((((((((((((((STORAGE))))))))))))))))))))))))))*/

    address public immutable stakingToken;
    address public immutable rewardToken;

    /// @dev Because this is an example contract, used a fixed amount
    /// @dev units are (rewardToken / stakingToken) * 10**18
    uint256 public immutable rewardRate = 1e18;

    uint256 public totalSupply;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdate;

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

    /*(((((((((((((((((((((((((((STORAGE))))))))))))))))))))))))))*/

    function getRewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (block.timestamp - lastUpdate) * ((rewardRate * 1e18) / totalSupply);
    }

    function getTokensOwed(address owner) public view returns (uint256) {
        ILRTAData memory data = abi.decode(dataOf[owner], (ILRTAData));

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

    bytes32 public constant ILRTA_DETAILS_TYPEHASH =
        keccak256("ILRTATransferDetails(uint256 balance, uint256 tokensOwed)");

    bytes32 public constant ILRTA_TRANSFER_TYPEHASH = keccak256(
        /* solhint-disable-next-line max-line-length */
        "ILRTATransfer(ILRTATransferDetails transferDetails,address spender,uint256 nonce,uint256 deadline)ILRTATransferDetails(uint256 balance, uint256 tokensOwed)"
    );

    function transfer(address to, bytes calldata transferDetailsBytes) external override returns (bool) {
        ILRTATransferDetails memory transferDetails = abi.decode(transferDetailsBytes, (ILRTATransferDetails));
        return _transfer(msg.sender, to, transferDetails);
    }

    function transferBySignature(
        address from,
        bytes calldata signatureTransferBytes,
        bytes calldata requestedTransferBytes,
        bytes calldata signature
    )
        external
        override
        returns (bool)
    {
        SignatureTransfer memory signatureTransfer = abi.decode(signatureTransferBytes, (SignatureTransfer));
        RequestedTransfer memory requestedTransfer = abi.decode(requestedTransferBytes, (RequestedTransfer));

        if (block.timestamp > signatureTransfer.deadline) revert SignatureExpired(signatureTransfer.deadline);
        if (
            abi.decode(requestedTransfer.transferDetails, (ILRTATransferDetails)).balance
                > abi.decode(signatureTransfer.transferDetails, (ILRTATransferDetails)).balance
                || abi.decode(requestedTransfer.transferDetails, (ILRTATransferDetails)).tokensOwed
                    > abi.decode(signatureTransfer.transferDetails, (ILRTATransferDetails)).tokensOwed
        ) {
            revert InvalidRequest(abi.encode(signatureTransfer.transferDetails));
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

        return
        /* solhint-disable-next-line max-line-length */
        _transfer(from, requestedTransfer.to, abi.decode(requestedTransfer.transferDetails, (ILRTATransferDetails)));
    }

    /*(((((((((((((((((((((((INTERNAL LOGIC)))))))))))))))))))))))*/

    function _transfer(address from, address to, ILRTATransferDetails memory transferDetails) internal returns (bool) {
        uint256 rewardPerToken = getRewardPerToken();

        ILRTAData memory dataFrom = abi.decode(dataOf[from], (ILRTAData));
        ILRTAData memory dataTo = abi.decode(dataOf[from], (ILRTAData));

        dataFrom.tokensOwed += dataFrom.balance * (rewardPerToken - dataFrom.rewardPerTokenPaid) / 1e18;
        dataTo.tokensOwed += dataTo.balance * (rewardPerToken - dataTo.rewardPerTokenPaid) / 1e18;

        dataFrom.balance -= transferDetails.balance;
        dataFrom.rewardPerTokenPaid = rewardPerToken;
        dataFrom.tokensOwed -= transferDetails.tokensOwed;
        dataOf[from] = abi.encode(dataFrom);

        // Cannot overflow because the sum of all user balances and tokens owed can't exceed the max uint256 value.
        unchecked {
            dataTo.tokensOwed += transferDetails.tokensOwed;
            dataTo.balance += transferDetails.balance;
        }

        dataTo.rewardPerTokenPaid = rewardPerToken;
        dataOf[to] = abi.encode(dataTo);

        emit Transfer(from, to, abi.encode(transferDetails));

        return true;
    }
}
