import MockFungibleToken from "../node_modules/ilrta-evm/out/MockFungibleToken.sol/MockFungibleToken.json";
import Permit3 from "../node_modules/ilrta-evm/out/Permit3.sol/Permit3.json";
import TransferBatch from "../node_modules/ilrta-evm/out/TransferBatch.sol/TransferBatch.json";
import {
  getTransferTypedDataHash,
  signTransfer,
  transferBySignature,
} from "../src/example/fungibleToken";
import {
  mockFungibleTokenABI,
  permit3ABI,
  transferBatchABI,
} from "../src/generated";
import { signSuperSignature } from "../src/superSignature";
import { ALICE, BOB, forkBlockNumber, forkUrl } from "../src/test/constants";
import { publicClient, walletClient } from "../src/test/utils";
import { startProxy } from "@viem/anvil";
import invariant from "tiny-invariant";
import { Hex, parseEther, zeroAddress } from "viem";

const main = async () => {
  const shutdown = await startProxy({
    port: 8545, // By default, the proxy will listen on port 8545.
    host: "::", // By default, the proxy will listen on all interfaces.
    options: {
      chainId: 1,
      forkUrl,
      forkBlockNumber,
    },
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
    args: [zeroAddress],
  });

  const { contractAddress: mockFTAddress1 } =
    await publicClient.waitForTransactionReceipt({
      hash: deployHash,
    });
  invariant(mockFTAddress1);

  const ft_1 = {
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
    args: [zeroAddress],
  });

  const { contractAddress: mockFTAddress2 } =
    await publicClient.waitForTransactionReceipt({
      hash: deployHash,
    });
  invariant(mockFTAddress2);

  const ft_2 = {
    decimals: 18,
    name: "Test FT",
    symbol: "TEST",
    address: mockFTAddress2,
    id: "0x0000000000000000000000000000000000000000000000000000000000000000",
  } as const;

  // mint token
  let mintHash = await walletClient.writeContract({
    abi: mockFungibleTokenABI,
    functionName: "mint",
    address: mockFTAddress1,
    args: [ALICE, parseEther("1")],
  });
  await publicClient.waitForTransactionReceipt({ hash: mintHash });

  mintHash = await walletClient.writeContract({
    abi: mockFungibleTokenABI,
    functionName: "mint",
    address: mockFTAddress2,
    args: [ALICE, parseEther("1")],
  });
  await publicClient.waitForTransactionReceipt({ hash: mintHash });

  // sign
  const hash1 = getTransferTypedDataHash(1, {
    transferDetails: { ilrta: ft_1, data: { amount: parseEther("1") } },
    spender: ALICE,
  });
  const hash2 = getTransferTypedDataHash(1, {
    transferDetails: { ilrta: ft_2, data: { amount: parseEther("1") } },
    spender: ALICE,
  });
  const block = await publicClient.getBlock();

  const verify = {
    dataHash: [hash1, hash2],
    nonce: 0n,
    deadline: block.timestamp + 100n,
  } as const;

  const signature = await signSuperSignature(walletClient, ALICE, verify);

  // transfer
  const { request } = await publicClient.simulateContract({
    abi: transferBatchABI,
    address: TransferBatchAddress,
    functionName: "transferBatch",
    args: [
      ALICE,
      [ft_1.address, ft_2.address],
      [{ amount: parseEther("1") }, { amount: parseEther("1") }],
      [
        { to: BOB, transferDetails: { amount: parseEther("0.5") } },
        { to: BOB, transferDetails: { amount: parseEther("0.5") } },
      ],
      0n,
      block.timestamp + 100n,
      signature,
    ],
  });
  const hash = await walletClient.writeContract(request);
  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  console.log("gas used:", receipt.cumulativeGasUsed);

  await shutdown();
};

main().catch((err) => console.error(err));
