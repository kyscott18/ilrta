import MockERC20 from "../node_modules/ilrta-evm/lib/solmate/out/MockERC20.sol/MockERC20.json";
import Permit3 from "../node_modules/ilrta-evm/out/Permit3.sol/Permit3.json";
import { permit3ABI, solmateMockErc20ABI } from "../src/generated.js";
import {
  permit3SignTransferBatch,
  permit3TransferBatchBySignature,
} from "../src/permit3.js";
import { ALICE, BOB, forkBlockNumber, forkUrl } from "../src/test/constants.js";
import { anvil, publicClient, walletClient } from "../src/test/utils.js";
import { startProxy } from "@viem/anvil";
import { makeAmountFromString } from "reverse-mirage";
import invariant from "tiny-invariant";
import { type Hex, parseEther } from "viem";

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

  // deploy token
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

  const mockERC20_1 = {
    type: "erc20",
    decimals: 18,
    name: "Mock ERC20",
    symbol: "MOCK",
    chainID: anvil.id,
    address: mockERC20Address1,
  } as const;

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

  const mockERC20_2 = {
    type: "erc20",
    decimals: 18,
    name: "Mock ERC20",
    symbol: "MOCK",
    chainID: anvil.id,
    address: mockERC20Address2,
  } as const;

  // mint token
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

  // sign
  const block = await publicClient.getBlock();
  const transfer = {
    transferDetails: [
      makeAmountFromString(mockERC20_1, "1"),
      makeAmountFromString(mockERC20_2, "1"),
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

  // transfer
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
          amount: makeAmountFromString(mockERC20_1, "0.5"),
        },
        {
          to: BOB,
          amount: makeAmountFromString(mockERC20_2, "0.5"),
        },
      ],
      signature,
    },
  );
  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  console.log("gas used:", receipt.cumulativeGasUsed);

  await shutdown();
};

main().catch((err) => console.error(err));
