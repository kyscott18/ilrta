import { ilrtaFungibleTokenABI } from "../generated.js";
import {
  type ILRTA,
  type ILRTAData,
  type ILRTARequestedTransfer,
  type ILRTASignatureTransfer,
  ILRTASuperSignatureTransfer,
  ILRTATransfer,
  type ILRTATransferDetails,
} from "../ilrta.js";
import type { ReverseMirageRead, ReverseMirageWrite } from "reverse-mirage";
import invariant from "tiny-invariant";
import type { Account, Hex, PublicClient, WalletClient } from "viem";
import type { Address } from "viem/accounts";
import { getAddress, hashTypedData } from "viem/utils";

export type FungibleToken = ILRTA<"fungible token"> & {
  decimals: number;
  id: "0x0000000000000000000000000000000000000000000000000000000000000000";
};

export type DataType = ILRTAData<FungibleToken, { balance: bigint }>;

export type TransferDetailsType = ILRTATransferDetails<
  FungibleToken,
  { amount: bigint }
>;

export type SignatureTransfer = ILRTASignatureTransfer<TransferDetailsType>;

export type RequestedTransfer = ILRTARequestedTransfer<TransferDetailsType>;

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
    verifyingContract: getAddress(transfer.transferDetails.ilrta.address),
  } as const;

  return hashTypedData({
    domain,
    types: SuperSignatureTransfer,
    primaryType: "Transfer",
    message: {
      transferDetails: { amount: transfer.transferDetails.amount },
      spender: getAddress(transfer.spender),
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
        amount: transfer.transferDetails.amount,
      },
      spender: transfer.spender,
      nonce: transfer.nonce,
      deadline: transfer.deadline,
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
    args: [args.to, args.transferDetails],
    address: args.transferDetails.ilrta.address,
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
        transferDetails: {
          amount: args.signatureTransfer.transferDetails.amount,
        },
        nonce: args.signatureTransfer.nonce,
        deadline: args.signatureTransfer.deadline,
      },
      {
        to: args.requestedTransfer.to,
        transferDetails: {
          amount: args.requestedTransfer.transferDetails.amount,
        },
      },
      args.signature,
    ],
    address: args.signatureTransfer.transferDetails.ilrta.address,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

export const dataOf = (
  publicClient: PublicClient,
  args: { ilrta: FungibleToken; owner: Address },
) =>
  ({
    read: () =>
      publicClient.readContract({
        abi: ilrtaFungibleTokenABI,
        address: args.ilrta.address,
        functionName: "dataOf",
        args: [args.owner, args.ilrta.id],
      }),
    parse: (data): DataType => ({
      type: "fungible tokenData",
      ilrta: args.ilrta,
      balance: data.balance,
    }),
  }) satisfies ReverseMirageRead<{ balance: bigint }>;
