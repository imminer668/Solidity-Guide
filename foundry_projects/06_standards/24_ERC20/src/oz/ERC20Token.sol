// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev OpenZeppelin ERC20 实现
 * 使用 OpenZeppelin 的 ERC20 基类，添加简单的元数据配置
 */
contract ERC20Token is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // 铸造代币（教学用，生产环境需权限控制）
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    // 销毁代币（教学用）
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}