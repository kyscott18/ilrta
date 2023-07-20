import MockFungibleToken from "../node_modules/ilrta-evm/out/MockFungibleToken.sol/MockFungibleToken.json";
import Permit3 from "../node_modules/ilrta-evm/out/Permit3.sol/Permit3.json";
import {
  getTransferTypedDataHash,
  signTransfer,
  transferBySignature,
} from "../src/example/fungibleToken";
import { mockFungibleTokenABI, permit3ABI } from "../src/generated";
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
  // const hash1 = getTransferTypedDataHash(1, {
  //   transferDetails: { ilrta: ft_1, data: { amount: parseEther("1") } },
  //   spender:
  // });
  const block = await publicClient.getBlock();
  const signatureTransfer = {
    transferDetails: { ilrta: ft_1, data: { amount: parseEther("1") } },
    nonce: 0n,
    deadline: block.timestamp + 100n,
    spender: ALICE,
  };

  const signature = await signTransfer(walletClient, ALICE, signatureTransfer);

  // transfer
  const { hash } = await transferBySignature(
    publicClient,
    walletClient,
    ALICE,
    {
      signer: ALICE,
      signatureTransfer,
      requestedTransfer: {
        to: BOB,
        transferDetails: { ilrta: ft_1, data: { amount: parseEther("0.5") } },
      },
      signature,
    },
  );
  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  console.log("gas used:", receipt.cumulativeGasUsed);

  await shutdown();
};

main().catch((err) => console.error(err));
