import type { AbiParameter } from "abitype";
import type { Token, TokenData } from "reverse-mirage";
import { type Hex } from "viem";
import type { Address } from "viem/accounts";

export type ILRTA<TType extends string = string> = Token<TType> & {
  address: Address;
  id: Hex;
};

export type ILRTAData<TILRTA extends ILRTA, TData extends object> = TokenData<
  TILRTA,
  TData
> & {
  type: `${TILRTA["type"]}Data`;
};

export type ILRTATransferDetails<
  TILRTA extends ILRTA = ILRTA,
  TData extends object = object,
> = {
  type: `${TILRTA["type"]}Transfer`;
  ilrta: TILRTA;
} & TData;

export type ILRTASignatureTransfer<
  TTransferDetails extends ILRTATransferDetails,
> = {
  nonce: bigint;
  deadline: bigint;
  transferDetails: TTransferDetails;
};

export type ILRTARequestedTransfer<
  TTransferDetails extends ILRTATransferDetails,
> = {
  to: Address;
  transferDetails: TTransferDetails;
};

export const ILRTATransfer = <TTransferDetails extends readonly AbiParameter[]>(
  transferDetails: TTransferDetails,
) =>
  ({
    Transfer: [
      { name: "transferDetails", type: "TransferDetails" },
      { name: "spender", type: "address" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
    TransferDetails: transferDetails,
  }) as const;

export const ILRTASuperSignatureTransfer = <
  TTransferDetails extends readonly AbiParameter[],
>(
  transferDetails: TTransferDetails,
) =>
  ({
    Transfer: [
      { name: "transferDetails", type: "TransferDetails" },
      { name: "spender", type: "address" },
    ],
    TransferDetails: transferDetails,
  }) as const;
