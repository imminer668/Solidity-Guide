// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SimpleBridge - A simplified cross-chain bridge implementation
/// @notice Demonstrates burn/mint cross-chain bridge pattern
/// @dev This is a simplified local implementation for educational purposes
contract SimpleBridge is ERC20, Ownable {

    // Bridge event - emitted when tokens are locked for cross-chain transfer
    event Bridge(address indexed user, uint256 amount);
    // Mint event - emitted when tokens are minted on target chain
    event Mint(address indexed to, uint256 amount);
    // Lock event - emitted when tokens are locked on source chain
    event Lock(address indexed user, uint256 amount);
    // Unlock event - emitted when tokens are unlocked on target chain
    event Unlock(address indexed user, uint256 amount);

    /**
     * @param name Token Name
     * @param symbol Token Symbol
     * @param totalSupply Token Supply
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) payable ERC20(name, symbol) Ownable() {
        _mint(msg.sender, totalSupply);
    }

    /**
     * @notice Lock tokens for cross-chain transfer (stake/mint pattern)
     * @param amount Amount of tokens to lock
     */
    function lock(uint256 amount) external {
        _transfer(msg.sender, address(this), amount);
        emit Lock(msg.sender, amount);
        emit Bridge(msg.sender, amount);
    }

    /**
     * @notice Unlock tokens (for stake/mint or stake/unstake patterns)
     * @param to Address to receive tokens
     * @param amount Amount of tokens to unlock
     */
    function unlock(address to, uint256 amount) external onlyOwner {
        _transfer(address(this), to, amount);
        emit Unlock(to, amount);
    }

    /**
     * @notice Burn tokens for cross-chain transfer (burn/mint pattern)
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit Bridge(msg.sender, amount);
    }

    /**
     * @notice Mint tokens (called by bridge operator on target chain)
     * @param to Address to receive tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    /**
     * @notice Get the balance of tokens locked in the bridge
     * @return Balance of locked tokens
     */
    function getLockedBalance() external view returns (uint256) {
        return balanceOf(address(this));
    }
}