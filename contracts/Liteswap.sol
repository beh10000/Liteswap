// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Liteswap is ReentrancyGuard {
    using SafeERC20 for IERC20;
    struct Pair {
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
        uint256 totalShares;  // Total shares issued for this pair
        bool initialized;
    }
    struct LiquidityPosition {
        uint256 shares;       // User's share of the pool
        bool hasPosition;     // Whether the position exists
    }
    mapping(uint256 pairId => Pair) public pairs;
    mapping(address tokenA => mapping(address tokenB => uint256)) public tokenPairId;
    mapping(uint256 pairId=> mapping(address liquidityProvider => LiquidityPosition)) public liquidityProviderPositions;
    uint256 private _pairIdCount; // Counter for generating unique pair IDs
    uint256 private constant MINIMUM_SHARES = 1000; // prevent division by zero on first liquidity provision
    
    event PairInitialized(
        uint256 indexed pairId, 
        address indexed tokenA, 
        address indexed tokenB
    );
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
    event ReservesUpdated(
        uint256 indexed pairId, 
        uint256 reserveA, 
        uint256 reserveB
    );
    event Swap(
        uint256 indexed pairId,
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    
    // Custom errors
    error PairAlreadyExists();
    error PairDoesNotExist();
    error InvalidTokenAddress();
    error InsufficientLiquidity();
    error InvalidAmount();
    error TransferFailed();
    error NoPosition();
    error InvalidProportions();
    error InsufficientShares();
    
    constructor() {
        _pairIdCount = 1;
    }
    
    /**
     * @notice Creates a new trading pair between two tokens if it doesn't already exist.
     * The order of tokenA and tokenB doesn't matter - (tokenA,tokenB) and (tokenB,tokenA) 
     * are considered the same pair. Both token addresses must be valid and different from
     * each other. Emits a PairInitialized event upon successful creation.
     * @dev Initializes a new token pair and returns the pair ID
     * @param tokenA The address of the first token in the pair
     * @param tokenB The address of the second token in the pair
     * @param amountA The amount of tokenA to add
     * @param amountB The amount of tokenB to add
     * @return pairId The unique identifier for the newly created pair
     */
    function initializePair(address tokenA, address tokenB, uint256 amountA, uint256 amountB) 
        external 
        returns (uint256 pairId) {
            if (tokenA == address(0) || tokenB == address(0)) revert InvalidTokenAddress();
            if (tokenA == tokenB) revert InvalidTokenAddress();
            if (amountA == 0 || amountB == 0) revert InvalidAmount();
            
            // Sort tokens by address to ensure consistent ordering
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
            (uint256 amount0, uint256 amount1) = tokenA < tokenB ? (amountA, amountB) : (amountB, amountA);
                
            if (tokenPairId[token0][token1] != 0) revert PairAlreadyExists();
            
            pairId = _pairIdCount++;
            tokenPairId[token0][token1] = pairId;

            if (!_transferTokens(token0, msg.sender, address(this), amount0)) revert TransferFailed();
            if (!_transferTokens(token1, msg.sender, address(this), amount1)) revert TransferFailed();

            // Calculate initial shares as geometric mean 
            uint256 initialShares = _sqrt(amount0 * amount1);
            if (initialShares < MINIMUM_SHARES) revert InsufficientLiquidity();
            _mintShares(pairId, msg.sender, initialShares);

            pairs[pairId] = Pair({
                tokenA: token0,
                tokenB: token1,
                reserveA: amount0,
                reserveB: amount1,
                totalShares: initialShares,
                initialized: true
            });

            emit PairInitialized(pairId, token0, token1);
            emit LiquidityAdded(pairId, msg.sender, amount0, amount1, initialShares);
            emit ReservesUpdated(pairId, amount0, amount1);
            return pairId;
    }

    /**
     * @notice Adds liquidity to an existing trading pair by providing one token amount. The required amount
     * of the second token is calculated based on the current exchange rate to maintain price stability. 
     * Before calling, the liquidity provider must set approval on both Token A and Token B.
     * Liquidity provider should manage token allowances for Token B to set limit if price changes between tx broadcasting and block inclusion.
     * @dev Adds liquidity to a pair. Calculates and transfers the proportional amount of tokenB
     * @param pairId The pair ID to add liquidity to
     * @param amountA The amount of tokenA to add (must be token0 in the pair)
     * @return amountB The amount of tokenB that was transferred
     * @return shares The number of shares minted for the liquidity provider
     */
    function addLiquidity(uint256 pairId, uint256 amountA) 
        external nonReentrant 
        returns (uint256 amountB, uint256 shares) {
            Pair storage pair = pairs[pairId];
            if (!pair.initialized) revert PairDoesNotExist();
            if (amountA == 0) revert InvalidAmount();
            
            // Calculate required tokenB amount based on current ratio
            amountB = (amountA * pair.reserveB) / pair.reserveA;
            if (amountB == 0) revert InvalidAmount();
            
            // Calculate shares based on proportion
            shares = (amountA * pair.totalShares) / pair.reserveA;
            if (shares == 0) revert InsufficientLiquidity();

            if (!_transferTokens(pair.tokenA, msg.sender, address(this), amountA)) revert TransferFailed();
            if (!_transferTokens(pair.tokenB, msg.sender, address(this), amountB)) revert TransferFailed();

            _mintShares(pairId, msg.sender, shares);
            _updateReserves(pairId, pair.reserveA + amountA, pair.reserveB + amountB);

            emit LiquidityAdded(pairId, msg.sender, amountA, amountB, shares);
            return (amountB, shares);
    }

    /**
     * @notice Removes liquidity from a trading pair by burning shares and receiving back both tokens proportionally
     * @dev Removes liquidity from a pair
     * @param sharesToBurn The number of shares to burn
     * @return amountA Amount of tokenA returned
     * @return amountB Amount of tokenB returned
     */
    function removeLiquidity(uint256 pairId, uint256 sharesToBurn) 
        external nonReentrant 
        returns (uint256 amountA, uint256 amountB) {
            if (sharesToBurn == 0) revert InvalidAmount();
            
            LiquidityPosition storage position = liquidityProviderPositions[pairId][msg.sender];
            if (!position.hasPosition) revert NoPosition();
            if (position.shares < sharesToBurn) revert InsufficientShares();

            Pair storage pair = pairs[pairId];
            
            // Calculate tokens to return based on share proportion
            amountA = (pair.reserveA * sharesToBurn) / pair.totalShares;
            amountB = (pair.reserveB * sharesToBurn) / pair.totalShares;
            if (amountA == 0 || amountB == 0) revert InvalidAmount();

            
            _burnShares(pairId, msg.sender, sharesToBurn);
            _updateReserves(pairId, pair.reserveA - amountA, pair.reserveB - amountB);

            IERC20(pair.tokenA).safeTransfer(msg.sender, amountA);
            IERC20(pair.tokenB).safeTransfer(msg.sender, amountB);

            emit LiquidityRemoved(pairId, msg.sender, amountA, amountB, sharesToBurn);
            return (amountA, amountB);
    }
    /**
     * @notice Swaps an exact amount of input tokens for output tokens
     * @dev Performs a token swap with a minimum output amount requirement and applies 0.3% fee
     * @param pairId The pair ID to swap tokens for
     * @param tokenIn The address of the input token
     * @param amountIn The amount of input tokens to swap
     * @param minAmountOut The minimum amount of output tokens that must be received
     * @return amountOut The actual amount of output tokens received
     */
    function swap(uint256 pairId, address tokenIn, uint256 amountIn, uint256 minAmountOut)
        external nonReentrant
        returns (uint256 amountOut){
            if (amountIn == 0) revert InvalidAmount();
            Pair storage pair = pairs[pairId];
            if (!pair.initialized) revert PairDoesNotExist();
            if (tokenIn != pair.tokenA && tokenIn != pair.tokenB) revert InvalidTokenAddress();
            
            // Determine which token is being swapped in/out
            bool isTokenA = tokenIn == pair.tokenA;
            uint256 reserveIn = isTokenA ? pair.reserveA : pair.reserveB;
            uint256 reserveOut = isTokenA ? pair.reserveB : pair.reserveA;
            
            // Calculate output amount using constant product formula (x * y = k)
            // Apply 0.3% fee by using 997 instead of 1000
            // dy = (y * dx * 997) / (x * 1000 + dx * 997)
            amountOut = (reserveOut * amountIn * 997) / (reserveIn * 1000 + amountIn * 997);
            
            if (amountOut < minAmountOut) revert InvalidAmount();
            if (amountOut >= reserveOut) revert InsufficientLiquidity();
            
            // Transfer input tokens from user to contract
            if (!_transferTokens(tokenIn, msg.sender, address(this), amountIn)) revert TransferFailed();
            
            // Transfer output tokens to user
            address tokenOut = isTokenA ? pair.tokenB : pair.tokenA;
            IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
            
            // Update reserves - fee is absorbed into reserves since we're transferring full amountIn
            uint256 newReserveA = isTokenA ? pair.reserveA + amountIn : pair.reserveA - amountOut;
            uint256 newReserveB = isTokenA ? pair.reserveB - amountOut : pair.reserveB + amountIn;
                
            _updateReserves(pairId, newReserveA, newReserveB);
            
            emit Swap(pairId, msg.sender, tokenIn, tokenOut, amountIn, amountOut);
            
            return amountOut;
    }

    /**
     * @dev Safe transfer function that works with any ERC20 token
     * Core utility function used by multiple main functions
     */
    function _transferTokens(address token, address from, address to, uint256 amount) 
        private 
        returns (bool) {
            IERC20(token).safeTransferFrom(from, to, amount);
            return true;  // safeTransferFrom will revert on failure
    }

    /**
     * @dev Updates the reserves for a pair
     * Core state update function used by multiple main functions
     */
    function _updateReserves(uint256 pairId, uint256 reserveA, uint256 reserveB) 
        private {
            pairs[pairId].reserveA = reserveA;
            pairs[pairId].reserveB = reserveB;
            emit ReservesUpdated(pairId, reserveA, reserveB);
    }

    /**
     * @dev Mints shares to an address
     * Share management function
     */
    function _mintShares(uint256 pairId, address to, uint256 amount) 
        private {
            LiquidityPosition storage position = liquidityProviderPositions[pairId][to];
            position.shares += amount;
            position.hasPosition = true;
            pairs[pairId].totalShares += amount;
    }

    /**
     * @dev Burns shares from an address
     * Share management function
     */
    function _burnShares(uint256 pairId, address from, uint256 amount) 
        private {
            LiquidityPosition storage position = liquidityProviderPositions[pairId][from];
            position.shares -= amount;
            if (position.shares == 0) {
                position.hasPosition = false;
            }
            pairs[pairId].totalShares -= amount;
    }

    /**
     * @dev Square root function
     * Math utility function
     */
    function _sqrt(uint256 y) 
        private pure 
        returns (uint256 z) {
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

    // View Functions

    /**
     * @notice Gets the unique pair ID for a token pair
     * @dev Orders the token addresses and retrieves the pair ID from mapping
     * @param tokenA The address of the first token
     * @param tokenB The address of the second token
     * @return The unique identifier for the token pair, or 0 if pair doesn't exist
     */
    function getPairId(address tokenA, address tokenB) 
        public view 
        returns (uint256) {
            (address token0, address token1) = tokenA < tokenB 
                ? (tokenA, tokenB) 
                : (tokenB, tokenA);
            return tokenPairId[token0][token1];
    }

    /**
     * @notice Returns the current reserves and total shares for a liquidity pair
     * @dev Retrieves the stored reserves and total shares from the Pair struct
     * @param pairId The unique identifier of the liquidity pair
     * @return reserveA The current reserve of tokenA in the pair
     * @return reserveB The current reserve of tokenB in the pair
     * @return totalShares The total number of shares issued for this pair
     */
    function getPairInfo(uint256 pairId) 
        external view 
        returns (uint256 reserveA, uint256 reserveB, uint256 totalShares) {
            Pair storage pair = pairs[pairId];
            return (pair.reserveA, pair.reserveB, pair.totalShares);
    }

    /**
     * @notice Calculates a user's share of a liquidity pool in basis points
     * @dev Computes the percentage of the pool owned by the user, scaled by 10000
     * @param pairId The unique identifier of the liquidity pair
     * @param user The address of the liquidity provider
     * @return The user's share in basis points (1 = 0.01%, 10000 = 100%)
     */
    function getUserShareBps(uint256 pairId, address user) 
        public view 
        returns (uint256) {
            Pair storage pair = pairs[pairId];
            LiquidityPosition storage position = liquidityProviderPositions[pairId][user];
            if (pair.totalShares == 0) return 0;
            return (position.shares * 10000) / pair.totalShares;
    }
}