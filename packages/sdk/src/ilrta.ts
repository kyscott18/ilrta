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

export type ILRTAApprovalDetails<
  TILRTA extends ILRTA = ILRTA,
  TData extends object = object,
> = {
  type: `${TILRTA["type"]}Approval`;
  ilrta: TILRTA;
} & TData;
