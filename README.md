

# Liteswap
![Liteswap](/assets/Liteswap.png)

A simple decentralized exchange protocol that pairs automated market making with limit orders for enhanced trader experience and liquidity provider risk management.

## Features

- Create trading pairs between any two ERC20 tokens
- Add/remove liquidity while collecting fees
- Swap tokens
- Fee-free limit order placement, filling, and cancellation


## Verified Contract Deployment to Sepolia

- https://sepolia.etherscan.io/address/0xd2e85adece075adc02c702f38ba406e806382d8b#code

- simple dapp https://rich-rigid-manufacturer.anvil.app (was using free plan to ensure it could be reproduced by a non-anvil user, which doesnt allow changing the url.)


## Architecture

The core contract `Liteswap.sol` implements:

- Pair creation and management
- Share-based liquidity provision accounting
- Constant product AMM formula (x * y = k)
- Simple offer based limit order system

The supplementary contract `TestERC20.sol` is used for generating test tokens on sepolia to interact with the contract.
````mermaid
graph TD
    subgraph Liteswap [Liteswap Contract Instance]
        subgraph Storage [Contract Storage]
            direction LR
            subgraph Mappings [State Mappings]
                PM[pairs]
                TPM[tokenPairId]
                LPM[liquidityProviderPositions]
                LOM[limitOrders]
            end
            
            subgraph Counters [State Counters]
                PC[_pairIdCount]
                OC[_orderIdCounter]
            end
        end

        subgraph Functions [Contract Functions]
            direction TB
            subgraph AMM [AMM Operations]
                IP[initializePair]
                AL[addLiquidity]
                RL[removeLiquidity]
                SW[swap]
            end

            subgraph LO [Limit Orders]
                PLO[placeLimitOrder]
                FLO[fillLimitOrder]
                CLO[cancelLimitOrder]
            end

            subgraph Internal [Internal Functions]
                TT[_transferTokens]
                UR[_updateReserves]
                MS[_mintShares]
                BS[_burnShares]
                SQ[_sqrt]
            end

            subgraph Views [View Functions]
                GPI[getPairId]
                GPIF[getPairInfo]
                GSB[getUserShareBps]
            end
        end

        Functions --> Storage
        Storage --> Functions
    end

    EXT[External Token Contracts] -.-> Liteswap
    USR[Users] -.-> Liteswap

    style Liteswap fill:#e6e6e6,stroke:#000000,stroke-width:3px,color:#000000
    style Storage fill:#cce5ff,stroke:#000000,stroke-width:1px,color:#000000
    style Functions fill:#d4edda,stroke:#000000,stroke-width:1px,color:#000000
    style AMM fill:#c3e6cb,stroke:#000000,stroke-width:1px,color:#000000
    style LO fill:#d4d7f5,stroke:#000000,stroke-width:1px,color:#000000
    style Internal fill:#ffe5cc,stroke:#000000,stroke-width:1px,color:#000000
    style Views fill:#f8d7da,stroke:#000000,stroke-width:1px,color:#000000
    style Mappings fill:#b8e2fc,stroke:#000000,stroke-width:1px,color:#000000
    style Counters fill:#e9d2f4,stroke:#000000,stroke-width:1px,color:#000000
    style EXT fill:#ffe5cc,stroke:#000000,stroke-width:1px,stroke-dasharray: 5 5,color:#000000
    style USR fill:#ffe5cc,stroke:#000000,stroke-width:1px,stroke-dasharray: 5 5,color:#000000
````
## User Journey
````mermaid
flowchart TD
    START([Start]) --> A{Trading Pair Exists?}
    
    A -->|No| B[Initialize New Pair]
    B --> C[Supply Initial Liquidity]
    C --> D[Pair Created]
    
    A -->|Yes| D
    
    D --> E{Choose Action}
    
    E -->|Swap| F[Swap Tokens]
    F --> G[Approve Token Transfer]
    G --> H[Execute Swap]
    H --> E
    
    E -->|Add Liquidity| I[Add More Liquidity]
    I --> J[Approve Both Tokens]
    J --> K[Provide Liquidity]
    K --> L[Receive LP Shares]
    L --> E
    
    E -->|Remove Liquidity| M[Remove Liquidity]
    M --> N[Burn LP Shares]
    N --> O[Receive Both Tokens]
    O --> E
    
    E --> END([End])

    style START fill:#d4edda,stroke:#000000,stroke-width:2px,color:#000000
    style END fill:#f8d7da,stroke:#000000,stroke-width:2px,color:#000000
    style A fill:#cce5ff,stroke:#000000,stroke-width:2px,color:#000000
    style E fill:#cce5ff,stroke:#000000,stroke-width:2px,color:#000000
    style D fill:#d4d7f5,stroke:#000000,stroke-width:2px,color:#000000
    
    classDef action fill:#e6e6e6,stroke:#000000,stroke-width:2px,color:#000000
    class B,C,F,G,H,I,J,K,L,M,N,O action
    ````

## Stack
- Solidity smart contract
- Hardhat dev node and testing framework
- Typescript tests
- Front end written in python and javascript using Anvil


## Test Coverage
The test suite provides comprehensive coverage of core functionality and edge cases. 

### Core Functionality Tests
- Pair initialization and management
- Liquidity provision (adding/removing)
- Token swaps with AMM
- Limit order placement, filling and cancellation
- Share calculation and accounting

### Edge Case & Security Tests
- Invalid token addresses and zero amounts
- Insufficient allowances and balances 
- Order ID increments and state transitions
- Transfer fee handling
- Price ratio validation

### Coverage Metrics
Based on hardhat coverage report:

|----------------|----------|----------|----------|----------|----------------|
|File            |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
|----------------|----------|----------|----------|----------|----------------|
| contracts/     |    86.03 |    70.71 |    69.57 |    86.78 |                |
|  Liteswap.sol  |    93.55 |    71.74 |     87.5 |    95.54 |... 587,588,589 |
|  TestERC20.sol |     8.33 |        0 |    28.57 |     5.88 |... 56,57,58,60 |
|----------------|----------|----------|----------|----------|----------------|
|All files       |    86.03 |    70.71 |    69.57 |    86.78 |                |
|----------------|----------|----------|----------|----------|----------------|

Note: Additional test cases could improve coverage but core functionality is well tested. The TestERC20 contract had no need to be tested. 

Key test scenarios include:
- Initializing pairs with invalid parameters
- Adding/removing liquidity with edge case amounts
- Swapping with insufficient liquidity
- Placing limit orders with invalid ratios
- Filling already filled/cancelled orders
- Attempting unauthorized cancellations
- Handling token transfer fees correctly


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
3. Prepare for Sepolia testnet deployment by creating a `.env` file with your configuration:

```bash
SEPOLIA_PRIVATE_KEY=your_testnet_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
ALCHEMY_API_KEY=your_alchemy_api_key
```

4a. Deploy Liteswap and the Test Token Factory to localhost network:
```bash
npx hardhat node --network hardhat
```
Save some of the test account private keys that are logged when you activate the hardhat node and import them into your browser wallet when running the below dapp.
Note: If you have not setup your Sepolia private key yet, remove sepolia section from the hardhat.config.ts file. 

```bash
npx hardhat ignition deploy ignition/modules/Liteswap.ts --reset --network localhost && npx hardhat ignition deploy ignition/modules/TestFactory.ts --network localhost
```

4b. Deploy Liteswap to Sepolia
```bash
npx hardhat ignition deploy ignition/modules/Liteswap.ts --reset --network sepolia --verify && npx hardhat ignition deploy ignition/modules/TestFactory.ts --network sepolia --verify
```
Note: You will need Sepolia Testnet ETH to deploy the contracts and interact with the dapp. Alchemy has a faucet. https://www.alchemy.com/faucets/ethereum-sepolia. 
If you do not have an etherscan api key, remove the --verify flag from the commands and remove the etherscan section from hardhat.config.ts.



## Usage

After deployment, clone the dapp.
https://anvil.works/build#clone:VWNRQRSGPY77UYZQ=VT33BJ3AXXGVJTNXHSCYSM4A

This will take you to Anvil, a python web framework and browser IDE. 

Once you open the IDE, find the "contracts" datatable. Copy the Liteswap address and Factory address from the above deployment script logs and paste them into the contracts datatable in the corresponding address fields. The dapp reads the address and abi from this datatable to connect to the contract, so make sure the datatable access settings are set to "Client Read Only, Server No access". 

If you are on the localhost network, go to main.js file and find and update these variables.
```javascript
const gchainrpc="http://127.0.0.1:8545/" 
export const networks = [customNetwork]
```


If you are on Sepolia Network, go to main.js file and set the networks value to:
```javascript 
export const networks = [sepolia]
```
Now click "Run" and you can interact with the app. 

## Contract Reference

### Public/External Functions

| Function | Inputs | Outputs | Description | State Changing |
|----------|---------|---------|-------------|----------------|
| initializePair | address tokenA, address tokenB, uint256 amountA, uint256 amountB | uint256 pairId | Creates a new trading pair between two tokens with initial liquidity. Tokens must be valid and different. Order of tokens doesn't matter. Emits PairInitialized, LiquidityAdded and ReservesUpdated events. | Yes |
| addLiquidity | uint256 pairId, uint256 amountA | (uint256 amountB, uint256 shares) | Adds liquidity to existing pair by providing one token amount. Required amount of second token is calculated based on current exchange rate. Emits LiquidityAdded event. | Yes |
| removeLiquidity | uint256 pairId, uint256 sharesToBurn | (uint256 amountA, uint256 amountB) | Burns shares to remove liquidity proportionally. Returns both token amounts. Emits LiquidityRemoved event. | Yes |
| swap | uint256 pairId, address tokenIn, uint256 amountIn, uint256 minAmountOut | uint256 amountOut | Swaps exact input tokens for output tokens with 0.3% fee. Requires minimum output amount. Handles fee-on-transfer tokens. Emits Swap and ReservesUpdated events. | Yes |
| placeLimitOrder | uint256 pairId, address offerToken, uint256 offerAmount, uint256 desiredAmount | uint256 orderId | Places limit order to swap tokens at specific rate. Rate must be worse than AMM price. Handles fee-on-transfer tokens. Emits LimitOrderPlaced event. | Yes |
| cancelLimitOrder | uint256 pairId, uint256 orderId | void | Cancels active limit order and returns remaining offered tokens to maker. Only callable by order maker. Emits LimitOrderCancelled event. | Yes |
| fillLimitOrder | uint256 pairId, uint256 orderId, uint256 amountDesiredToFill | uint256 filled | Fills active limit order with specified amount. Returns amount of offer tokens sent to filler. Handles fee-on-transfer tokens. Emits LimitOrderFilled event. | Yes |
| getPairId | address tokenA, address tokenB | uint256 | Gets unique ID for token pair. Order of tokens doesn't matter - returns same ID for (A,B) and (B,A). | No |
| getPairInfo | uint256 pairId | (uint256 reserveA, uint256 reserveB, uint256 totalShares) | Gets current reserves and total shares for a liquidity pair. | No |
| getUserShareBps | uint256 pairId, address user | uint256 | Calculates user's share of liquidity pool in basis points (1 = 0.01%, 10000 = 100%). | No |

### Public State Variables 

| Variable | Type | Description |
|----------|------|-------------|
| pairs | mapping(uint256 => Pair) | Stores pair data including tokens, reserves, total shares and initialization status |
| tokenPairId | mapping(address => mapping(address => uint256)) | Maps sorted token addresses to their unique pair ID |
| liquidityProviderPositions | mapping(uint256 => mapping(address => LiquidityPosition)) | Tracks LP positions including shares and position status |
| limitOrders | mapping(uint256 => mapping(uint256 => LimitOrder)) | Stores limit order data including tokens, amounts, maker and status |
| _pairIdCount | uint256 | Counter for generating unique pair IDs starting from 1 |

### Events

| Event | Parameters | Description |
|-------|------------|-------------|
| PairInitialized | uint256 indexed pairId, address token0, address token1 | Emitted when new trading pair is created |
| LiquidityAdded | uint256 indexed pairId, address indexed provider, uint256 amountA, uint256 amountB, uint256 shares | Emitted when liquidity is added to a pair |
| LiquidityRemoved | uint256 indexed pairId, address indexed provider, uint256 amountA, uint256 amountB, uint256 shares | Emitted when liquidity is removed from a pair |
| Swap | uint256 indexed pairId, address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut | Emitted when tokens are swapped |
| ReservesUpdated | uint256 indexed pairId, uint256 reserveA, uint256 reserveB | Emitted when pair reserves are updated |
| LimitOrderPlaced | uint256 indexed pairId, uint256 indexed orderId, address indexed maker, address offerToken, address desiredToken, uint256 offerAmount, uint256 desiredAmount | Emitted when limit order is created |
| LimitOrderCancelled | uint256 indexed pairId, uint256 indexed orderId | Emitted when limit order is cancelled |
| LimitOrderFilled | uint256 indexed pairId, uint256 indexed orderId, address indexed filler, uint256 fillAmount | Emitted when limit order is filled |

## Assumptions and comments
At this point in time, the market is moving beyond solely relying on simple symmetrical constant product market makers and moving towards concentrated liquidity pools. In the interest of time for this project, implementing a version of Uniswap V3 concentrated positions utilizing tick math would have been a stretch. Since it is critical for liquidity providers to be able to hedge impermanent loss and direct ranges in which they want to primarily be buying or selling, the solution was to introduce the simple limit order system alongside the standard constant product liquidity pool. While working through this, it became clear that this can be beneficial for liquidity providers in a situation where they want to be a seller at some price range, but they dont want to also be a buyer at that range. If they were in a V3 pool they would have to monitor the position and pull it once the price marched through it in one direction before returning in the other direction. If they utilized this implementation of the limit order they could set ranges they expect price to hit, exit at the high range, re-enter at the low range and not bear impermanent loss in between.


Before taking to production, a few things may be considered:
- further gas optimization techniques
- implementing a routing system, either on-chain or offchain to close spreads between limit orders and liquidity pool price
- a test sequence using Foundry fuzzing utilities could enhance our confidence in edge case behavior and formal third party audits could enhance user confidence







