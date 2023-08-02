import {
  type FungibleToken,
  signTransfer,
  transferBySignature,
} from "../src/example/fungibleToken.js";
import { mockFungibleTokenABI } from "../src/generated.js";
import { ALICE, BOB } from "../src/test/constants.js";
import { publicClient, walletClient } from "../src/test/utils.js";
import { startProxy } from "@viem/anvil";
import MockFungibleToken from "ilrta/out/MockFungibleToken.sol/MockFungibleToken.json";
import invariant from "tiny-invariant";
import { type Hex, parseEther, zeroAddress } from "viem";
import { foundry } from "viem/chains";

const main = async () => {
  const shutdown = await startProxy({
    port: 8545, // By default, the proxy will listen on port 8545.
    host: "::", // By default, the proxy will listen on all interfaces.
  });

  // deploy token
  const deployHash = await walletClient.deployContract({
    account: ALICE,
    abi: mockFungibleTokenABI,
    bytecode: MockFungibleToken.bytecode.object as Hex,
    args: [zeroAddress],
  });

  const { contractAddress: mockFTAddress } =
    await publicClient.waitForTransactionReceipt({
      hash: deployHash,
    });
  invariant(mockFTAddress);

  const ft = {
    type: "fungibleToken",
    decimals: 18,
    name: "Test FT",
    symbol: "TEST",
    address: mockFTAddress,
    id: "0x0000000000000000000000000000000000000000000000000000000000000000",
    chainID: foundry.id,
  } as const satisfies FungibleToken;

  // mint token
  const mintHash = await walletClient.writeContract({
    abi: mockFungibleTokenABI,
    functionName: "mint",
    address: mockFTAddress,
    args: [ALICE, parseEther("1")],
  });
  await publicClient.waitForTransactionReceipt({ hash: mintHash });

  // sign
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
        transferDetails: {
          type: "fungibleTokenTransfer",
          ilrta: ft,
          amount: parseEther("0.5"),
        },
      },
      signature,
    },
  );
  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  console.log("gas used:", receipt.cumulativeGasUsed);

  await shutdown();
};

main().catch((err) => console.error(err));
