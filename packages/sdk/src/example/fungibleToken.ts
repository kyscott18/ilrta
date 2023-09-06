import type { ReverseMirageRead, ReverseMirageWrite } from "reverse-mirage";
import type { Account, PublicClient, WalletClient } from "viem";
import type { Address } from "viem/accounts";
import { ilrtaFungibleTokenABI } from "../generated.js";
import {
  type ILRTA,
  type ILRTAApprovalDetails,
  type ILRTAData,
  type ILRTATransferDetails,
} from "../ilrta.js";

export type FungibleToken = ILRTA<"fungibleToken"> & {
  decimals: number;
};

export type DataType = ILRTAData<FungibleToken, { balance: bigint }>;

export type TransferDetailsType = ILRTATransferDetails<
  FungibleToken,
  { amount: bigint }
>;

export type ApprovalDetailsType = ILRTAApprovalDetails<
  FungibleToken,
  { amount: bigint }
>;

export const Data = [{ name: "balance", type: "uint256" }] as const;

export const TransferDetails = [{ name: "amount", type: "uint256" }] as const;

export const ApprovalDetails = [{ name: "amount", type: "uint256" }] as const;

export const transfer = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: { to: Address; transferDetails: TransferDetailsType },
): Promise<
  ReverseMirageWrite<typeof ilrtaFungibleTokenABI, "transfer_dMWqQA">
> => {
  const { request, result } = await publicClient.simulateContract({
    account,
    abi: ilrtaFungibleTokenABI,
    functionName: "transfer_dMWqQA",
    args: [args.to, args.transferDetails],
    address: args.transferDetails.ilrta.address,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

// TODO: transferFrom

// TODO: approve

export const dataOf = (
  publicClient: PublicClient,
  args: { ilrta: FungibleToken; owner: Address },
) =>
  ({
    read: () =>
      publicClient.readContract({
        abi: ilrtaFungibleTokenABI,
        address: args.ilrta.address,
        functionName: "dataOf_cGJnTo",
        args: [
          args.owner,
          "0x0000000000000000000000000000000000000000000000000000000000000000",
        ],
      }),
    parse: (data): DataType => ({
      type: "fungibleTokenData",
      token: args.ilrta,
      balance: data.balance,
    }),
  }) satisfies ReverseMirageRead<{ balance: bigint }>;

export const allowanceOf = (
  publicClient: PublicClient,
  args: { ilrta: FungibleToken; owner: Address; spender: Address },
) =>
  ({
    read: () =>
      publicClient.readContract({
        abi: ilrtaFungibleTokenABI,
        address: args.ilrta.address,
        functionName: "allowanceOf_QDmnOj",
        args: [
          args.owner,
          args.spender,
          "0x0000000000000000000000000000000000000000000000000000000000000000",
        ],
      }),
    parse: (data): ApprovalDetailsType => ({
      type: "fungibleTokenApproval",
      ilrta: args.ilrta,
      amount: data.amount,
    }),
  }) satisfies ReverseMirageRead<{ amount: bigint }>;
