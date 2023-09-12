import type { Token, TokenData } from "reverse-mirage";
import type { Address } from "viem/accounts";

export type ILRTA<TType extends string = string> = Token<TType> & {
  address: Address;
  name: String;
  symbol: String;
  blockCreated: bigint;
};

export type ILRTAData<TILRTA extends ILRTA, TData extends object> = TokenData<
  TILRTA,
  `${TILRTA["type"]}Data`,
  TData
>;

export type ILRTATransfer<
  TILRTA extends ILRTA = ILRTA,
  TData extends object = object,
> = TokenData<TILRTA, `${TILRTA["type"]}Transfer`, TData>;

export type ILRTAApproval<
  TILRTA extends ILRTA = ILRTA,
  TData extends object = object,
> = TokenData<TILRTA, `${TILRTA["type"]}Approval`, TData>;
