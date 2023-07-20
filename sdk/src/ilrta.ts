import { ilrtaABI } from "./generated.js";
import type { ReverseMirageRead, ReverseMirageWrite } from "reverse-mirage";
import { type Hex, type PublicClient, type WalletClient } from "viem";
import type { Account, Address } from "viem/accounts";

export type ILRTA = {
  name: string;
  symbol: string;
  address: Address;
};

export type ILRTASignatureTransfer = {
  nonce: bigint;
  deadline: bigint;
  transferDetails: ILRTATransferDetails;
};

export type ILRTARequestedTransfer = {
  to: Address;
  transferDetails: ILRTATransferDetails;
};

export type ILRTAData = {
  ilrta: Pick<ILRTA, "address">;
  data: Hex;
};

export type ILRTATransferDetails = {
  ilrta: Pick<ILRTA, "address">;
  data: Hex;
};

export const Transfer = {
  Transfer: [
    { name: "transferDetails", type: "bytes" },
    { name: "spender", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
} as const;

export const SuperSignatureTransfer = {
  Transfer: [
    { name: "transferDetails", type: "bytes" },
    { name: "spender", type: "address" },
  ],
} as const;

export const getTransferTypedDataHash = () => {};

export const ilrtaTransfer = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: { to: Address; transferDetails: ILRTATransferDetails },
): Promise<ReverseMirageWrite<typeof ilrtaABI, "transfer">> => {
  const { request, result } = await publicClient.simulateContract({
    account,
    abi: ilrtaABI,
    functionName: "transfer",
    args: [args.to, args.transferDetails.data],
    address: args.transferDetails.ilrta.address,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

export const ilrtaTransferBySignature = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: {
    signer: Address;
    signatureTransfer: ILRTASignatureTransfer;
    requestedTransfer: ILRTARequestedTransfer;
    signature: Hex;
  },
): Promise<ReverseMirageWrite<typeof ilrtaABI, "transferBySignature">> => {
  const { request, result } = await publicClient.simulateContract({
    account,
    abi: ilrtaABI,
    functionName: "transferBySignature",
    args: [
      args.signer,
      {
        transferDetails: args.signatureTransfer.transferDetails.data,
        nonce: args.signatureTransfer.nonce,
        deadline: args.signatureTransfer.deadline,
      },
      {
        to: args.requestedTransfer.to,
        transferDetails: args.requestedTransfer.transferDetails.data,
      },
      args.signature,
    ],
    address: args.signatureTransfer.transferDetails.ilrta.address,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

export const ilrtaDataOf = (
  publicClient: PublicClient,
  args: { ilrta: Pick<ILRTA, "address">; owner: Address; id: Hex },
) =>
  ({
    read: () =>
      publicClient.readContract({
        abi: ilrtaABI,
        address: args.ilrta.address,
        functionName: "dataOf",
        args: [args.owner, args.id],
      }),
    parse: (data) => data,
  }) satisfies ReverseMirageRead<Hex>;
