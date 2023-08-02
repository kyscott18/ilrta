import { getTransferTypedDataHash } from "../src/example/fungibleToken.js";
import {
  mockFungibleTokenABI,
  permit3ABI,
  transferBatchABI,
} from "../src/generated.js";
import { signSuperSignature } from "../src/superSignature.js";
import { ALICE, BOB } from "../src/test/constants.js";
import { publicClient, walletClient } from "../src/test/utils.js";
import { startProxy } from "@viem/anvil";
import MockFungibleToken from "ilrta/out/MockFungibleToken.sol/MockFungibleToken.json";
import Permit3 from "ilrta/out/Permit3.sol/Permit3.json";
import TransferBatch from "ilrta/out/TransferBatch.sol/TransferBatch.json";
import invariant from "tiny-invariant";
import { type Hex, parseEther } from "viem";
import { foundry } from "viem/chains";

const main = async () => {
  const shutdown = await startProxy({
    port: 8545, // By default, the proxy will listen on port 8545.
    host: "::", // By default, the proxy will listen on all interfaces.
  });

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

  deployHash = await walletClient.deployContract({
    account: ALICE,
    abi: transferBatchABI,
    bytecode: TransferBatch.bytecode.object as Hex,
    args: [Permit3Address],
  });

  const { contractAddress: TransferBatchAddress } =
    await publicClient.waitForTransactionReceipt({
      hash: deployHash,
    });
  invariant(TransferBatchAddress);

  // deploy token
  deployHash = await walletClient.deployContract({
    account: ALICE,
    abi: mockFungibleTokenABI,
    bytecode: MockFungibleToken.bytecode.object as Hex,
    args: [Permit3Address],
  });

  const { contractAddress: mockFTAddress1 } =
    await publicClient.waitForTransactionReceipt({
      hash: deployHash,
    });
  invariant(mockFTAddress1);

  const ft_1 = {
    type: "fungibleToken",
    chainID: foundry.id,
    decimals: 18,
    name: "Test FT",
    symbol: "TEST",
    address: mockFTAddress1,
    id: "0x0000000000000000000000000000000000000000000000000000000000000000",
  } as const;

  deployHash = await walletClient.deployContract({
    account: ALICE,
    abi: mockFungibleTokenABI,
    bytecode: MockFungibleToken.bytecode.object as Hex,
    args: [Permit3Address],
  });

  const { contractAddress: mockFTAddress2 } =
    await publicClient.waitForTransactionReceipt({
      hash: deployHash,
    });
  invariant(mockFTAddress2);

  const ft_2 = {
    type: "fungibleToken",
    chainID: foundry.id,
    decimals: 18,
    name: "Test FT",
    symbol: "TEST",
    address: mockFTAddress2,
    id: "0x0000000000000000000000000000000000000000000000000000000000000000",
  } as const;

  // mint token
  const { request: mintRequest1 } = await publicClient.simulateContract({
    account: ALICE,
    abi: mockFungibleTokenABI,
    functionName: "mint",
    address: mockFTAddress1,
    args: [ALICE, parseEther("1")],
  });
  let mintHash = await walletClient.writeContract(mintRequest1);
  await publicClient.waitForTransactionReceipt({ hash: mintHash });

  const { request: mintRequest2 } = await publicClient.simulateContract({
    account: ALICE,
    abi: mockFungibleTokenABI,
    functionName: "mint",
    address: mockFTAddress2,
    args: [ALICE, parseEther("1")],
  });
  mintHash = await walletClient.writeContract(mintRequest2);
  await publicClient.waitForTransactionReceipt({ hash: mintHash });

  // sign
  const hash1 = getTransferTypedDataHash(foundry.id, {
    transferDetails: {
      type: "fungibleTokenTransfer",
      ilrta: ft_1,
      amount: parseEther("1"),
    },
    spender: TransferBatchAddress,
  });
  const hash2 = getTransferTypedDataHash(foundry.id, {
    transferDetails: {
      type: "fungibleTokenTransfer",
      ilrta: ft_2,
      amount: parseEther("1"),
    },
    spender: TransferBatchAddress,
  });
  const block = await publicClient.getBlock();

  const verify = {
    dataHash: [hash1, hash2],
    nonce: 0n,
    deadline: block.timestamp + 1000n,
  } as const;

  const signature = await signSuperSignature(walletClient, ALICE, verify);

  // transfer
  const { request } = await publicClient.simulateContract({
    abi: transferBatchABI,
    address: TransferBatchAddress,
    functionName: "transferBatch",
    account: ALICE,
    args: [
      ALICE,
      [ft_1.address, ft_2.address],
      [{ amount: parseEther("1") }, { amount: parseEther("1") }],
      [
        { to: BOB, transferDetails: { amount: parseEther("0.5") } },
        { to: BOB, transferDetails: { amount: parseEther("0.5") } },
      ],
      0n,
      block.timestamp + 1000n,
      signature,
    ],
  });
  const hash = await walletClient.writeContract(request);
  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  console.log("gas used:", receipt.cumulativeGasUsed);

  await shutdown();
};

main().catch((err) => console.error(err));
