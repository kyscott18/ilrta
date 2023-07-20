import { ilrtaABI } from "./generated.js";
import type { AbiParameter } from "abitype";
import type { ReverseMirageRead, ReverseMirageWrite } from "reverse-mirage";
import { type Hex, type PublicClient, type WalletClient } from "viem";
import type { Account, Address } from "viem/accounts";

export type ILRTA = {
  name: string;
  symbol: string;
  address: Address;
};

export type ILRTAData<TILRTA extends ILRTA, TData extends object> = {
  ilrta: TILRTA;
  data: TData;
};

export type ILRTATransferDetails<TILRTA extends ILRTA, TData extends object> = {
  ilrta: TILRTA;
  data: TData;
};

export type ILRTASignatureTransfer<
  TILRTA extends ILRTA,
  TData extends object,
> = {
  nonce: bigint;
  deadline: bigint;
  transferDetails: ILRTATransferDetails<TILRTA, TData>;
};

export type ILRTARequestedTransfer<
  TILRTA extends ILRTA,
  TData extends object,
> = {
  to: Address;
  transferDetails: ILRTATransferDetails<TILRTA, TData>;
};

export const ILRTATransfer = (transferDetails: readonly AbiParameter[]) =>
  ({
    Transfer: [
      { name: "transferDetails", type: "TransferDetails" },
      { name: "spender", type: "address" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
    TransferDetails: transferDetails,
  }) as const;

export const ILRTASuperSignatureTransfer = (
  transferDetails: readonly AbiParameter[],
) =>
  ({
    Transfer: [
      { name: "transferDetails", type: "bytes" },
      { name: "spender", type: "address" },
    ],
    TransferDetails: transferDetails,
  }) as const;

export const ilrtaTransfer =
  <TILRTA extends ILRTA, TData extends object>(
    encodeDataToBytes: (
      data: ILRTATransferDetails<TILRTA, TData>["data"],
    ) => Hex,
  ) =>
  async (
    publicClient: PublicClient,
    walletClient: WalletClient,
    account: Account | Address,
    args: { to: Address; transferDetails: ILRTATransferDetails<TILRTA, TData> },
  ): Promise<ReverseMirageWrite<typeof ilrtaABI, "transfer">> => {
    const { request, result } = await publicClient.simulateContract({
      account,
      abi: ilrtaABI,
      functionName: "transfer",
      args: [args.to, encodeDataToBytes(args.transferDetails.data)],
      address: args.transferDetails.ilrta.address,
    });
    const hash = await walletClient.writeContract(request);
    return { hash, result, request };
  };

export const ilrtaTransferBySignature =
  <TILRTA extends ILRTA, TData extends object>(
    encodeDataToBytes: (
      data: ILRTATransferDetails<TILRTA, TData>["data"],
    ) => Hex,
  ) =>
  async (
    publicClient: PublicClient,
    walletClient: WalletClient,
    account: Account | Address,
    args: {
      signer: Address;
      signatureTransfer: ILRTASignatureTransfer<TILRTA, TData>;
      requestedTransfer: ILRTARequestedTransfer<TILRTA, TData>;
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
          transferDetails: encodeDataToBytes(
            args.signatureTransfer.transferDetails.data,
          ),
          nonce: args.signatureTransfer.nonce,
          deadline: args.signatureTransfer.deadline,
        },
        {
          to: args.requestedTransfer.to,
          transferDetails: encodeDataToBytes(
            args.requestedTransfer.transferDetails.data,
          ),
        },
        args.signature,
      ],
      address: args.signatureTransfer.transferDetails.ilrta.address,
    });
    const hash = await walletClient.writeContract(request);
    return { hash, result, request };
  };

export const ilrtaDataOf =
  <TILRTA extends ILRTA, TData extends object>(
    decodeBytesToData: (bytes: Hex, ilrta: TILRTA) => TData,
  ) =>
  (
    publicClient: PublicClient,
    args: { ilrta: TILRTA; owner: Address; id: Hex },
  ) =>
    ({
      read: () =>
        publicClient.readContract({
          abi: ilrtaABI,
          address: args.ilrta.address,
          functionName: "dataOf",
          args: [args.owner, args.id],
        }),
      parse: (data): TData => decodeBytesToData(data, args.ilrta),
    }) satisfies ReverseMirageRead<Hex>;
