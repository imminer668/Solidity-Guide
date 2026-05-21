// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {IERC20} from "./IERC20.sol";

/**
 * @dev WETH (Wrapped ETH) 最小实现
 * 封装 ETH 为符合 ERC20 标准的 WETH
 */
contract WETH is IERC20 {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public {
        require(_balances[msg.sender] >= amount, "WETH: insufficient balance");
        _balances[msg.sender] -= amount;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "WETH: transfer failed");
        emit Withdrawal(msg.sender, amount);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount, "WETH: insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(_balances[from] >= amount, "WETH: insufficient balance");
        uint256 allowed = _allowances[from][msg.sender];
        require(allowed >= amount, "WETH: insufficient allowance");
        _balances[from] -= amount;
        _allowances[from][msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}