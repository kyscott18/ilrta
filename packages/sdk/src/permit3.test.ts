import Permit3 from "ilrta/out/Permit3.sol/Permit3.json";
import { type ERC20, createAmountFromString } from "reverse-mirage";
import invariant from "tiny-invariant";
import { type Hex, getAddress, parseEther } from "viem";
import { beforeEach, describe, test } from "vitest";
import MockERC20 from "../../../lib/solmate/out/MockERC20.sol/MockERC20.json";
import { permit3ABI, solmateMockErc20ABI } from "./generated.js";
import {
  permit3SignTransfer,
  permit3SignTransferBatch,
  permit3SignTransferBatchERC20,
  permit3SignTransferERC20,
  permit3TransferBatchBySignature,
  permit3TransferBatchERC20BySignature,
  permit3TransferBySignature,
  permit3TransferERC20BySignature,
} from "./permit3.js";
import { ALICE, BOB } from "./test/constants.js";
import { anvil, publicClient, testClient, walletClient } from "./test/utils.js";

let id: Hex | undefined = undefined;
let mockERC20: ERC20;

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
    console.log("permit3 address:", getAddress(Permit3Address));

    // deploy tokens
    deployHash = await walletClient.deployContract({
      account: ALICE,
      abi: solmateMockErc20ABI,
      bytecode: MockERC20.bytecode.object as Hex,
      args: ["Mock ERC20", "MOCK", 18],
    });

    const { contractAddress: mockERC20Address } =
      await publicClient.waitForTransactionReceipt({
        hash: deployHash,
      });
    invariant(mockERC20Address);

    mockERC20 = {
      type: "erc20",
      decimals: 18,
      name: "Mock ERC20",
      symbol: "MOCK",
      chainID: anvil.id,
      address: mockERC20Address,
    };

    // mint to alice
    const { request: mintRequest1 } = await publicClient.simulateContract({
      abi: solmateMockErc20ABI,
      functionName: "mint",
      address: mockERC20Address,
      args: [ALICE, parseEther("4")],
      account: ALICE,
    });
    const mintHash1 = await walletClient.writeContract(mintRequest1);
    await publicClient.waitForTransactionReceipt({ hash: mintHash1 });

    // approve permit3
    const { request: approveRequest1 } = await publicClient.simulateContract({
      abi: solmateMockErc20ABI,
      functionName: "approve",
      address: mockERC20Address,
      args: [Permit3Address, parseEther("4")],
      account: ALICE,
    });
    const approveHash1 = await walletClient.writeContract(approveRequest1);
    await publicClient.waitForTransactionReceipt({ hash: approveHash1 });
  } else {
    await testClient.revert({ id });
  }
  id = await testClient.snapshot();
}, 100_000);

describe("permit 3", () => {
  test.todo("transfer by signature", async () => {
    const block = await publicClient.getBlock();
    const transfer = {
      transferDetails: createAmountFromString(mockERC20, "1"),
      spender: ALICE,
      nonce: 5n,
      deadline: block.timestamp + 100n,
    } as const;

    const signature = await permit3SignTransfer(walletClient, ALICE, transfer);

    const { hash } = await permit3TransferBySignature(
      publicClient,
      walletClient,
      ALICE,
      {
        signer: ALICE,
        signatureTransfer: transfer,
        requestedTransfer: {
          to: BOB,
          amount: transfer.transferDetails.amount,
        },
        signature,
      },
    );

    await publicClient.waitForTransactionReceipt({ hash });
  });

  test.todo("transfer batch by signature", async () => {
    const block = await publicClient.getBlock();
    const transfer = {
      transferDetails: [
        createAmountFromString(mockERC20, "0.5"),
        createAmountFromString(mockERC20, "0.5"),
      ] as const,
      spender: ALICE,
      nonce: 0n,
      deadline: block.timestamp + 100n,
    } as const;

    const signature = await permit3SignTransferBatch(
      walletClient,
      ALICE,
      transfer,
    );

    const { hash } = await permit3TransferBatchBySignature(
      publicClient,
      walletClient,
      ALICE,
      {
        signer: ALICE,
        signatureTransfer: transfer,
        requestedTransfer: [
          {
            to: BOB,
            amount: transfer.transferDetails[0].amount,
          },
          {
            to: BOB,
            amount: transfer.transferDetails[1].amount,
          },
        ],
        signature,
      },
    );

    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("transfer by signature erc20", async () => {
    const block = await publicClient.getBlock();
    const transfer = {
      transferDetails: createAmountFromString(mockERC20, "1"),
      spender: ALICE,
      nonce: 0n,
      deadline: block.timestamp + 100n,
    } as const;

    const signature = await permit3SignTransferERC20(
      walletClient,
      ALICE,
      transfer,
    );

    const { hash } = await permit3TransferERC20BySignature(
      publicClient,
      walletClient,
      ALICE,
      {
        signer: ALICE,
        signatureTransfer: transfer,
        requestedTransfer: {
          to: BOB,
          amount: { amount: transfer.transferDetails.amount },
        },
        signature,
      },
    );

    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("transfer batch by signature erc20", async () => {
    const block = await publicClient.getBlock();
    const transfer = {
      transferDetails: [
        createAmountFromString(mockERC20, "0.5"),
        createAmountFromString(mockERC20, "0.5"),
      ],
      spender: ALICE,
      nonce: 0n,
      deadline: block.timestamp + 100n,
    } as const;

    const signature = await permit3SignTransferBatchERC20(
      walletClient,
      ALICE,
      transfer,
    );

    const { hash } = await permit3TransferBatchERC20BySignature(
      publicClient,
      walletClient,
      ALICE,
      {
        signer: ALICE,
        signatureTransfer: transfer,
        requestedTransfer: [
          {
            to: BOB,
            amount: { amount: transfer.transferDetails[0].amount },
          },
          {
            to: BOB,
            amount: { amount: transfer.transferDetails[1].amount },
          },
        ],
        signature,
      },
    );

    await publicClient.waitForTransactionReceipt({ hash });
  });
});
