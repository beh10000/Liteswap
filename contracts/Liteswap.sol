// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";
contract sampleToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000*1 ether);
    }
}
contract Liteswap is ReentrancyGuard {
    struct Pair {
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
        uint256 totalShares;  // Total shares issued for this pair
        bool initialized;
    }

    struct UserPosition {
        uint256 shares;       // User's share of the pool
        bool hasPosition;     // Whether the position exists
    }
    mapping(uint256 pairId => Pair) public pairs;
    mapping(address tokenA => mapping(address tokenB => bool)) public pairExists;
    mapping(uint256 pairId=> mapping(address liquidityProvider => UserPosition)) public liquidityProviderPositions;
    uint256 private _nextPairId; // Counter for generating unique pair IDs
    uint256 private constant MINIMUM_SHARES = 1000; // prevent division by zero on first liquidity provision
    
    event PairInitialized(uint256 indexed pairId, 
        address indexed tokenA, 
        address indexed tokenB);
    event LiquidityAdded(
        uint256 indexed pairId,
        address indexed liquidityProvider,
        uint256 amountA,
        uint256 amountB,
        uint256 shares
    );
    event LiquidityRemoved(
        uint256 indexed pairId,
        address indexed liquidityProvider,
        uint256 amountA,
        uint256 amountB,
        uint256 shares
    );
    event ReservesUpdated(uint256 indexed pairId, uint256 reserveA, uint256 reserveB);
    
    // Custom errors
    error PairAlreadyExists();
    error PairDoesNotExist();
    error InvalidTokenAddress();
    error InsufficientLiquidity();
    error InvalidAmount();
    error TransferFailed();
    error NoPosition();
    error InvalidProportions();
    
    constructor() {
        _nextPairId = 1;
    }
    
    /**
     * @dev Initializes a new token pair and returns the pair ID
     */
    function initializePair(address tokenA, address tokenB) external returns (uint256 pairId) {
        if (tokenA == address(0) || tokenB == address(0)) revert InvalidTokenAddress();
        if (tokenA == tokenB) revert InvalidTokenAddress();
        if (pairExists[tokenA][tokenB] || pairExists[tokenB][tokenA]) revert PairAlreadyExists();
        
        pairId = _nextPairId++;
        
        pairs[pairId] = Pair({
            tokenA: tokenA,
            tokenB: tokenB,
            reserveA: 0,
            reserveB: 0,
            totalShares: 0,
            initialized: true
        });
        
        pairExists[tokenA][tokenB] = true;
        pairExists[tokenB][tokenA] = true;
        
        emit PairInitialized(pairId, tokenA, tokenB);
        return pairId;
    }

    /**
     * @dev Adds liquidity to a pair
     * @return shares The number of shares minted for the liquidity provider
     */
    function addLiquidity(
        uint256 pairId,
        uint256 amountA,
        uint256 amountB
    ) external nonReentrant returns (uint256 shares) {
        Pair storage pair = pairs[pairId];
        if (!pair.initialized) revert PairDoesNotExist();
        if (amountA == 0 || amountB == 0) revert InvalidAmount();

        // Calculate shares to mint
        if (pair.totalShares == 0) {
            // For first deposit, shares are sqrt(a * b) - MINIMUM_SHARES
            shares = _sqrt(amountA * amountB) - MINIMUM_SHARES;
            _mintShares(pairId, address(0), MINIMUM_SHARES); // Lock minimum shares
        } else {
            // For subsequent deposits, maintain proportion with lower of the two ratios
            shares = _min(
                (amountA * pair.totalShares) / pair.reserveA,
                (amountB * pair.totalShares) / pair.reserveB
            );
        }

        if (shares == 0) revert InsufficientLiquidity();

        // Transfer tokens to contract
        if (!_transferTokens(pair.tokenA, msg.sender, address(this), amountA)) revert TransferFailed();
        if (!_transferTokens(pair.tokenB, msg.sender, address(this), amountB)) revert TransferFailed();

        // Mint shares to user
        _mintShares(pairId, msg.sender, shares);

        // Update reserves
        _updateReserves(pairId, pair.reserveA + amountA, pair.reserveB + amountB);

        emit LiquidityAdded(pairId, msg.sender, amountA, amountB, shares);
        return shares;
    }

    /**
     * @dev Removes liquidity from a pair
     * @param sharesToBurn The number of shares to burn
     * @return amountA Amount of tokenA returned
     * @return amountB Amount of tokenB returned
     */
    function removeLiquidity(
        uint256 pairId,
        uint256 sharesToBurn
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        UserPosition storage position = liquidityProviderPositions[pairId][msg.sender];
        if (!position.hasPosition || position.shares < sharesToBurn) revert NoPosition();

        Pair storage pair = pairs[pairId];
        
        // Calculate tokens to return based on share proportion
        amountA = (pair.reserveA * sharesToBurn) / pair.totalShares;
        amountB = (pair.reserveB * sharesToBurn) / pair.totalShares;

        // Burn shares
        _burnShares(pairId, msg.sender, sharesToBurn);

        // Transfer tokens back to user
        if (!IERC20(pair.tokenA).transfer(msg.sender, amountA)) revert TransferFailed();
        if (!IERC20(pair.tokenB).transfer(msg.sender, amountB)) revert TransferFailed();

        // Update reserves
        _updateReserves(pairId, pair.reserveA - amountA, pair.reserveB - amountB);

        emit LiquidityRemoved(pairId, msg.sender, amountA, amountB, sharesToBurn);
        return (amountA, amountB);
    }

    /**
     * @dev Mints shares to an address
     */
    function _mintShares(uint256 pairId, address to, uint256 amount) private {
        UserPosition storage position = liquidityProviderPositions[pairId][to];
        position.shares += amount;
        position.hasPosition = true;
        pairs[pairId].totalShares += amount;
    }

    /**
     * @dev Burns shares from an address
     */
    function _burnShares(uint256 pairId, address from, uint256 amount) private {
        UserPosition storage position = liquidityProviderPositions[pairId][from];
        position.shares -= amount;
        if (position.shares == 0) {
            position.hasPosition = false;
        }
        pairs[pairId].totalShares -= amount;
    }

    /**
     * @dev Gets user's share of the pool (in basis points - 10000 = 100%)
     */
    function getUserShare(uint256 pairId, address user) public view returns (uint256) {
        Pair storage pair = pairs[pairId];
        UserPosition storage position = liquidityProviderPositions[pairId][user];
        if (pair.totalShares == 0) return 0;
        return (position.shares * 10000) / pair.totalShares;
    }

    /**
     * @dev Updates the reserves for a pair
     */
    function _updateReserves(uint256 pairId, uint256 reserveA, uint256 reserveB) private {
        pairs[pairId].reserveA = reserveA;
        pairs[pairId].reserveB = reserveB;
        emit ReservesUpdated(pairId, reserveA, reserveB);
    }

    /**
     * @dev Safe transfer function
     */
    function _transferTokens(address token, address from, address to, uint256 amount) private returns (bool) {
        return IERC20(token).transferFrom(from, to, amount);
    }

    /**
     * @dev Square root function
     */
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @dev Returns minimum of two numbers
     */
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x < y ? x : y;
    }

    /**
     * @dev Returns the reserves and total shares for a pair
     */
    function getPairInfo(uint256 pairId) external view returns (
        uint256 reserveA,
        uint256 reserveB,
        uint256 totalShares
    ) {
        Pair storage pair = pairs[pairId];
        return (pair.reserveA, pair.reserveB, pair.totalShares);
    }
}