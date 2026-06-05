// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

/**
 * @dev Proxy 代理合约
 * 将调用委托给 Logic 合约，实现数据和逻辑分离
 */
contract Proxy {
    address public implementation;

    constructor(address implementation_) {
        implementation = implementation_;
    }

    fallback() external payable {
        address _implementation = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

/**
 * @dev Logic 逻辑合约
 * 与 Proxy 状态变量存储结构相同
 */
contract Logic {
    address public implementation;
    uint256 public x = 99;
    event CallSuccess();

    function increment() external returns (uint256) {
        emit CallSuccess();
        return x + 1;
    }

    function setX(uint256 _x) external {
        x = _x;
    }
}

/**
 * @dev Caller 调用者合约
 * 通过 call 调用代理合约
 */
contract Caller {
    address public proxy;

    constructor(address proxy_) {
        proxy = proxy_;
    }

    function increment() external returns (uint256) {
        (bool success, bytes memory data) = proxy.call(
            abi.encodeWithSignature("increment()")
        );
        require(success, "Call failed");
        return abi.decode(data, (uint256));
    }
}