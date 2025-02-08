import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("Liteswap", function () {
  /*
  things to test:
  1. disallow 0 address, disallow two of the same address, disallow non-address entries, disallow duplicate either order
  2. liquidity adding: first time confirm square root. confirm share count and reserve count increment as intended
  3. liquidity removal: make sure share count and reserve count decrement as intended
  */
  });
