import MockFungibleToken from "ilrta/out/MockFungibleToken.sol/MockFungibleToken.json";
import { readAndParse } from "reverse-mirage";
import invariant from "tiny-invariant";
import { type Hex, parseEther } from "viem";
import { foundry } from "viem/chains";
import { beforeEach, describe, expect, test } from "vitest";
import { ALICE, BOB } from "../_test/constants.js";
import { publicClient, testClient, walletClient } from "../_test/utils.js";
import { mockFungibleTokenABI } from "../generated.js";
import {
  type FungibleToken,
  fungibleTokenDataOf,
  fungibleTokenTransfer,
} from "./fungibleToken.js";

let id: Hex | undefined = undefined;
let ft: FungibleToken;

beforeEach(async () => {
  if (id === undefined) {
    // deploy tokens
    const deployHash = await walletClient.deployContract({
      account: ALICE,
      abi: mockFungibleTokenABI,
      bytecode: MockFungibleToken.bytecode.object as Hex,
    });

    const { contractAddress: mockFTAddress } =
      await publicClient.waitForTransactionReceipt({
        hash: deployHash,
      });
    invariant(mockFTAddress);

    ft = {
      type: "fungibleToken",
      decimals: 18,
      name: "Test FT",
      symbol: "TEST",
      address: mockFTAddress,
      chainID: foundry.id,
      blockCreated: 0n,
    } as const satisfies FungibleToken;

    // mint to alice
    const { request: mintRequest } = await publicClient.simulateContract({
      account: ALICE,
      abi: mockFungibleTokenABI,
      functionName: "mint",
      address: mockFTAddress,
      args: [ALICE, parseEther("1")],
    });
    const mintHash = await walletClient.writeContract(mintRequest);
    await publicClient.waitForTransactionReceipt({ hash: mintHash });
  } else {
    await testClient.revert({ id });
  }
  id = await testClient.snapshot();
}, 100_000);

describe("fungibleToken", () => {
  test("transfer", async () => {
    const { hash } = await fungibleTokenTransfer(
      publicClient,
      walletClient,
      ALICE,
      {
        to: BOB,
        transferDetails: {
          type: "fungibleTokenTransfer",
          token: ft,
          amount: parseEther("1"),
        },
      },
    );
    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("read balance", async () => {
    const balanceOfAlice = await readAndParse(
      publicClient,
      fungibleTokenDataOf(publicClient, { token: ft, owner: ALICE }),
    );
    expect(balanceOfAlice.amount).toBe(parseEther("1"));
  });
});
