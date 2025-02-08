// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";



const LiteswapModule = buildModule("LiteswapModule", (m) => {
  // Deploy the Liteswap contract
  const liteswap = m.contract("Liteswap", []);
  console.log(liteswap.id)
  return { liteswap };
});

export default LiteswapModule;
