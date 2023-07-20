import { ilrtaFungibleTokenABI } from "../generated.js";
import type { ILRTA } from "../ilrta.js";
import type { ReverseMirageRead, ReverseMirageWrite } from "reverse-mirage";
import type { Account, Hex, PublicClient, WalletClient } from "viem";
import type { Address } from "viem/accounts";
import {
  decodeAbiParameters,
  encodeAbiParameters,
  hashTypedData,
} from "viem/utils";

export type FungibleToken = ILRTA & { decimals: number };

export type SignatureTransfer = {
  nonce: bigint;
  deadline: bigint;
  transferDetails: TransferDetailsType;
};

export type RequestedTransfer = {
  to: Address;
  transferDetails: TransferDetailsType;
};

export type DataType = { ft: FungibleToken; balance: bigint };

export type TransferDetailsType = { ft: FungibleToken; amount: bigint };

export const Data = [{ name: "balance", type: "uint256" }] as const;

export const TransferDetails = [{ name: "amount", type: "uint256" }] as const;

export const Transfer = {
  Transfer: [
    { name: "transferDetails", type: "TransferDetails" },
    { name: "spender", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
  TransferDetails: { TransferDetails },
} as const;

export const SuperSignatureTransfer = {
  Transfer: [
    { name: "transferDetails", type: "TransferDetails" },
    { name: "spender", type: "address" },
  ],
  TransferDetails: { TransferDetails },
} as const;

export const getTransferTypedDataHash = (
  chainID: number,
  transfers: {
    transferDetails: TransferDetailsType;
    spender: Address;
  },
) => {
  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: transfers.transferDetails.ft.address,
  } as const;

  return hashTypedData({
    domain,
    types: SuperSignatureTransfer,
    primaryType: "Transfer",
    message: {
      transferDetails: {
        amount: transfers.transferDetails.amount,
      },
      spender: transfers.spender,
    },
  });
};

export const transfer = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: { to: Address; transferDetails: TransferDetailsType },
): Promise<ReverseMirageWrite<typeof ilrtaFungibleTokenABI, "transfer">> => {
  const { request, result } = await publicClient.simulateContract({
    account,
    abi: ilrtaFungibleTokenABI,
    functionName: "transfer",
    args: [
      args.to,
      encodeAbiParameters(TransferDetails, [args.transferDetails.amount]),
    ],
    address: args.transferDetails.ft.address,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

export const transferBySignature = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: {
    signer: Address;
    signatureTransfer: SignatureTransfer;
    requestedTransfer: RequestedTransfer;
    signature: Hex;
  },
): Promise<
  ReverseMirageWrite<typeof ilrtaFungibleTokenABI, "transferBySignature">
> => {
  const { request, result } = await publicClient.simulateContract({
    account,
    abi: ilrtaFungibleTokenABI,
    functionName: "transferBySignature",
    args: [
      args.signer,
      {
        transferDetails: encodeAbiParameters(TransferDetails, [
          args.signatureTransfer.transferDetails.amount,
        ]),
        nonce: args.signatureTransfer.nonce,
        deadline: args.signatureTransfer.deadline,
      },
      {
        to: args.requestedTransfer.to,
        transferDetails: encodeAbiParameters(TransferDetails, [
          args.requestedTransfer.transferDetails.amount,
        ]),
      },
      args.signature,
    ],
    address: args.signatureTransfer.transferDetails.ft.address,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

export const dataOf = (
  publicClient: PublicClient,
  args: { ft: FungibleToken; owner: Address },
) =>
  ({
    read: () =>
      publicClient.readContract({
        abi: ilrtaFungibleTokenABI,
        address: args.ft.address,
        functionName: "dataOf",
        args: [args.owner, "0x"],
      }),
    parse: (data): DataType => ({
      balance: decodeAbiParameters(Data, data)[0],
      ft: args.ft,
    }),
  }) satisfies ReverseMirageRead<Hex>;
