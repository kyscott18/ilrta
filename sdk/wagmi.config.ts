import { defineConfig } from "@wagmi/cli";
import { foundry } from "@wagmi/cli/plugins";

export default defineConfig({
  out: "src/generated.ts",
  contracts: [],
  plugins: [
    foundry({
      project: "node_modules/ilrta-evm/",
    }),
    foundry({
      project: "node_modules/ilrta-evm/lib/solmate/",
      include: ["MockERC20.sol/**"],
      namePrefix: "solmate",
    }),
    foundry({
      project: "contracts",
    }),
  ],
});
