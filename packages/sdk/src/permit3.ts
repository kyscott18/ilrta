import type {
  ERC20,
  ERC20Amount,
  ReverseMirageRead,
  ReverseMirageWrite,
} from "reverse-mirage";
import invariant from "tiny-invariant";
import {
  type Account,
  type Address,
  type Hex,
  type PublicClient,
  type WalletClient,
  encodeAbiParameters,
  getAddress,
} from "viem";
import { Permit3Address } from "./constants.js";
import { permit3ABI } from "./generated.js";
import type { ILRTATransferDetails } from "./ilrta.js";

export const TokenTypeEnum = {
  ERC20: 0,
  ILRTA: 1,
} as const;

export type TransferDetails =
  | (Pick<ILRTATransferDetails, "type" | "ilrta"> & { transferDetails: Hex })
  | ERC20Amount<ERC20>;

const isILRTA = (
  transferDetails: TransferDetails,
): transferDetails is Pick<ILRTATransferDetails, "type" | "ilrta"> & {
  transferDetails: Hex;
} => !("token" in transferDetails);

export type SignatureTransfer = {
  transferDetails: TransferDetails;
  nonce: bigint;
  deadline: bigint;
};

export type SignatureTransferBatch = {
  transferDetails: readonly TransferDetails[];
  nonce: bigint;
  deadline: bigint;
};

export type SignatureTransferERC20 = {
  transferDetails: ERC20Amount<ERC20>;
  nonce: bigint;
  deadline: bigint;
};

export type SignatureTransferBatchERC20 = {
  transferDetails: readonly ERC20Amount<ERC20>[];
  nonce: bigint;
  deadline: bigint;
};

export type RequestedTransfer<TTransferDetails extends TransferDetails> = {
  to: Address;
} & (TTransferDetails["type"] extends `erc20${string}`
  ? { amount: bigint }
  : { transferDetails: Hex });

export type RequestedTransferERC20 = {
  to: Address;
  amount: Pick<ERC20Amount<ERC20>, "amount">;
};

export const TransferDetailsType = [
  { name: "token", type: "address" },
  { name: "tokenType", type: "uint8" },
  { name: "functionSelector", type: "bytes4" },
  { name: "transferDetails", type: "bytes" },
] as const;

export const TransferDetailsERC20 = [
  {
    name: "token",
    type: "address",
  },
  { name: "amount", type: "uint256" },
] as const;

export const Transfer = {
  Transfer: [
    { name: "transferDetails", type: "TransferDetails" },
    { name: "spender", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
  TransferDetails: TransferDetailsType,
};

export const TransferBatch = {
  Transfer: [
    { name: "transferDetails", type: "TransferDetails[]" },
    { name: "spender", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
  TransferDetails: TransferDetailsType,
} as const;

export const TransferERC20 = {
  Transfer: [
    { name: "transferDetails", type: "TransferDetails" },
    { name: "spender", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
  TransferDetails: TransferDetailsERC20,
} as const;

export const TransferBatchERC20 = {
  Transfer: [
    { name: "transferDetails", type: "TransferDetails[]" },
    { name: "spender", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
  TransferDetails: TransferDetailsERC20,
} as const;

export const permit3SignTransfer = (
  walletClient: WalletClient,
  account: Account | Address,
  transfer: SignatureTransfer & { spender: Address },
): Promise<Hex> => {
  const chainID = walletClient.chain?.id;
  invariant(chainID);

  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: Permit3Address,
  } as const;

  return walletClient.signTypedData({
    domain,
    account,
    types: Transfer,
    primaryType: "Transfer",
    message: {
      transferDetails: isILRTA(transfer.transferDetails)
        ? ({
            token: getAddress(transfer.transferDetails.ilrta.address),
            tokenType: TokenTypeEnum.ILRTA,
            functionSelector: "0x811c34d3",
            transferDetails: transfer.transferDetails.transferDetails,
          } as const)
        : ({
            token: getAddress(transfer.transferDetails.token.address),
            tokenType: TokenTypeEnum.ERC20,
            functionSelector: "0x23b872dd",
            transferDetails: encodeAbiParameters(
              [{ name: "amount", type: "uint256" }],
              [transfer.transferDetails.amount],
            ),
          } as const),
      spender: getAddress(transfer.spender),
      nonce: transfer.nonce,
      deadline: transfer.deadline,
    },
  });
};

export const permit3SignTransferBatch = (
  walletClient: WalletClient,
  account: Account | Address,
  transfers: SignatureTransferBatch & { spender: Address },
) => {
  const chainID = walletClient.chain?.id;
  invariant(chainID);

  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: Permit3Address,
  } as const;

  return walletClient.signTypedData({
    domain,
    account,
    types: TransferBatch,
    primaryType: "Transfer",
    message: {
      transferDetails: transfers.transferDetails.map((t) =>
        isILRTA(t)
          ? ({
              token: getAddress(t.ilrta.address),
              tokenType: TokenTypeEnum.ILRTA,
              functionSelector: "0x811c34d3",
              transferDetails: t.transferDetails,
            } as const)
          : ({
              token: getAddress(t.token.address),
              tokenType: TokenTypeEnum.ERC20,
              functionSelector: "0x23b872dd",
              transferDetails: encodeAbiParameters(
                [{ name: "amount", type: "uint256" }],
                [t.amount],
              ),
            } as const),
      ),
      spender: getAddress(transfers.spender),
      nonce: transfers.nonce,
      deadline: transfers.deadline,
    },
  });
};

export const permit3SignTransferERC20 = (
  walletClient: WalletClient,
  account: Account | Address,
  transfer: SignatureTransferERC20 & { spender: Address },
): Promise<Hex> => {
  const chainID = walletClient.chain?.id;
  invariant(chainID);

  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: Permit3Address,
  } as const;

  return walletClient.signTypedData({
    domain,
    account,
    types: TransferERC20,
    primaryType: "Transfer",
    message: {
      transferDetails: {
        token: getAddress(transfer.transferDetails.token.address),
        amount: transfer.transferDetails.amount,
      } as const,
      spender: getAddress(transfer.spender),
      nonce: transfer.nonce,
      deadline: transfer.deadline,
    },
  });
};

export const permit3SignTransferBatchERC20 = (
  walletClient: WalletClient,
  account: Account | Address,
  transfers: SignatureTransferBatchERC20 & { spender: Address },
) => {
  const chainID = walletClient.chain?.id;
  invariant(chainID);

  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: Permit3Address,
  } as const;

  return walletClient.signTypedData({
    domain,
    account,
    types: TransferBatchERC20,
    primaryType: "Transfer",
    message: {
      transferDetails: transfers.transferDetails.map(
        (t) =>
          ({
            token: getAddress(t.token.address),
            amount: t.amount,
          }) as const,
      ),
      spender: getAddress(transfers.spender),
      nonce: transfers.nonce,
      deadline: transfers.deadline,
    },
  });
};

export const permit3TransferBySignature = async <
  TSignatureTransfer extends SignatureTransfer,
>(
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: {
    signer: Address;
    signatureTransfer: TSignatureTransfer;
    requestedTransfer: RequestedTransfer<TSignatureTransfer["transferDetails"]>;
    signature: Hex;
  },
): Promise<ReverseMirageWrite<typeof permit3ABI, "transferBySignature">> => {
  const { request, result } = await publicClient.simulateContract({
    address: Permit3Address,
    abi: permit3ABI,
    functionName: "transferBySignature",
    args: [
      args.signer,
      {
        transferDetails: isILRTA(args.signatureTransfer.transferDetails)
          ? ({
              token: getAddress(
                args.signatureTransfer.transferDetails.ilrta.address,
              ),
              tokenType: TokenTypeEnum.ILRTA,
              functionSelector: "0x811c34d3",
              transferDetails:
                args.signatureTransfer.transferDetails.transferDetails,
            } as const)
          : ({
              token: getAddress(
                args.signatureTransfer.transferDetails.token.address,
              ),
              tokenType: TokenTypeEnum.ERC20,
              functionSelector: "0x23b872dd",
              transferDetails: encodeAbiParameters(
                [{ name: "amount", type: "uint256" }],
                [args.signatureTransfer.transferDetails.amount],
              ),
            } as const),
        nonce: args.signatureTransfer.nonce,
        deadline: args.signatureTransfer.deadline,
      },
      {
        to: args.requestedTransfer.to,
        transferDetails:
          "amount" in args.requestedTransfer
            ? encodeAbiParameters(
                [{ name: "amount", type: "uint256" }],
                [args.requestedTransfer.amount],
              )
            : args.requestedTransfer.transferDetails,
      },
      args.signature,
    ],
    account,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

export const permit3TransferBatchBySignature = async <
  TSignatureTransferBatch extends SignatureTransferBatch,
>(
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: {
    signer: Address;
    signatureTransfer: TSignatureTransferBatch;
    requestedTransfer: readonly RequestedTransfer<
      TSignatureTransferBatch["transferDetails"][number]
    >[];
    signature: Hex;
  },
): Promise<ReverseMirageWrite<typeof permit3ABI, "transferBySignature">> => {
  const { request, result } = await publicClient.simulateContract({
    address: Permit3Address,
    abi: permit3ABI,
    functionName: "transferBySignature",
    args: [
      args.signer,
      {
        transferDetails: args.signatureTransfer.transferDetails.map((t) =>
          isILRTA(t)
            ? ({
                token: getAddress(t.ilrta.address),
                tokenType: TokenTypeEnum.ILRTA,
                functionSelector: "0x811c34d3",
                transferDetails: t.transferDetails,
              } as const)
            : ({
                token: getAddress(t.token.address),
                tokenType: TokenTypeEnum.ERC20,
                functionSelector: "0x23b872dd",
                transferDetails: encodeAbiParameters(
                  [{ name: "amount", type: "uint256" }],
                  [t.amount],
                ),
              } as const),
        ),
        nonce: args.signatureTransfer.nonce,
        deadline: args.signatureTransfer.deadline,
      },
      args.requestedTransfer.map((r) => ({
        to: r.to,
        transferDetails:
          "amount" in r
            ? encodeAbiParameters(
                [{ name: "amount", type: "uint256" }],
                [r.amount],
              )
            : r.transferDetails,
      })),
      args.signature,
    ],
    account,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

export const permit3TransferERC20BySignature = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: {
    signer: Address;
    signatureTransfer: SignatureTransferERC20;
    requestedTransfer: RequestedTransferERC20;
    signature: Hex;
  },
): Promise<ReverseMirageWrite<typeof permit3ABI, "transferBySignature">> => {
  const { request, result } = await publicClient.simulateContract({
    address: Permit3Address,
    abi: permit3ABI,
    functionName: "transferBySignature",
    args: [
      args.signer,
      {
        transferDetails: {
          token: getAddress(
            args.signatureTransfer.transferDetails.token.address,
          ),
          amount: args.signatureTransfer.transferDetails.amount,
        } as const,
        nonce: args.signatureTransfer.nonce,
        deadline: args.signatureTransfer.deadline,
      },
      {
        to: args.requestedTransfer.to,
        amount: args.requestedTransfer.amount.amount,
      },
      args.signature,
    ],
    account,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

export const permit3TransferBatchERC20BySignature = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: {
    signer: Address;
    signatureTransfer: SignatureTransferBatchERC20;
    requestedTransfer: readonly RequestedTransferERC20[];
    signature: Hex;
  },
): Promise<ReverseMirageWrite<typeof permit3ABI, "transferBySignature">> => {
  const { request, result } = await publicClient.simulateContract({
    address: Permit3Address,
    abi: permit3ABI,
    functionName: "transferBySignature",
    args: [
      args.signer,
      {
        transferDetails: args.signatureTransfer.transferDetails.map(
          (t) =>
            ({
              token: getAddress(t.token.address),
              amount: t.amount,
            }) as const,
        ),
        nonce: args.signatureTransfer.nonce,
        deadline: args.signatureTransfer.deadline,
      },
      args.requestedTransfer.map((r) => ({
        to: r.to,
        amount: r.amount.amount,
      })),
      args.signature,
    ],
    account,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

export const isNonceUsed = (
  publicClient: PublicClient,
  args: { address: Address; nonce: bigint },
) => {
  return {
    read: () =>
      publicClient.readContract({
        abi: permit3ABI,
        address: Permit3Address,
        functionName: "nonceBitmap",
        args: [args.address, args.nonce >> 8n],
      }),
    parse: (data): boolean => (data & (1n << (args.nonce & 0xffn))) > 0n,
  } satisfies ReverseMirageRead<bigint>;
};
