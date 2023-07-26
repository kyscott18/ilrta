import { Permit3Address } from "./constants.js";
import { permit3ABI } from "./generated.js";
import type { ERC20, ERC20Amount, ReverseMirageWrite } from "reverse-mirage";
import invariant from "tiny-invariant";
import {
  type Account,
  type Address,
  type Hex,
  type PublicClient,
  type WalletClient,
  getAddress,
  hashTypedData,
} from "viem";

export type SignatureTransfer = {
  transferDetails: ERC20Amount<ERC20>;
  nonce: bigint;
  deadline: bigint;
};

export type SignatureTransferBatch = {
  transferDetails: readonly ERC20Amount<ERC20>[];
  nonce: bigint;
  deadline: bigint;
};

export type RequestedTransfer = {
  to: Address;
  amount: Pick<ERC20Amount<ERC20>, "amount">;
};

export const TransferDetails = [
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
  TransferDetails,
} as const;

export const TransferBatch = {
  Transfer: [
    { name: "transferDetails", type: "TransferDetails[]" },
    { name: "spender", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
  TransferDetails,
} as const;

export const SuperSignatureTransfer = {
  Transfer: [
    { name: "transferDetails", type: "TransferDetails" },
    { name: "spender", type: "address" },
  ],
  TransferDetails,
} as const;

export const SuperSignatureTransferBatch = {
  Transfer: [
    { name: "transferDetails", type: "TransferDetails[]" },
    { name: "spender", type: "address" },
  ],
  TransferDetails,
} as const;

export const getTransferTypedDataHash = (
  chainID: number,
  transfer: { transferDetails: ERC20Amount<ERC20>; spender: Address },
): Hex => {
  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: Permit3Address,
  } as const;

  return hashTypedData({
    domain,
    types: SuperSignatureTransfer,
    primaryType: "Transfer",
    message: {
      transferDetails: {
        token: transfer.transferDetails.token.address,
        amount: transfer.transferDetails.amount,
      },
      spender: transfer.spender,
    },
  });
};

export const getTransferBatchTypedDataHash = (
  chainID: number,
  transfers: {
    transferDetails: readonly ERC20Amount<ERC20>[];
    spender: Address;
  },
) => {
  const domain = {
    name: "Permit3",
    version: "1",
    chainId: chainID,
    verifyingContract: Permit3Address,
  } as const;

  return hashTypedData({
    domain,
    types: SuperSignatureTransferBatch,
    primaryType: "Transfer",
    message: {
      transferDetails: transfers.transferDetails.map((c) => ({
        token: c.token.address,
        amount: c.amount,
      })),
      spender: transfers.spender,
    },
  });
};

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
      transferDetails: {
        token: getAddress(transfer.transferDetails.token.address),
        amount: transfer.transferDetails.amount,
      },
      spender: transfer.spender,
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
      transferDetails: transfers.transferDetails.map((c) => ({
        token: c.token.address,
        amount: c.amount,
      })),
      spender: transfers.spender,
      nonce: transfers.nonce,
      deadline: transfers.deadline,
    },
  });
};

export const permit3TransferBySignature = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: {
    signer: Address;
    signatureTransfer: SignatureTransfer;
    requestedTransfer: RequestedTransfer;
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
        },
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

export const permit3TransferBatchBySignature = async (
  publicClient: PublicClient,
  walletClient: WalletClient,
  account: Account | Address,
  args: {
    signer: Address;
    signatureTransfer: SignatureTransferBatch;
    requestedTransfer: readonly RequestedTransfer[];
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
        transferDetails: args.signatureTransfer.transferDetails.map((t) => ({
          token: t.token.address,
          amount: t.amount,
        })),
        nonce: args.signatureTransfer.nonce,
        deadline: args.signatureTransfer.deadline,
      },
      args.requestedTransfer.map((t) => ({
        to: t.to,
        amount: t.amount.amount,
      })),
      args.signature,
    ],
    account,
  });
  const hash = await walletClient.writeContract(request);
  return { hash, result, request };
};

// TODO: is nonce used
