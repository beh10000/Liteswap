// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
} 

contract TestFeeOnTransferERC20 is ERC20 {
    uint256 private constant FEE_BPS = 1000; // 10% fee in basis points

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from != address(0) && to != address(0)) { // Skip fee on mint/burn
            uint256 feeAmount = (amount * FEE_BPS) / 10000;
            super._update(from, to, amount - feeAmount);
            _burn(from, feeAmount);
        } else {
            super._update(from, to, amount);
        }
    }
}