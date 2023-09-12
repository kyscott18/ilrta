import type {
  BaseERC20,
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
import { permit3ABI } from "./generated.js";
import type { ILRTATransfer } from "./ilrta.js";

export const TokenTypeEnum = {
  ERC20: 0,
  ILRTA: 1,
} as const;

export type TransferDetails =
  | (Pick<ILRTATransfer, "type" | "token"> & { transferDetails: Hex })
  | ERC20Amount<BaseERC20>;

const isILRTA = (
  transferDetails: TransferDetails,
): transferDetails is Pick<ILRTATransfer, "type" | "token"> & {
  transferDetails: Hex;
} => "transferDetails" in transferDetails;

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
  transferDetails: ERC20Amount<BaseERC20>;
  nonce: bigint;
  deadline: bigint;
};

export type SignatureTransferBatchERC20 = {
  transferDetails: readonly ERC20Amount<BaseERC20>[];
  nonce: bigint;
  deadline: bigint;
};

export type RequestedTransfer<TTransferDetails extends TransferDetails> =
  TTransferDetails extends { transferDetails: Hex }
    ? { transferDetails: Hex }
    : Omit<ERC20Amount<BaseERC20>, "type" | "token">;

export type RequestedTransferERC20 = Pick<ERC20Amount<BaseERC20>, "amount">;

export const TransferDetailsType = [
  { name: "token", type: "address" },
  { name: "tokenType", type: "uint8" },
  { name: "functionSelector", type: "uint32" },
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

export const encodeTransferDetails = (transferDetails: TransferDetails) =>
  isILRTA(transferDetails)
    ? ({
        token: getAddress(transferDetails.token.address),
        tokenType: TokenTypeEnum.ILRTA,
        functionSelector: 0x811c34d3,
        transferDetails: transferDetails.transferDetails,
      } as const)
    : ({
        token: getAddress(transferDetails.token.address),
        tokenType: TokenTypeEnum.ERC20,
        functionSelector: 0x23b872dd,
        transferDetails: encodeAbiParameters(
          [{ name: "amount", type: "uint256" }],
          [transferDetails.amount],
        ),
      } as const);

export const permit3SignTransfer = (
  walletClient: WalletClient,
  account: Account | Address,
  args: SignatureTransfer & { spender: Address; permit3: Address },
): Promise<Hex> => {
  const chainID = walletClient.chain?.id;
  invariant(chainID);

  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: args.permit3,
  } as const;

  return walletClient.signTypedData({
    domain,
    account,
    types: Transfer,
    primaryType: "Transfer",
    message: {
      transferDetails: encodeTransferDetails(args.transferDetails),
      spender: getAddress(args.spender),
      nonce: args.nonce,
      deadline: args.deadline,
    },
  });
};

export const permit3SignTransferBatch = (
  walletClient: WalletClient,
  account: Account | Address,
  args: SignatureTransferBatch & { spender: Address; permit3: Address },
) => {
  const chainID = walletClient.chain?.id;
  invariant(chainID);

  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: args.permit3,
  } as const;

  return walletClient.signTypedData({
    domain,
    account,
    types: TransferBatch,
    primaryType: "Transfer",
    message: {
      transferDetails: args.transferDetails.map((t) =>
        encodeTransferDetails(t),
      ),
      spender: getAddress(args.spender),
      nonce: args.nonce,
      deadline: args.deadline,
    },
  });
};

export const permit3SignTransferERC20 = (
  walletClient: WalletClient,
  account: Account | Address,
  args: SignatureTransferERC20 & { spender: Address; permit3: Address },
): Promise<Hex> => {
  const chainID = walletClient.chain?.id;
  invariant(chainID);

  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: args.permit3,
  } as const;

  return walletClient.signTypedData({
    domain,
    account,
    types: TransferERC20,
    primaryType: "Transfer",
    message: {
      transferDetails: {
        token: getAddress(args.transferDetails.token.address),
        amount: args.transferDetails.amount,
      } as const,
      spender: getAddress(args.spender),
      nonce: args.nonce,
      deadline: args.deadline,
    },
  });
};

export const permit3SignTransferBatchERC20 = (
  walletClient: WalletClient,
  account: Account | Address,
  args: SignatureTransferBatchERC20 & { spender: Address; permit3: Address },
) => {
  const chainID = walletClient.chain?.id;
  invariant(chainID);

  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: args.permit3,
  } as const;

  return walletClient.signTypedData({
    domain,
    account,
    types: TransferBatchERC20,
    primaryType: "Transfer",
    message: {
      transferDetails: args.transferDetails.map(
        (t) =>
          ({
            token: getAddress(t.token.address),
            amount: t.amount,
          }) as const,
      ),
      spender: getAddress(args.spender),
      nonce: args.nonce,
      deadline: args.deadline,
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
    from: Address;
    to: Address;
    signatureTransfer: TSignatureTransfer;
    requestedTransfer: RequestedTransfer<TSignatureTransfer["transferDetails"]>;
    signature: Hex;
    permit3: Address;
  },
): Promise<ReverseMirageWrite<typeof permit3ABI, "transferBySignature">> => {
  const { request, result } = await publicClient.simulateContract({
    address: args.permit3,
    abi: permit3ABI,
    functionName: "transferBySignature",
    args: [
      args.from,
      {
        transferDetails: isILRTA(args.signatureTransfer.transferDetails)
          ? ({
              token: getAddress(
                args.signatureTransfer.transferDetails.token.address,
              ),
              tokenType: TokenTypeEnum.ILRTA,
              functionSelector: 0x811c34d3,
              transferDetails:
                args.signatureTransfer.transferDetails.transferDetails,
            } as const)
          : ({
              token: getAddress(
                args.signatureTransfer.transferDetails.token.address,
              ),
              tokenType: TokenTypeEnum.ERC20,
              functionSelector: 0x23b872dd,
              transferDetails: encodeAbiParameters(
                [{ name: "amount", type: "uint256" }],
                [args.signatureTransfer.transferDetails.amount],
              ),
            } as const),
        nonce: args.signatureTransfer.nonce,
        deadline: args.signatureTransfer.deadline,
      },
      {
        to: args.to,
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
    from: Address;
    to: Address | Address[];
    signatureTransfer: TSignatureTransferBatch;
    requestedTransfer: readonly RequestedTransfer<
      TSignatureTransferBatch["transferDetails"][number]
    >[];
    signature: Hex;
    permit3: Address;
  },
): Promise<ReverseMirageWrite<typeof permit3ABI, "transferBySignature">> => {
  if (
    typeof args.to === "object" &&
    args.to.length !== args.requestedTransfer.length
  )
    throw Error("Requested transfer length mismatch");

  const { request, result } = await publicClient.simulateContract({
    address: args.permit3,
    abi: permit3ABI,
    functionName: "transferBySignature",
    args: [
      args.from,
      {
        transferDetails: args.signatureTransfer.transferDetails.map((t) =>
          isILRTA(t)
            ? ({
                token: getAddress(t.token.address),
                tokenType: TokenTypeEnum.ILRTA,
                functionSelector: 0x811c34d3,
                transferDetails: t.transferDetails,
              } as const)
            : ({
                token: getAddress(t.token.address),
                tokenType: TokenTypeEnum.ERC20,
                functionSelector: 0x23b872dd,
                transferDetails: encodeAbiParameters(
                  [{ name: "amount", type: "uint256" }],
                  [t.amount],
                ),
              } as const),
        ),
        nonce: args.signatureTransfer.nonce,
        deadline: args.signatureTransfer.deadline,
      },
      args.requestedTransfer.map((r, i) => ({
        to: typeof args.to === "object" ? args.to[i]! : args.to,
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
    from: Address;
    to: Address;
    signatureTransfer: SignatureTransferERC20;
    requestedTransfer: RequestedTransferERC20;
    signature: Hex;
    permit3: Address;
  },
): Promise<ReverseMirageWrite<typeof permit3ABI, "transferBySignature">> => {
  const { request, result } = await publicClient.simulateContract({
    address: args.permit3,
    abi: permit3ABI,
    functionName: "transferBySignature",
    args: [
      args.from,
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
        to: args.to,
        amount: args.requestedTransfer.amount,
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
    from: Address;
    to: Address | Address[];
    signatureTransfer: SignatureTransferBatchERC20;
    requestedTransfer: readonly RequestedTransferERC20[];
    signature: Hex;
    permit3: Address;
  },
): Promise<ReverseMirageWrite<typeof permit3ABI, "transferBySignature">> => {
  if (
    typeof args.to === "object" &&
    args.to.length !== args.requestedTransfer.length
  )
    throw Error("Requested transfer length mismatch");

  const { request, result } = await publicClient.simulateContract({
    address: args.permit3,
    abi: permit3ABI,
    functionName: "transferBySignature",
    args: [
      args.from,
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
      args.requestedTransfer.map((r, i) => ({
        to: typeof args.to === "object" ? args.to[i]! : args.to,
        amount: r.amount,
      })),
      args.signature,
    ],
    account,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

export const permit3IsNonceUsed = (
  publicClient: PublicClient,
  args: { address: Address; nonce: bigint; permit3: Address },
) => {
  return {
    read: () =>
      publicClient.readContract({
        abi: permit3ABI,
        address: args.permit3,
        functionName: "nonceBitmap",
        args: [args.address, args.nonce >> 8n],
      }),
    parse: (data): boolean => (data & (1n << (args.nonce & 0xffn))) > 0n,
  } satisfies ReverseMirageRead<bigint>;
};
