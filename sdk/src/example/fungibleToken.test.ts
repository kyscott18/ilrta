import MockFungibleToken from "../../node_modules/ilrta-evm/out/MockFungibleToken.sol/MockFungibleToken.json";
import Permit3 from "../../node_modules/ilrta-evm/out/Permit3.sol/Permit3.json";
import { mockFungibleTokenABI, permit3ABI } from "../generated.js";
import { ALICE, BOB } from "../test/constants.js";
import { publicClient, testClient, walletClient } from "../test/utils.js";
import {
  type FungibleToken,
  signTransfer,
  transfer,
  transferBySignature,
} from "./fungibleToken.js";
import invariant from "tiny-invariant";
import { type Hex, parseEther } from "viem";
import { afterAll, beforeAll, beforeEach, describe, test } from "vitest";

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
    name: "Mock ERC20",
    symbol: "MOCK",
    address: mockFTAddress,
    id: "0x",
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

    // should the signature just be bytes?
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

  test.todo("transfer by super signature");

  test.todo("read data");
});
