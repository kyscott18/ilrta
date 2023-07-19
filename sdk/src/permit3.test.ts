import MockERC20 from "../../ilrta-evm/lib/solmate/out/MockERC20.sol/MockERC20.json";
import Permit3 from "../../ilrta-evm/out/Permit3.sol/Permit3.json";
import { Permit3Address } from "./constants.js";
import {
  permit3ABI,
  solmateMockErc20ABI,
  superSignatureABI,
} from "./generated.js";
import {
  getTransferBatchTypedDataHash,
  getTransferTypedDataHash,
  permit3SignTransfer,
  permit3SignTransferBatch,
  permit3TransferBatchBySignature,
  permit3TransferBySignature,
} from "./permit3.js";
import { signSuperSignature } from "./superSignature.js";
import { ALICE, BOB } from "./test/constants.js";
import { anvil, publicClient, testClient, walletClient } from "./test/utils.js";
import { type Token, makeCurrencyAmountFromString } from "reverse-mirage";
import invariant from "tiny-invariant";
import { type Hex, getAddress, parseEther } from "viem";
import { afterAll, beforeAll, beforeEach, describe, test } from "vitest";

let id: Hex;
let mockERC20_1: Token;
let mockERC20_2: Token;

beforeAll(async () => {
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
    abi: solmateMockErc20ABI,
    bytecode: MockERC20.bytecode.object as Hex,
    args: ["Mock ERC20", "MOCK", 18],
  });

  const { contractAddress: mockERC20Address1 } =
    await publicClient.waitForTransactionReceipt({
      hash: deployHash,
    });
  invariant(mockERC20Address1);

  mockERC20_1 = {
    type: "token",
    decimals: 18,
    name: "Mock ERC20",
    symbol: "MOCK",
    chainID: anvil.id,
    address: mockERC20Address1,
  };
  deployHash = await walletClient.deployContract({
    account: ALICE,
    abi: solmateMockErc20ABI,
    bytecode: MockERC20.bytecode.object as Hex,
    args: ["Mock ERC20", "MOCK", 18],
  });

  const { contractAddress: mockERC20Address2 } =
    await publicClient.waitForTransactionReceipt({
      hash: deployHash,
    });
  invariant(mockERC20Address2);

  mockERC20_2 = {
    type: "token",
    decimals: 18,
    name: "Mock ERC20",
    symbol: "MOCK",
    chainID: anvil.id,
    address: mockERC20Address2,
  };

  // mint to alice
  let mintHash = await walletClient.writeContract({
    abi: solmateMockErc20ABI,
    functionName: "mint",
    address: mockERC20Address1,
    args: [ALICE, parseEther("1")],
  });
  await publicClient.waitForTransactionReceipt({ hash: mintHash });

  mintHash = await walletClient.writeContract({
    abi: solmateMockErc20ABI,
    functionName: "mint",
    address: mockERC20Address2,
    args: [ALICE, parseEther("1")],
  });
  await publicClient.waitForTransactionReceipt({ hash: mintHash });

  // approve permit3
  let approveHash = await walletClient.writeContract({
    abi: solmateMockErc20ABI,
    functionName: "approve",
    address: mockERC20Address1,
    args: [Permit3Address, parseEther("1")],
  });
  await publicClient.waitForTransactionReceipt({ hash: approveHash });

  approveHash = await walletClient.writeContract({
    abi: solmateMockErc20ABI,
    functionName: "approve",
    address: mockERC20Address2,
    args: [Permit3Address, parseEther("1")],
  });
  await publicClient.waitForTransactionReceipt({ hash: approveHash });
}, 100_000);

beforeEach(async () => {
  if (id !== undefined) await testClient.revert({ id });
  id = await testClient.snapshot();
});

afterAll(async () => {
  await testClient.reset();
});

describe("permit 3", () => {
  test("transfer by signature", async () => {
    const block = await publicClient.getBlock();
    const transfer = {
      transferDetails: makeCurrencyAmountFromString(mockERC20_1, "1"),
      spender: ALICE,
      nonce: 0n,
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
        requestedTransfer: { to: BOB, amount: transfer.transferDetails },
        signature,
      },
    );
    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("transfer batch by signature", async () => {
    const block = await publicClient.getBlock();
    const transfer = {
      transferDetails: [
        makeCurrencyAmountFromString(mockERC20_1, "1"),
        makeCurrencyAmountFromString(mockERC20_2, "1"),
      ],
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
        requestedTransfer: transfer.transferDetails.map((t) => ({
          to: BOB,
          amount: t,
        })),
        signature,
      },
    );
    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("transfer by super signature", async () => {
    const block = await publicClient.getBlock();
    const transfer = {
      transferDetails: makeCurrencyAmountFromString(mockERC20_1, "1"),
      spender: ALICE,
      nonce: 0n,
      deadline: block.timestamp + 100n,
    } as const;

    const dataHash = getTransferTypedDataHash(1, transfer);

    const verify = {
      dataHash: [dataHash],
      deadline: block.timestamp + 100n,
      nonce: 0n,
    } as const;

    const signature = await signSuperSignature(walletClient, ALICE, verify);

    let hash = await walletClient.writeContract({
      abi: superSignatureABI,
      address: Permit3Address,
      functionName: "verifyAndStoreRoot",
      args: [ALICE, verify, signature],
    });
    await publicClient.waitForTransactionReceipt({ hash });

    hash = await walletClient.writeContract({
      abi: permit3ABI,
      functionName: "transferBySuperSignature",
      address: Permit3Address,
      args: [
        ALICE,
        {
          token: getAddress(transfer.transferDetails.currency.address),
          amount: transfer.transferDetails.amount,
        },
        { to: BOB, amount: transfer.transferDetails.amount },
        [dataHash],
      ],
    });
    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("transfer batch by super signature", async () => {
    const block = await publicClient.getBlock();
    const transfer = {
      transferDetails: [
        makeCurrencyAmountFromString(mockERC20_1, "1"),
        makeCurrencyAmountFromString(mockERC20_2, "1"),
      ],
      spender: ALICE,
      nonce: 0n,
      deadline: block.timestamp + 100n,
    } as const;

    const dataHash = getTransferBatchTypedDataHash(1, transfer);

    const verify = {
      dataHash: [dataHash],
      deadline: block.timestamp + 100n,
      nonce: 0n,
    } as const;

    const signature = await signSuperSignature(walletClient, ALICE, verify);

    let hash = await walletClient.writeContract({
      abi: superSignatureABI,
      address: Permit3Address,
      functionName: "verifyAndStoreRoot",
      args: [ALICE, verify, signature],
    });
    await publicClient.waitForTransactionReceipt({ hash });

    hash = await walletClient.writeContract({
      abi: permit3ABI,
      functionName: "transferBySuperSignature",
      address: Permit3Address,
      args: [
        ALICE,
        transfer.transferDetails.map((t) => ({
          token: getAddress(t.currency.address),
          amount: t.amount,
        })),
        transfer.transferDetails.map((t) => ({
          to: BOB,
          amount: t.amount,
        })),
        [dataHash],
      ],
    });
    await publicClient.waitForTransactionReceipt({ hash });
  });
});
