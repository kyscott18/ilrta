import { Permit3Address } from "./constants.js";
import invariant from "tiny-invariant";
import {
  keccak256,
  type Account,
  type Address,
  type Hex,
  type WalletClient,
  encodePacked,
  type Hash,
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
    name: "SuperSignature",
    version: "1",
    chainId: chainID,
    verifyingContract: Permit3Address,
  } as const;

  return await walletClient.signTypedData({
    domain,
    account,
    types: VerifyType,
    primaryType: "Verify",
    message: verify,
  });
};

export const calculateRoot = (signer: Address, dataHash: readonly Hash[]) =>
  keccak256(encodePacked(["address", "bytes32[]"], [signer, dataHash]));
