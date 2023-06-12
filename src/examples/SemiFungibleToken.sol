// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILRTA} from "../ILRTA.sol";

abstract contract ILRTASemiFungibleToken is ILRTA {
    /*(((((((((((((((((((((((((((STORAGE))))))))))))))))))))))))))*/

    mapping(address owner => mapping(bytes32 id => ILRTAData data)) internal _dataOf;

    /*(((((((((((((((((((((((((CONSTRUCTOR))))))))))))))))))))))))*/

    constructor(
        string memory _name,
        string memory _symbol
    )
        ILRTA(_name, symbol, "TransferDetails(uint256 id,uint256 amount)")
    {
        name = _name;
        symbol = _symbol;
    }

    /*((((((((((((((((((((((((((((LOGIC)))))))))))))))))))))))))))*/

    function balanceOf(address owner, uint256 id) external view returns (uint256 balance) {
        return _dataOf[owner][bytes32(id)].balance;
    }

    /*(((((((((((((((((((((((((ILRTA LOGIC))))))))))))))))))))))))*/

    struct ILRTADataID {
        uint256 id;
    }

    struct ILRTAData {
        uint256 balance;
    }

    struct ILRTATransferDetails {
        bytes32 id;
        uint256 amount;
    }

    function dataID(bytes calldata idBytes) external pure override returns (bytes32) {
        ILRTADataID memory id = abi.decode(idBytes, (ILRTADataID));
        return bytes32(id.id);
    }

    function dataOf(address owner, bytes32 id) external view override returns (bytes memory) {
        return abi.encode(_dataOf[owner][id]);
    }

    function transfer(address to, bytes calldata transferDetailsBytes) external override returns (bool) {
        ILRTATransferDetails memory transferDetails = abi.decode(transferDetailsBytes, (ILRTATransferDetails));
        return _transfer(msg.sender, to, transferDetails);
    }

    function transferBySignature(
        address from,
        SignatureTransfer calldata signatureTransfer,
        RequestedTransfer calldata requestedTransfer,
        bytes calldata signature
    )
        external
        override
        returns (bool)
    {
        ILRTATransferDetails memory transferDetails =
            abi.decode(requestedTransfer.transferDetails, (ILRTATransferDetails));
        ILRTATransferDetails memory signatureTransferDetails =
            abi.decode(signatureTransfer.transferDetails, (ILRTATransferDetails));

        if (
            transferDetails.amount > signatureTransferDetails.amount
                || transferDetails.id != signatureTransferDetails.id
        ) {
            revert InvalidRequest(abi.encode(signatureTransfer.transferDetails));
        }

        verifySignature(from, signatureTransfer, signature);

        return
        /* solhint-disable-next-line max-line-length */
        _transfer(from, requestedTransfer.to, abi.decode(requestedTransfer.transferDetails, (ILRTATransferDetails)));
    }

    /*(((((((((((((((((((((((INTERNAL LOGIC)))))))))))))))))))))))*/

    function _transfer(address from, address to, ILRTATransferDetails memory transferDetails) internal returns (bool) {
        _dataOf[from][transferDetails.id].balance -= transferDetails.amount;

        _dataOf[to][transferDetails.id].balance += transferDetails.amount;

        emit Transfer(from, to, abi.encode(transferDetails));

        return true;
    }

    function _mint(address to, bytes32 id, uint256 amount) internal virtual {
        _dataOf[to][id].balance += amount;

        emit Transfer(address(0), to, abi.encode(ILRTATransferDetails({amount: amount, id: id})));
    }

    function _burn(address from, bytes32 id, uint256 amount) internal virtual {
        _dataOf[from][id].balance -= amount;

        emit Transfer(from, address(0), abi.encode(ILRTATransferDetails({amount: amount, id: id})));
    }
}