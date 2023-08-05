// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {ILRTA} from "../ILRTA.sol";
// import {SignatureVerification} from "../SignatureVerification.sol";

// /// @notice Implement a semi-fungible token with ilrta
// /// @author Kyle Scott
// abstract contract ILRTASemiFungibleToken is ILRTA {
//     /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
//                                DATA TYPES
//     <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

//     struct ILRTADataID {
//         uint256 id;
//     }

//     struct ILRTAData {
//         uint256 balance;
//     }

//     struct ILRTATransferDetails {
//         bytes32 id;
//         uint256 amount;
//     }

//     struct SignatureTransfer {
//         uint256 nonce;
//         uint256 deadline;
//         ILRTATransferDetails transferDetails;
//     }

//     struct RequestedTransfer {
//         address to;
//         ILRTATransferDetails transferDetails;
//     }

//     /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
//                                 STORAGE
//     <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

//     mapping(address owner => mapping(bytes32 id => ILRTAData data)) private _dataOf;

//     /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
//                               CONSTRUCTOR
//     <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

//     constructor(
//         address _superSignature,
//         string memory _name,
//         string memory _symbol
//     )
//         ILRTA(_superSignature, _name, _symbol, "TransferDetails(uint256 id,uint256 amount)")
//     {
//         name = _name;
//         symbol = _symbol;
//     }

//     /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
//                                  LOGIC
//     <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

//     function balanceOf(address owner, uint256 id) external view returns (uint256 balance) {
//         return _dataOf[owner][bytes32(id)].balance;
//     }

//     /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
//                               ILRTA LOGIC
//     <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

//     function dataID(ILRTADataID calldata id) external pure returns (bytes32) {
//         return bytes32(id.id);
//     }

//     function dataOf(address owner, bytes32 id) external view returns (ILRTAData memory) {
//         return _dataOf[owner][id];
//     }

//     function transfer(address to, ILRTATransferDetails calldata transferDetails) external returns (bool) {
//         return _transfer(msg.sender, to, transferDetails);
//     }

//     function transferBySignature(
//         address from,
//         SignatureTransfer calldata signatureTransfer,
//         RequestedTransfer calldata requestedTransfer,
//         bytes calldata signature
//     )
//         external
//         returns (bool)
//     {
//         if (
//             requestedTransfer.transferDetails.amount > signatureTransfer.transferDetails.amount
//                 || signatureTransfer.transferDetails.id != requestedTransfer.transferDetails.id
//         ) {
//             revert InvalidRequest(abi.encode(signatureTransfer.transferDetails));
//         }

//         _verifySignature(from, signatureTransfer, signature);

//         return _transfer(from, requestedTransfer.to, requestedTransfer.transferDetails);
//     }

//     function transferBySuperSignature(
//         address from,
//         ILRTATransferDetails calldata transferDetails,
//         RequestedTransfer calldata requestedTransfer,
//         bytes32[] calldata dataHash
//     )
//         external
//         returns (bool)
//     {
//         if (
//             requestedTransfer.transferDetails.amount > transferDetails.amount
//                 || transferDetails.id != requestedTransfer.transferDetails.id
//         ) {
//             revert InvalidRequest(abi.encode(transferDetails));
//         }

//         _verifySuperSignature(from, transferDetails, dataHash);

//         return _transfer(from, requestedTransfer.to, requestedTransfer.transferDetails);
//     }

//     /*<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3
//                              INTERNAL LOGIC
//     <3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3<3*/

//     function _verifySignature(
//         address from,
//         SignatureTransfer calldata signatureTransfer,
//         bytes calldata signature
//     )
//         private
//     {
//         if (block.timestamp > signatureTransfer.deadline) revert SignatureExpired(signatureTransfer.deadline);

//         useUnorderedNonce(from, signatureTransfer.nonce);

//         bytes32 signatureHash = hashTypedData(
//             keccak256(
//                 abi.encode(
//                     TRANSFER_TYPEHASH,
//                     keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, signatureTransfer.transferDetails)),
//                     msg.sender,
//                     signatureTransfer.nonce,
//                     signatureTransfer.deadline
//                 )
//             )
//         );

//         SignatureVerification.verify(signature, signatureHash, from);
//     }

//     function _verifySuperSignature(
//         address from,
//         ILRTATransferDetails calldata transferDetails,
//         bytes32[] calldata dataHash
//     )
//         private
//     {
//         bytes32 signatureHash = hashTypedData(
//             keccak256(
//                 abi.encode(
//                     SUPER_SIGNATURE_TRANSFER_TYPEHASH,
//                     keccak256(abi.encode(TRANSFER_DETAILS_TYPEHASH, transferDetails)),
//                     msg.sender
//                 )
//             )
//         );

//         if (dataHash[0] != signatureHash) revert DataHashMismatch();

//         superSignature.verifyData(from, dataHash);
//     }

//     function _transfer(address from, address to, ILRTATransferDetails memory transferDetails) internal returns (bool)
// {
//         _dataOf[from][transferDetails.id].balance -= transferDetails.amount;

//         _dataOf[to][transferDetails.id].balance += transferDetails.amount;

//         emit Transfer(from, to, abi.encode(transferDetails));

//         return true;
//     }

//     function _mint(address to, bytes32 id, uint256 amount) internal virtual {
//         _dataOf[to][id].balance += amount;

//         emit Transfer(address(0), to, abi.encode(ILRTATransferDetails({amount: amount, id: id})));
//     }

//     function _burn(address from, bytes32 id, uint256 amount) internal virtual {
//         _dataOf[from][id].balance -= amount;

//         emit Transfer(from, address(0), abi.encode(ILRTATransferDetails({amount: amount, id: id})));
//     }
// }
