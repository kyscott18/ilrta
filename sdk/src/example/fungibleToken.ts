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
import invariant from "tiny-invariant";
import type { Account, Hex, WalletClient } from "viem";
import type { Address } from "viem/accounts";
import {
  decodeAbiParameters,
  encodeAbiParameters,
  hashTypedData,
} from "viem/utils";

export type FungibleToken = ILRTA & { decimals: number; id: "0x" };

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
  transfer: {
    transferDetails: TransferDetailsType;
    spender: Address;
  },
) => {
  const domain = {
    name: transfer.transferDetails.ilrta.name,
    version: "1",
    chainId: chainID,
    verifyingContract: transfer.transferDetails.ilrta.address,
  } as const;

  return hashTypedData({
    domain,
    types: SuperSignatureTransfer,
    primaryType: "Transfer",
    message: {
      transferDetails: {
        amount: transfer.transferDetails.data.amount,
      },
      spender: transfer.spender,
    },
  });
};

export const signTransfer = (
  walletClient: WalletClient,
  account: Account | Address,
  transfer: SignatureTransfer & { spender: Address },
): Promise<Hex> => {
  const chainID = walletClient.chain?.id;
  invariant(chainID);

  const domain = {
    name: transfer.transferDetails.ilrta.name,
    version: "1",
    chainId: chainID,
    verifyingContract: transfer.transferDetails.ilrta.address,
  } as const;

  return walletClient.signTypedData({
    domain,
    account,
    types: Transfer,
    primaryType: "Transfer",
    message: {
      transferDetails: {
        amount: transfer.transferDetails.data.amount,
      },
      spender: transfer.spender,
      nonce: transfer.nonce,
      deadline: transfer.deadline,
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
