// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

/**
 * @dev MultiCall 多重调用合约 - 原生实现
 */
contract MultiCall {
    struct Call {
        address target;
        bool allowFailure;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function multicall(Call[] calldata calls) external returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);

        for (uint256 i = 0; i < length; i++) {
            Call calldata calli = calls[i];
            (bool success, bytes memory data) = calli.target.call(calli.callData);
            returnData[i] = Result(success, data);

            if (!calli.allowFailure && !success) {
                revert("MultiCall: call failed");
            }
        }
    }
}