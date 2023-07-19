import { Permit3Address } from "./constants.js";
import { VerifyType, signSuperSignature } from "./superSignature.js";
import { ALICE } from "./test/constants.js";
import { anvil, walletClient } from "./test/utils.js";
import { hashTypedData, keccak256, recoverAddress } from "viem";
import { describe, expect, test } from "vitest";

describe("super signature", () => {
  test("sign", async () => {
    const domain = {
      name: "SuperSignature",
      version: "1",
      chainId: anvil.id,
      verifyingContract: Permit3Address,
    } as const;

    const verify = {
      dataHash: [keccak256("0x")],
      deadline: 0n,
      nonce: 0n,
    } as const;

    const hash = hashTypedData({
      domain,
      types: VerifyType,
      primaryType: "Verify",
      message: verify,
    });
    const signature = await signSuperSignature(walletClient, ALICE, verify);
    const address = await recoverAddress({ hash, signature });
    expect(address).toBe(ALICE);
  });
});
