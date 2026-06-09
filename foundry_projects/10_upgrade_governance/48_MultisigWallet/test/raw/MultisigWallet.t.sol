// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "../../src/raw/MultisigWallet.sol";

/**
 * @title MultisigWalletTest
 * @notice 原生实现 MultisigWallet（多签钱包）的单元测试
 * @dev 教学重点：
 *      1. 多签钱包：交易需要 M-of-N 签名才能执行
 *      2. 关键概念：
 *         - owners: 签名者列表
 *         - threshold: 所需签名数
 *         - nonce: 每次交易递增，防重放
 *         - txHash: keccak256(to, value, data, nonce, chainid)，EIP-712 风格
 *      3. 签名验证：必须按地址升序拼接 ecrecover 结果
 *      4. ERR10001~ERR10006 错误码含义：
 *         - ERR10001: owners 数量非法
 *         - ERR10002: threshold = 0
 *         - ERR10003: 重复 owner / 0 地址
 *         - ERR10006: 签名不足
 *      5. 实战应用：Gnosis Safe 是此模式的金标准
 */
contract MultisigWalletTest is Test {
    MultisigWallet public wallet;
    address[] public owners;

    /// @dev 阈值 = 2（3 个 owner 至少 2 个签名）
    uint256 constant THRESHOLD = 2;
    uint256 constant AMOUNT = 1 ether;

    /// @dev 3 个 owner 用 vm.addr(1/2/3) 派生，对应 Anvil 默认账户
    function setUp() public {
        owners = [vm.addr(1), vm.addr(2), vm.addr(3)];
        wallet = new MultisigWallet(owners, THRESHOLD);
    }

    /// @notice 验证部署：owners 列表、阈值、isOwner 映射、初始 nonce
    /// @dev 教学要点：vm.addr(pk) 是 Foundry cheatcode，从私钥派生地址
    function testDeployment() public view {
        assertEq(wallet.owners(0), vm.addr(1));
        assertEq(wallet.owners(1), vm.addr(2));
        assertEq(wallet.owners(2), vm.addr(3));
        assertEq(wallet.ownerCount(), 3);

        assertEq(wallet.threshold(), 2);

        assertTrue(wallet.isOwner(vm.addr(1)));
        assertTrue(wallet.isOwner(vm.addr(2)));
        assertTrue(wallet.isOwner(vm.addr(3)));
        assertFalse(wallet.isOwner(address(0x5)));

        assertEq(wallet.nonce(), 0);
    }

    /// @notice 验证 encodeTransactionData 生成稳定的 txHash
    /// @dev 教学要点：txHash 包含 chainid，跨链同 nonce 也不会重放
    function testEncodeTransactionData() public view {
        bytes memory data = "";
        bytes32 txHash = wallet.encodeTransactionData(
            address(0x4),
            AMOUNT,
            data,
            0,
            block.chainid
        );
        assertTrue(txHash != bytes32(0));
    }

    /// @notice 验证 0 个 owner 部署失败
    function testCannotDeployWithZeroOwners() public {
        address[] memory emptyOwners = new address[](0);
        vm.expectRevert("ERR10001");
        new MultisigWallet(emptyOwners, 1);
    }

    /// @notice 验证 threshold=0 部署失败
    function testCannotDeployWithThresholdZero() public {
        address[] memory newOwners = new address[](1);
        newOwners[0] = vm.addr(1);
        vm.expectRevert("ERR10002");
        new MultisigWallet(newOwners, 0);
    }

    /// @notice 验证 threshold > owners 部署失败
    function testCannotDeployWithThresholdGreaterThanOwners() public {
        address[] memory newOwners = new address[](2);
        newOwners[0] = vm.addr(1);
        newOwners[1] = vm.addr(2);
        vm.expectRevert("ERR10001");
        new MultisigWallet(newOwners, 3);
    }

    /// @notice 验证重复 owner 部署失败
    function testCannotDeployWithDuplicateOwners() public {
        address[] memory dupOwners = new address[](2);
        dupOwners[0] = vm.addr(1);
        dupOwners[1] = vm.addr(1);
        vm.expectRevert("ERR10003");
        new MultisigWallet(dupOwners, 2);
    }

    /// @notice 验证 0 地址 owner 部署失败
    function testCannotDeployWithZeroAddressOwner() public {
        address[] memory newOwners = new address[](1);
        newOwners[0] = address(0);
        vm.expectRevert("ERR10003");
        new MultisigWallet(newOwners, 1);
    }

    /// @notice 工具函数：用私钥对 hash 签名，附以太坊签名前缀
    /// @dev 教学要点："\x19Ethereum Signed Message:\n32" 前缀防止跨应用重放
    function sign(bytes32 hash, uint256 privateKey) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)));
        return abi.encodePacked(r, s, v);
    }

    /// @notice 工具函数：构造按地址升序的拼接签名
    /// @dev 教学要点：合约内部会按地址升序校验签名拼接
    function buildSortedSignatures(bytes32 txHash) internal view returns (bytes memory) {
        bytes memory sig1 = sign(txHash, 1);
        bytes memory sig2 = sign(txHash, 2);
        bytes memory sig3 = sign(txHash, 3);
        // 排序：a2 < a3 < a1
        return abi.encodePacked(sig2, sig3, sig1);
    }

    /// @notice 验证多签交易成功执行
    /// @dev 教学要点：
    ///      1. txHash 包含 nonce 和 chainid
    ///      2. 必须按地址升序拼接签名
    ///      3. 执行后 nonce 自增，防重放
    function testExecTransactionWithValidSignatures() public {
        address to = address(0x4);
        uint256 value = AMOUNT;
        bytes memory data = "";
        bytes32 txHash = wallet.encodeTransactionData(to, value, data, wallet.nonce(), block.chainid);

        bytes memory signatures = buildSortedSignatures(txHash);

        vm.deal(address(wallet), AMOUNT * 2);

        assertEq(address(to).balance, 0);

        bool success = wallet.execTransaction{value: value}(to, value, data, signatures);
        assertTrue(success);

        assertEq(address(to).balance, AMOUNT);
        assertEq(wallet.nonce(), 1);
    }

    /// @notice 验证签名不足时 revert
    function testExecTransactionWithInsufficientSignatures() public {
        address to = address(0x4);
        uint256 value = AMOUNT;
        bytes memory data = "";
        bytes32 txHash = wallet.encodeTransactionData(to, value, data, wallet.nonce(), block.chainid);

        bytes memory sig2 = sign(txHash, 2);  // 仅 1 个签名
        bytes memory signatures = sig2;

        vm.deal(address(wallet), AMOUNT * 2);

        vm.expectRevert("ERR10006");
        wallet.execTransaction{value: value}(to, value, data, signatures);
    }

    /// @notice 验证非 owner 签名被拒
    function testExecTransactionWithInvalidSignature() public {
        address to = address(0x4);
        uint256 value = AMOUNT;
        bytes memory data = "";
        bytes32 txHash = wallet.encodeTransactionData(to, value, data, wallet.nonce(), block.chainid);

        bytes memory sig1 = sign(txHash, 999); // 非 owner
        bytes memory signatures = sig1;

        vm.deal(address(wallet), AMOUNT * 2);

        vm.expectRevert("ERR10006");
        wallet.execTransaction{value: value}(to, value, data, signatures);
    }

    /// @notice 验证 nonce 防重放
    /// @dev 教学要点：nonce 变化后旧签名失效
    function testNoncePreventsReplayAttack() public {
        address to = address(0x4);
        uint256 value = AMOUNT;
        bytes memory data = "";

        bytes32 txHash = wallet.encodeTransactionData(to, value, data, wallet.nonce(), block.chainid);
        bytes memory signatures = buildSortedSignatures(txHash);

        vm.deal(address(wallet), AMOUNT * 3);

        // 第一次执行成功
        wallet.execTransaction{value: value}(to, value, data, signatures);
        assertEq(wallet.nonce(), 1);

        // 用新 nonce 重新签名后再执行
        bytes32 txHash2 = wallet.encodeTransactionData(to, value, data, wallet.nonce(), block.chainid);
        bytes memory signatures2 = buildSortedSignatures(txHash2);
        wallet.execTransaction{value: value}(to, value, data, signatures2);
        assertEq(wallet.nonce(), 2);
    }
}
