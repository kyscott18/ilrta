import { defineConfig } from "@wagmi/cli";
import { foundry } from "@wagmi/cli/plugins";

export default defineConfig({
  out: "src/generated.ts",
  contracts: [],
  plugins: [
    foundry({
      project: "node_modules/ilrta/",
      include: [
        "ILRTA.sol/**",
        "Permit3.sol/**",
        "SuperSignature.sol/**",
        "FungibleToken.sol/**",
        "MockFungibleToken.sol/**",
        "TransferBatch.sol/**",
        "MockERC20.sol/**",
      ],
    }),
  ],
});
