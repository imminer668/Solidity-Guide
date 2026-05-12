// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

// 逻辑合约：只有代码，没有真正的存储（演示用）
contract LogicContract {
    uint256 public value; // slot 0

    function setValue(uint256 _value) external {
        value = _value;
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}

// 代理合约：通过 delegatecall 复用 LogicContract 的代码
// 注意：ProxyContract 和 LogicContract 的 storage 布局必须完全一致
contract ProxyContract {
    uint256 public value; // slot 0，必须和 LogicContract 的 slot 0 对齐

    function execute(address _target, uint256 _newValue) external {
        (bool success, ) = _target.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _newValue)
        );
        require(success, "Delegatecall failed");
    }

    function readValue() external view returns (uint256) {
        return value;
    }
}
