import type { ReverseMirageRead, ReverseMirageWrite } from "reverse-mirage";
import type { Account, PublicClient, WalletClient } from "viem";
import type { Address } from "viem/accounts";
import { ilrtaFungibleTokenABI } from "../generated.js";
import {
  type ILRTA,
  type ILRTAApproval,
  type ILRTAData,
  type ILRTATransfer,
} from "../ilrta.js";

export type FungibleToken = ILRTA<"fungibleToken"> & {
  decimals: number;
};

export type FungibleTokenData = ILRTAData<FungibleToken, { amount: bigint }>;

export type FungibleTokenTransfer = ILRTATransfer<
  FungibleToken,
  { amount: bigint }
>;

export type FungibleTokenApproval = ILRTAApproval<
  FungibleToken,
  { amount: bigint }
>;

// TODO: Do we need these

export const Data = [{ name: "balance", type: "uint256" }] as const;

export const TransferDetails = [{ name: "amount", type: "uint256" }] as const;

export const ApprovalDetails = [{ name: "amount", type: "uint256" }] as const;

export const fungibleTokenTransfer = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: { to: Address; transferDetails: FungibleTokenTransfer },
): Promise<
  ReverseMirageWrite<typeof ilrtaFungibleTokenABI, "transfer_dMWqQA">
> => {
  const { request, result } = await publicClient.simulateContract({
    account,
    abi: ilrtaFungibleTokenABI,
    functionName: "transfer_dMWqQA",
    args: [args.to, args.transferDetails],
    address: args.transferDetails.token.address,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

// TODO: transferFrom

// TODO: approve

export const fungibleTokenDataOf = (
  publicClient: PublicClient,
  args: { token: FungibleToken; owner: Address },
) =>
  ({
    read: () =>
      publicClient.readContract({
        abi: ilrtaFungibleTokenABI,
        address: args.token.address,
        functionName: "dataOf_cGJnTo",
        args: [
          args.owner,
          "0x0000000000000000000000000000000000000000000000000000000000000000",
        ],
      }),
    parse: (data): FungibleTokenData => ({
      type: "fungibleTokenData",
      token: args.token,
      amount: data.balance,
    }),
  }) satisfies ReverseMirageRead<{ balance: bigint }>;

export const fungibleTokenAllowanceOf = (
  publicClient: PublicClient,
  args: { token: FungibleToken; owner: Address; spender: Address },
) =>
  ({
    read: () =>
      publicClient.readContract({
        abi: ilrtaFungibleTokenABI,
        address: args.token.address,
        functionName: "allowanceOf_QDmnOj",
        args: [
          args.owner,
          args.spender,
          "0x0000000000000000000000000000000000000000000000000000000000000000",
        ],
      }),
    parse: (data): FungibleTokenApproval => ({
      type: "fungibleTokenApproval",
      token: args.token,
      amount: data.amount,
    }),
  }) satisfies ReverseMirageRead<{ amount: bigint }>;
