import { Permit3Address } from "../constants.js";
import {
  ilrtaFungibleTokenABI,
  mockFungibleTokenABI,
  permit3ABI,
  superSignatureABI,
} from "../generated.js";
import { signSuperSignature } from "../superSignature.js";
import { ALICE, BOB } from "../test/constants.js";
import {
  anvil,
  publicClient,
  testClient,
  walletClient,
} from "../test/utils.js";
import {
  type FungibleToken,
  dataOf,
  getTransferTypedDataHash,
  signTransfer,
  transfer,
  transferBySignature,
} from "./fungibleToken.js";
import MockFungibleToken from "ilrta/out/MockFungibleToken.sol/MockFungibleToken.json";
import Permit3 from "ilrta/out/Permit3.sol/Permit3.json";
import { readAndParse } from "reverse-mirage";
import invariant from "tiny-invariant";
import { type Hex, parseEther } from "viem";
import { foundry } from "viem/chains";
import { beforeEach, describe, expect, test } from "vitest";

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
      args: [Permit3Address],
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
      id: "0x0000000000000000000000000000000000000000000000000000000000000000",
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

  test("transfer by signature", async () => {
    const block = await publicClient.getBlock();

    const signatureTransfer = {
      transferDetails: {
        type: "fungibleTokenTransfer",
        ilrta: ft,
        amount: parseEther("1"),
      },
      nonce: 0n,
      deadline: block.timestamp + 100n,
      spender: ALICE,
    } as const;

    const signature = await signTransfer(
      walletClient,
      ALICE,
      signatureTransfer,
    );

    const { hash } = await transferBySignature(
      publicClient,
      walletClient,
      ALICE,
      {
        signer: ALICE,
        signatureTransfer,
        requestedTransfer: {
          to: BOB,
          transferDetails: signatureTransfer.transferDetails,
        },
        signature,
      },
    );
    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("transfer by super signature", async () => {
    const block = await publicClient.getBlock();

    const transferDetails = {
      type: "fungibleTokenTransfer",
      ilrta: ft,
      amount: parseEther("1"),
    } as const;

    const dataHash = getTransferTypedDataHash(anvil.id, {
      transferDetails,
      spender: ALICE,
    });

    const verify = {
      dataHash: [dataHash],
      deadline: block.timestamp + 100n,
      nonce: 0n,
    } as const;

    const signature = await signSuperSignature(walletClient, ALICE, verify);

    const { request: verifyAndStoreRequest } =
      await publicClient.simulateContract({
        account: ALICE,
        abi: superSignatureABI,
        address: Permit3Address,
        functionName: "verifyAndStoreRoot",
        args: [ALICE, verify, signature],
      });

    let hash = await walletClient.writeContract(verifyAndStoreRequest);
    await publicClient.waitForTransactionReceipt({ hash });

    const { request: transferBySigRequest } =
      await publicClient.simulateContract({
        abi: ilrtaFungibleTokenABI,
        functionName: "transferBySuperSignature",
        address: ft.address,
        account: ALICE,
        args: [
          ALICE,
          {
            amount: transferDetails.amount,
          },
          { to: BOB, transferDetails: { amount: transferDetails.amount } },
          [dataHash],
        ],
      });

    hash = await walletClient.writeContract(transferBySigRequest);
    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("read data", async () => {
    const balanceOfAlice = await readAndParse(
      dataOf(publicClient, { ilrta: ft, owner: ALICE }),
    );
    expect(balanceOfAlice.balance).toBe(parseEther("1"));
  });
});
