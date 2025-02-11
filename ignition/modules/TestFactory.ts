import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const TestFactoryModule = buildModule("TestFactoryModule", (m) => {
  // Deploy the Liteswap contract
  const factory = m.contract("TestERC20Factory", []);
  console.log(factory.id)
  return { factory };
});
export default TestFactoryModule;