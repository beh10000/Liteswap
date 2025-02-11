#Liteswap
# Liteswap
A lightweight decentralized exchange (DEX) smart contract that enables trading between ERC20 token pairs with automated market making (AMM) complemented by simple limit orders.  

## Features

- Create trading pairs between any two ERC20 tokens
- Add/remove liquidity to earn fees from trades 
- Swap tokens with 0.3% fee that goes to liquidity providers
- Fee-free limit order placement, filling, and cancellation.

## Architecture

The core contract `Liteswap.sol` implements:

- Pair creation and management
- Share-based liquidity provision accounting
- Constant product AMM formula (x * y = k)
- Simple offer based limit order system

## Installation

1. Clone the repository:

```bash
git clone https://github.com/beh10000/Liteswap.git

```

2. Install dependencies:

```bash
npm install
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
3. Create a `.env` file with your configuration:

```bash
SEPOLIA_PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
ALCHEMY_API_KEY=your_alchemy_api_key
```
4. Deploy to network:

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

### Public/External Functions

| Function | Inputs | Outputs | Description | State Changing |
|----------|---------|---------|-------------|----------------|
| initializePair | address tokenA, address tokenB, uint256 amountA, uint256 amountB | uint256 pairId | Creates a new trading pair with initial liquidity. Returns pair ID. | Yes |
| addLiquidity | uint256 pairId, uint256 amountA | (uint256 amountB, uint256 shares) | Adds liquidity to existing pair. Returns required token B amount and shares minted. | Yes |
| removeLiquidity | uint256 pairId, uint256 sharesToBurn | (uint256 amountA, uint256 amountB) | Removes liquidity by burning shares. Returns token amounts received. | Yes |
| swap | uint256 pairId, address tokenIn, uint256 amountIn, uint256 minAmountOut | uint256 amountOut | Swaps tokens with 0.3% fee. Returns actual output amount. | Yes |
| placeLimitOrder | uint256 pairId, address offerToken, uint256 offerAmount, uint256 desiredOutput | uint256 orderId | Places a limit order. Returns unique order ID. | Yes |
| cancelLimitOrder | uint256 pairId, uint256 orderId | void | Cancels an active limit order and returns remaining tokens. | Yes |
| fillLimitOrder | uint256 pairId, uint256 orderId, uint256 fillAmount | void | Fills an active limit order with specified amount. | Yes |
| getPairId | address tokenA, address tokenB | uint256 | Gets unique ID for a token pair (order independent). | No |
| getPairInfo | uint256 pairId | (uint256 reserveA, uint256 reserveB, uint256 totalShares) | Gets current reserves and total shares for a pair. | No |
| getUserShareBps | uint256 pairId, address user | uint256 | Gets user's share of pool in basis points (1 = 0.01%). | No |

### Public State Variables

| Variable | Type | Description |
|----------|------|-------------|
| pairs | mapping(uint256 pairId => Pair) | Stores pair information including reserves, tokens, and total shares |
| tokenPairId | mapping(address tokenA => mapping(address tokenB => uint256)) | Maps token pairs to their unique IDs |
| liquidityProviderPositions | mapping(uint256 pairId => mapping(address => LiquidityPosition)) | Tracks liquidity positions for each provider |
| limitOrders | mapping(uint256 pairId => mapping(uint256 orderId => LimitOrder)) | Stores limit order details for each pair |
| _pairIdCount | uint256 | Counter for generating unique pair IDs |

### Events

| Event | Parameters | Description |
|-------|------------|-------------|
| PairInitialized | uint256 pairId, address token0, address token1 | Emitted when new pair is created |
| LiquidityAdded | uint256 pairId, address provider, uint256 amount0, uint256 amount1, uint256 shares | Emitted when liquidity is added |
| LiquidityRemoved | uint256 pairId, address provider, uint256 amount0, uint256 amount1, uint256 shares | Emitted when liquidity is removed |
| Swap | uint256 pairId, address user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut | Emitted when swap occurs |
| ReservesUpdated | uint256 pairId, uint256 reserve0, uint256 reserve1 | Emitted when reserves change |
| LimitOrderPlaced | uint256 pairId, uint256 orderId, address maker, address offerToken, uint256 offerAmount, uint256 desiredOutput | Emitted when limit order is placed |
| LimitOrderCancelled | uint256 pairId, uint256 orderId | Emitted when limit order is cancelled |
| LimitOrderFilled | uint256 pairId, uint256 orderId, address filler, uint256 fillAmount | Emitted when limit order is filled |

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

