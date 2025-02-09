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
  Pair Initialization:
  - Should revert when initializing with zero address for either token
  - Should revert when initializing with same token address for both tokens
  - Should revert when initializing a pair that already exists (in either token order)
  - Should revert when initializing with zero amount for either token
  - Should correctly sort tokens by address
  - Should correctly calculate initial shares as geometric mean
  - Should revert if initial shares are below MINIMUM_SHARES
  - Should properly set pair state (reserves, tokens, shares)
  - Should emit correct events (PairInitialized, LiquidityAdded, ReservesUpdated)

  Adding Liquidity:
  - Should revert when adding to non-existent pair
  - Should revert when adding zero amount
  - Should calculate correct amount of tokenB needed based on current ratio
  - Should mint correct number of shares proportional to contribution
  - Should properly update reserves
  - Should properly update user's liquidity position
  - Should emit correct events (LiquidityAdded, ReservesUpdated)

  Removing Liquidity:
  - Should revert when removing from non-existent position
  - Should revert when removing zero shares
  - Should revert when removing more shares than owned
  - Should calculate correct token amounts based on share proportion
  - Should properly burn shares
  - Should properly update reserves
  - Should properly update/remove user's liquidity position
  - Should emit correct events (LiquidityRemoved, ReservesUpdated)

  Token Transfers:
  - Should properly handle failed token transfers
  - Should properly handle tokens with different decimals
  - Should properly handle non-standard ERC20 tokens (e.g., tokens that return false on success)
  */
  async function deployFixture() {
    const [owner, user1, user2] = await hre.ethers.getSigners();
    
    const TokenFactory = await hre.ethers.getContractFactory("TestERC20");
    const tokenA = await (await TokenFactory.deploy("Token A", "TKNA")).waitForDeployment();
    const tokenB = await (await TokenFactory.deploy("Token B", "TKNB")).waitForDeployment();
    
    const LiteswapFactory = await hre.ethers.getContractFactory("Liteswap");
    const liteswap = await (await LiteswapFactory.deploy()).waitForDeployment();
    
    // Mint some tokens to users for testing
    const mintAmount = hre.ethers.parseEther("1000000");
    await tokenA.mint(owner.address, mintAmount);
    await tokenA.mint(user1.address, mintAmount);
    await tokenA.mint(user2.address, mintAmount);
    await tokenB.mint(owner.address, mintAmount);
    await tokenB.mint(user1.address, mintAmount);
    await tokenB.mint(user2.address, mintAmount);

    return { liteswap, tokenA, tokenB, owner, user1, user2 };
  }

  describe("Pair Initialization", function() {
    it("Should revert when initializing with zero address for either token", async function() {
      const { liteswap, tokenA } = await loadFixture(deployFixture);
      const amount = hre.ethers.parseEther("1000");

      await expect(liteswap.initializePair(
        tokenA.getAddress(), 
        hre.ethers.ZeroAddress, 
        amount, 
        amount
      )).to.be.revertedWithCustomError(liteswap, "InvalidTokenAddress");

      await expect(liteswap.initializePair(
        hre.ethers.ZeroAddress,
        tokenA.getAddress(), 
        amount, 
        amount
      )).to.be.revertedWithCustomError(liteswap, "InvalidTokenAddress");
    });

    it("Should revert when initializing with same token address", async function() {
      const { liteswap, tokenA } = await loadFixture(deployFixture);
      const amount = hre.ethers.parseEther("1000");

      await expect(liteswap.initializePair(
        tokenA.getAddress(),
        tokenA.getAddress(),
        amount,
        amount
      )).to.be.revertedWithCustomError(liteswap, "InvalidTokenAddress");
    });

    it("Should revert when initializing with zero amount", async function() {
      const { liteswap, tokenA, tokenB } = await loadFixture(deployFixture);
      const amount = hre.ethers.parseEther("1000");

      await expect(liteswap.initializePair(
        tokenA.getAddress(),
        tokenB.getAddress(),
        0,
        amount
      )).to.be.revertedWithCustomError(liteswap, "InvalidAmount");

      await expect(liteswap.initializePair(
        tokenA.getAddress(),
        tokenB.getAddress(),
        amount,
        0
      )).to.be.revertedWithCustomError(liteswap, "InvalidAmount");
    });

    it("Should correctly initialize a pair and emit events", async function() {
      const { liteswap, tokenA, tokenB, owner } = await loadFixture(deployFixture);
      const amountA = hre.ethers.parseEther("1000");
      const amountB = hre.ethers.parseEther("1000");

      // Approve tokens
      await tokenA.approve(await liteswap.getAddress(), amountA);
      await tokenB.approve(await liteswap.getAddress(), amountB);

      // Get token addresses
      const tokenAAddress = await tokenA.getAddress();
      const tokenBAddress = await tokenB.getAddress();

      // Initialize pair
      const tx = await liteswap.initializePair(tokenAAddress, tokenBAddress, amountA, amountB);

      // Get pair ID
      const pairId = await liteswap.tokenPairId(
        tokenAAddress < tokenBAddress ? tokenAAddress : tokenBAddress,
        tokenAAddress < tokenBAddress ? tokenBAddress : tokenAAddress
      );

      // Verify events
      await expect(tx)
        .to.emit(liteswap, "PairInitialized")
        .withArgs(pairId, tokenAAddress < tokenBAddress ? tokenAAddress : tokenBAddress, 
                        tokenAAddress < tokenBAddress ? tokenBAddress : tokenAAddress);

      await expect(tx)
        .to.emit(liteswap, "LiquidityAdded")
        .withArgs(pairId, owner.address, amountA, amountB, anyValue);

      await expect(tx)
        .to.emit(liteswap, "ReservesUpdated")
        .withArgs(pairId, amountA, amountB);

      // Verify pair state
      const pair = await liteswap.pairs(pairId);
      expect(pair.initialized).to.be.true;
      expect(pair.reserveA).to.equal(amountA);
      expect(pair.reserveB).to.equal(amountB);
      expect(pair.totalShares).to.be.gt(0);
    });
  });

  describe("Adding Liquidity", function() {
    it("Should revert when adding to non-existent pair", async function() {
      const { liteswap } = await loadFixture(deployFixture);
      const amount = hre.ethers.parseEther("1000");

      await expect(liteswap.addLiquidity(999, amount))
        .to.be.revertedWithCustomError(liteswap, "PairDoesNotExist");
    });

    it("Should correctly add liquidity to existing pair", async function() {
      const { liteswap, tokenA, tokenB, owner } = await loadFixture(deployFixture);
      const initialAmount = hre.ethers.parseEther("1000");
      const addAmount = hre.ethers.parseEther("500");

      // Initialize pair
      await tokenA.approve(await liteswap.getAddress(), initialAmount);
      await tokenB.approve(await liteswap.getAddress(), initialAmount);
      await liteswap.initializePair(await tokenA.getAddress(), await tokenB.getAddress(), initialAmount, initialAmount);

      const pairId = await liteswap.tokenPairId(
        await tokenA.getAddress() < await tokenB.getAddress() ? await tokenA.getAddress() : await tokenB.getAddress(),
        await tokenA.getAddress() < await tokenB.getAddress() ? await tokenB.getAddress() : await tokenA.getAddress()
      );

      // Add more liquidity
      await tokenA.approve(await liteswap.getAddress(), addAmount);
      await tokenB.approve(await liteswap.getAddress(), addAmount);
      
      const tx = await liteswap.addLiquidity(pairId, addAmount);

      await expect(tx)
        .to.emit(liteswap, "LiquidityAdded")
        .withArgs(pairId, owner.address, addAmount, addAmount, anyValue);

      // Verify updated reserves
      const pair = await liteswap.pairs(pairId);
      expect(pair.reserveA).to.equal(initialAmount + addAmount);
      expect(pair.reserveB).to.equal(initialAmount + addAmount);
    });
  });

  describe("Removing Liquidity", function() {
    it("Should revert when removing from non-existent position", async function() {
      const { liteswap } = await loadFixture(deployFixture);
      const shares = hre.ethers.parseEther("100");

      await expect(liteswap.removeLiquidity(999, shares))
        .to.be.revertedWithCustomError(liteswap, "NoPosition");
    });

    it("Should correctly remove liquidity", async function() {
      const { liteswap, tokenA, tokenB, owner } = await loadFixture(deployFixture);
      const amount = hre.ethers.parseEther("1000");

      // Initialize pair
      await tokenA.approve(await liteswap.getAddress(), amount);
      await tokenB.approve(await liteswap.getAddress(), amount);
      await liteswap.initializePair(await tokenA.getAddress(), await tokenB.getAddress(), amount, amount);

      const pairId = await liteswap.tokenPairId(
        
        await tokenA.getAddress() < await tokenB.getAddress() ? await tokenA.getAddress() : await tokenB.getAddress(),
        await tokenA.getAddress() < await tokenB.getAddress() ? await tokenB.getAddress() : await tokenA.getAddress()
      );

      // Get initial position
      const position = await liteswap.liquidityProviderPositions(pairId, owner.address);
      const shares = position.shares;

      // Remove all liquidity
      const tx = await liteswap.removeLiquidity(pairId, shares);

      await expect(tx)
        .to.emit(liteswap, "LiquidityRemoved")
        .withArgs(pairId, owner.address, amount, amount, shares);

      // Verify position is cleared
      const finalPosition = await liteswap.liquidityProviderPositions(pairId, owner.address);
      expect(finalPosition.shares).to.equal(0);
    });
  });
});
