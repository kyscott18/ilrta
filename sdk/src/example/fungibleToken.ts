import {
  type ILRTA,
  type ILRTAData,
  type ILRTARequestedTransfer,
  type ILRTASignatureTransfer,
  ILRTASuperSignatureTransfer,
  ILRTATransfer,
  type ILRTATransferDetails,
  ilrtaDataOf,
  ilrtaTransfer,
  ilrtaTransferBySignature,
} from "../ilrta.js";
import type { Hex } from "viem";
import type { Address } from "viem/accounts";
import {
  decodeAbiParameters,
  encodeAbiParameters,
  hashTypedData,
} from "viem/utils";

export type FungibleToken = ILRTA & { decimals: number };

export type SignatureTransfer = ILRTASignatureTransfer<
  FungibleToken,
  { amount: bigint }
>;

export type RequestedTransfer = ILRTARequestedTransfer<
  FungibleToken,
  { amount: bigint }
>;

export type DataType = ILRTAData<FungibleToken, { balance: bigint }>;

export type TransferDetailsType = ILRTATransferDetails<
  FungibleToken,
  { amount: bigint }
>;

export const Data = [{ name: "balance", type: "uint256" }] as const;

export const TransferDetails = [{ name: "amount", type: "uint256" }] as const;

export const Transfer = ILRTATransfer(TransferDetails);

export const SuperSignatureTransfer =
  ILRTASuperSignatureTransfer(TransferDetails);

export const getTransferTypedDataHash = (
  chainID: number,
  transfers: {
    transferDetails: TransferDetailsType;
    spender: Address;
  },
) => {
  const domain = {
    name: transfers.transferDetails.ilrta.name,
    version: "1",
    chainId: chainID,
    verifyingContract: transfers.transferDetails.ilrta.address,
  } as const;

  return hashTypedData({
    domain,
    types: SuperSignatureTransfer,
    primaryType: "Transfer",
    message: {
      transferDetails: {
        amount: transfers.transferDetails.data.amount,
      },
      spender: transfers.spender,
    },
  });
};

export const transfer = ilrtaTransfer((data: TransferDetailsType["data"]) =>
  encodeAbiParameters(TransferDetails, [data.amount]),
);

export const transferBySignature = ilrtaTransferBySignature(
  (data: TransferDetailsType["data"]) =>
    encodeAbiParameters(TransferDetails, [data.amount]),
);

export const dataOf = ilrtaDataOf(
  (bytes: Hex, ft: FungibleToken): DataType => ({
    data: { balance: decodeAbiParameters(Data, bytes)[0] },
    ilrta: ft,
  }),
);
