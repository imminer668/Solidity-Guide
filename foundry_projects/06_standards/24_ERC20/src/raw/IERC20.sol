// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

/**
 * @dev ERC20 接口合约
 * 定义了 ERC20 代币标准必须实现的事件和函数
 */
interface IERC20 {
    // 事件：转账时释放
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 事件：授权时释放
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // 核心函数
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}