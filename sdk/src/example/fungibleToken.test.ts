import MockFungibleToken from "../../node_modules/ilrta-evm/out/MockFungibleToken.sol/MockFungibleToken.json";
import Permit3 from "../../node_modules/ilrta-evm/out/Permit3.sol/Permit3.json";
import { Permit3Address } from "../constants";
import {
  ilrtaFungibleTokenABI,
  mockFungibleTokenABI,
  permit3ABI,
  superSignatureABI,
} from "../generated.js";
import { signSuperSignature } from "../superSignature";
import { ALICE, BOB } from "../test/constants.js";
import { publicClient, testClient, walletClient } from "../test/utils.js";
import {
  type FungibleToken,
  dataOf,
  getTransferTypedDataHash,
  signTransfer,
  transfer,
  transferBySignature,
} from "./fungibleToken.js";
import { readAndParse } from "reverse-mirage";
import invariant from "tiny-invariant";
import { type Hex, getAddress, parseEther } from "viem";
import {
  afterAll,
  beforeAll,
  beforeEach,
  describe,
  expect,
  test,
} from "vitest";

let id: Hex;
let ft: FungibleToken;

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
    decimals: 18,
    name: "Test FT",
    symbol: "TEST",
    address: mockFTAddress,
    id: "0x0000000000000000000000000000000000000000000000000000000000000000",
  } as const;

  // mint to alice
  const mintHash = await walletClient.writeContract({
    abi: mockFungibleTokenABI,
    functionName: "mint",
    address: mockFTAddress,
    args: [ALICE, parseEther("1")],
  });
  await publicClient.waitForTransactionReceipt({ hash: mintHash });
}, 100_000);

beforeEach(async () => {
  if (id !== undefined) await testClient.revert({ id });
  id = await testClient.snapshot();
});

afterAll(async () => {
  await testClient.reset();
});

describe("fungible token", () => {
  test("transfer", async () => {
    const { hash } = await transfer(publicClient, walletClient, ALICE, {
      to: BOB,
      transferDetails: { ilrta: ft, data: { amount: parseEther("1") } },
    });
    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("transfer by signature", async () => {
    const block = await publicClient.getBlock();

    const signatureTransfer = {
      transferDetails: { ilrta: ft, data: { amount: parseEther("1") } },
      nonce: 0n,
      deadline: block.timestamp + 100n,
      spender: ALICE,
    };

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

    const transferDetails = { ilrta: ft, data: { amount: parseEther("1") } };

    const dataHash = getTransferTypedDataHash(1, {
      transferDetails,
      spender: ALICE,
    });

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
      abi: ilrtaFungibleTokenABI,
      functionName: "transferBySuperSignature",
      address: ft.address,
      args: [
        ALICE,
        {
          amount: transferDetails.data.amount,
        },
        { to: BOB, transferDetails: { amount: transferDetails.data.amount } },
        [dataHash],
      ],
    });
    await publicClient.waitForTransactionReceipt({ hash });
  });

  test("read data", async () => {
    const balanceOfAlice = await readAndParse(
      dataOf(publicClient, { ilrta: ft, owner: ALICE }),
    );
    expect(balanceOfAlice.data.balance).toBe(parseEther("1"));
  });
});
