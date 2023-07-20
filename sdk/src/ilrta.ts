import type { AbiParameter } from "abitype";
import { type Hex } from "viem";
import type { Address } from "viem/accounts";

export type ILRTA = {
  name: string;
  symbol: string;
  address: Address;
  id: Hex;
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
