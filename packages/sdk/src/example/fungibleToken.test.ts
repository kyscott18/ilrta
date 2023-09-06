import MockFungibleToken from "ilrta/out/MockFungibleToken.sol/MockFungibleToken.json";
import Permit3 from "ilrta/out/Permit3.sol/Permit3.json";
import { readAndParse } from "reverse-mirage";
import invariant from "tiny-invariant";
import { type Hex, parseEther } from "viem";
import { foundry } from "viem/chains";
import { beforeEach, describe, expect, test } from "vitest";
import { mockFungibleTokenABI, permit3ABI } from "../generated.js";
import { ALICE, BOB } from "../test/constants.js";
import { publicClient, testClient, walletClient } from "../test/utils.js";
import { type FungibleToken, dataOf, transfer } from "./fungibleToken.js";

let id: Hex | undefined = undefined;
let ft: FungibleToken;

beforeEach(async () => {
  if (id === undefined) {
    // deploy permit3
    let deployHash = await walletClient.deployContract({
      account: ALICE,
      abi: permit3ABI,
      bytecode: Permit3.bytecode.object as Hex,
    });

    const { contractAddress: Permit3Address } =
      await publicClient.waitForTransactionReceipt({
        hash: deployHash,
      });
    invariant(Permit3Address);
    console.log("permit3 address:", Permit3Address);

    // deploy tokens
    deployHash = await walletClient.deployContract({
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
    } as const;

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
    const { hash } = await transfer(publicClient, walletClient, ALICE, {
      to: BOB,
      transferDetails: {
        type: "fungibleTokenTransfer",
        ilrta: ft,
        amount: parseEther("1"),
      },
    });
    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("read balance", async () => {
    const balanceOfAlice = await readAndParse(
      dataOf(publicClient, { ilrta: ft, owner: ALICE }),
    );
    expect(balanceOfAlice.balance).toBe(parseEther("1"));
  });
});
