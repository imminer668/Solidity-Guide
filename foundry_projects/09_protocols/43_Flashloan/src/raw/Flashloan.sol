// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev SimpleFlashloan 闪电贷合约 - 本地Mock实现
 * 展示闪电贷核心模式：接收代币 -> 执行逻辑 -> 归还代币+手续费
 */
contract SimpleFlashloan {
    uint256 public constant FEE = 3; // 0.3% fee (like Uniswap V2)

    // 闪电贷函数 - 借出代币，触发回调，然后检查归还
    function flashloan(address token, uint256 amount, bytes calldata data) external {
        require(amount > 0, "Amount must be positive");

        // 检查合约有足够余额
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient balance");

        // 转移代币给调用者
        IERC20(token).transfer(msg.sender, amount);

        // 调用回调函数
        (bool success, ) = msg.sender.call(abi.encodeWithSignature("onFlashloan(address,uint256,bytes)", address(this), amount, data));
        require(success, "Flashloan callback failed");

        // 检查归还金额（含手续费）
        uint256 fee = (amount * FEE) / 1000 + 1;
        uint256 repayAmount = amount + fee;
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        require(balanceAfter >= repayAmount, "Repayment failed");
    }
}

/**
 * @dev MockERC20 测试用ERC20代币
 */
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        if (allowance[from][msg.sender] != type(uint256).max) {
            require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}