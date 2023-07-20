import { ilrtaABI } from "./generated.js";
import type {
  AbiParameter,
  AbiParametersToPrimitiveTypes,
  Narrow,
} from "abitype";
import type { ReverseMirageRead, ReverseMirageWrite } from "reverse-mirage";
import {
  type Hex,
  type PublicClient,
  type WalletClient,
  decodeAbiParameters,
  encodeAbiParameters,
} from "viem";
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

export const convertBytesToData = <
  TDataType extends readonly AbiParameter[] | readonly unknown[],
>(
  dataType: Narrow<TDataType>,
  bytes: Hex,
) => decodeAbiParameters(dataType, bytes);

export const convertBytesToTransferData = <
  TTransferDetailsType extends readonly AbiParameter[] | readonly unknown[],
>(
  dataType: Narrow<TTransferDetailsType>,
  bytes: Hex,
) => decodeAbiParameters(dataType, bytes);

export const convertDataToBytes = <
  TDataType extends readonly AbiParameter[] | readonly unknown[],
>(
  dataType: Narrow<TDataType>,
  data: TDataType extends readonly AbiParameter[]
    ? AbiParametersToPrimitiveTypes<TDataType>
    : never,
): Hex => encodeAbiParameters<TDataType>(dataType, data);

export const convertTransferDetailsToBytes = <
  TTransferDetailsType extends readonly AbiParameter[] | readonly unknown[],
>(
  dataType: Narrow<TTransferDetailsType>,
  data: TTransferDetailsType extends readonly AbiParameter[]
    ? AbiParametersToPrimitiveTypes<TTransferDetailsType>
    : never,
): Hex => encodeAbiParameters<TTransferDetailsType>(dataType, data);
