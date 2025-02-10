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
- goerli
- mainnet

## Usage

After deployment, interact with the contract using:

1. Web interface (if available)
2. Direct contract interaction through etherscan
3. Programmatic integration using the contract ABI

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

```bash
git clone https://github.com/yourusername/liteswap.git
cd liteswap
```

```bash
npm install
```

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
- goerli
- mainnet

## Usage

After deployment, interact with the contract using:

1. Web interface (if available)
2. Direct contract interaction through etherscan
3. Programmatic integration using the contract ABI

## Security

- Contract has been audited by [Audit Firm Name] (optional)
- All mathematical operations use SafeMath
- Thoroughly tested against edge cases
- Emergency pause functionality for critical situations

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
