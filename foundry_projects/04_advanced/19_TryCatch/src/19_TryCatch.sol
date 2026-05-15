// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract TestContract {
    uint256 public value;

    constructor(uint256 _value) {
        if (_value == 0) revert("Zero not allowed");
        if (_value == 1) assert(false);
        value = _value;
    }

    function setValue(uint256 _value) external {
        if (_value == 0) revert("Zero not allowed");
        if (_value == type(uint256).max) assert(false);
        value = _value;
    }
}

contract TryCatchDemo {
    event Log(string message);
    event PanicLog(bytes data);

    function createContract(uint256 _value) external returns (bool success, uint256 result) {
        try new TestContract(_value) returns (TestContract c) {
            success = true;
            result = c.value();
        } catch Error(string memory reason) {
            emit Log(reason);
            success = false;
            result = 0;
        } catch (bytes memory rawData) {
            emit PanicLog(rawData);
            success = false;
            result = 0;
        }
    }

    function callContract(address _target, uint256 _value) external returns (bool) {
        try TestContract(_target).setValue(_value) {
            return true;
        } catch Error(string memory reason) {
            emit Log(reason);
            return false;
        } catch (bytes memory rawData) {
            emit PanicLog(rawData);
            return false;
        }
    }
}
