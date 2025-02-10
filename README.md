#Liteswap
# Liteswap
A lightweight decentralized exchange (DEX) smart contract that enables trading between ERC20 token pairs with automated market making (AMM).

## Features

- Create trading pairs between any two ERC20 tokens
- Add/remove liquidity to earn fees from trades 
- Swap tokens with 0.3% fee that goes to liquidity providers
- Protection against common attack vectors like reentrancy
- Efficient gas usage through optimized state management

## Architecture

The core contract `Liteswap.sol` implements:

- Pair creation and management
- Liquidity provision tracking
- Constant product AMM formula (x * y = k)
- Share-based liquidity accounting
- Safe token transfers and math operations

## Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/lite

```

2. Install dependencies:

```bash
npm install
```

3. Create a `.env` file with your configuration:

```bash
PRIVATE_KEY=your_private_key
INFURA_PROJECT_ID=your_infura_project_id
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Deployment

1. Compile the contracts:

```bash
npx hardhat compile
```

2. Run tests:

```bash
npx hardhat test
```

3. Deploy to network:

```bash
npx hardhat run scripts/deploy.js --network <network_name>
```


Supported networks:
- localhost
- sepolia
- goerli 
- mainnet

## Usage

After deployment, interact with the contract using:

1. Web interface (if available)
2. Direct contract interaction through etherscan
3. Programmatic integration using the contract ABI

## Contract Interface

### Public Read Variables

| Variable | Type | Description |
|----------|------|-------------|
| pairs | mapping(uint256 => Pair) | Stores pair information including reserves, tokens, and total shares |
| liquidityProviderPositions | mapping(uint256 => mapping(address => LiquidityPosition)) | Tracks liquidity positions for each provider |

### Public Functions

| Function | Inputs | Outputs | Description |
|----------|---------|---------|-------------|
| initializePair | address token0, address token1, uint256 amount0, uint256 amount1 | uint256 pairId | Creates a new trading pair with initial liquidity. Returns pair ID. |
| addLiquidity | uint256 pairId, uint256 amountA | (uint256 amountB, uint256 shares) | Adds liquidity to existing pair. Returns required token B amount and shares minted. |
| removeLiquidity | uint256 pairId, uint256 sharesToBurn | (uint256 amountA, uint256 amountB) | Removes liquidity by burning shares. Returns token amounts received. |
| swap | uint256 pairId, address tokenIn, uint256 amountIn, uint256 minAmountOut | uint256 amountOut | Swaps tokens with 0.3% fee. Returns actual output amount. |
| tokenPairId | address token0, address token1 | uint256 | Gets unique ID for a token pair (order independent). |
| getReserves | uint256 pairId | (uint256 reserveA, uint256 reserveB) | Gets current reserves for a pair. |
| getLiquidityPosition | uint256 pairId, address provider | (bool hasPosition, uint256 shares) | Gets liquidity position details for an address. |
| getPair | uint256 pairId | (address tokenA, address tokenB, uint256 reserveA, uint256 reserveB, uint256 totalShares, bool initialized) | Gets full pair details. |

### Events

| Event | Parameters | Description |
|-------|------------|-------------|
| PairInitialized | uint256 pairId, address token0, address token1 | Emitted when new pair is created |
| LiquidityAdded | uint256 pairId, address provider, uint256 amount0, uint256 amount1, uint256 shares | Emitted when liquidity is added |
| LiquidityRemoved | uint256 pairId, address provider, uint256 amount0, uint256 amount1, uint256 shares | Emitted when liquidity is removed |
| Swap | uint256 pairId, address user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut | Emitted when swap occurs |
| ReservesUpdated | uint256 pairId, uint256 reserve0, uint256 reserve1 | Emitted when reserves change |

## Security

- Contract has not been audited
- Thoroughly tested against edge cases

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

