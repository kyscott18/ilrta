import { Permit3Address } from "./constants.js";
import invariant from "tiny-invariant";
import {
  type Account,
  type Address,
  type Hash,
  type Hex,
  type WalletClient,
  encodePacked,
  keccak256,
} from "viem";

export const VerifyType = {
  Verify: [
    {
      name: "dataHash",
      type: "bytes32[]",
    },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" },
  ],
} as const;

export const signSuperSignature = async (
  walletClient: WalletClient,
  account: Account | Address,
  verify: {
    dataHash: readonly Hex[];
    nonce: bigint;
    deadline: bigint;
  },
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
    types: VerifyType,
    primaryType: "Verify",
    message: verify,
  });
};

export const calculateRoot = (signer: Address, dataHash: readonly Hash[]) =>
  keccak256(encodePacked(["address", "bytes32[]"], [signer, dataHash]));
