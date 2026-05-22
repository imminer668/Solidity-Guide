// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "../../src/raw/ERC20.sol";
import "../../src/raw/MerkleAirdrop.sol";

contract MerkleAirdropTest is Test {
    ERC20 token;
    MerkleAirdrop airdrop;

    address alice = address(0xA11CE);
    address bob   = address(0xB0B);
    address carol = address(0xCAFE);
    address dave  = address(0xD057);

    uint256 constant ALICE_AMOUNT = 100e18;
    uint256 constant BOB_AMOUNT   = 200e18;
    uint256 constant CAROL_AMOUNT = 300e18;
    uint256 constant DAVE_AMOUNT  = 400e18;

    bytes32 root;
    bytes32[] aliceProof;
    bytes32[] bobProof;
    bytes32[] carolProof;
    bytes32[] daveProof;

    function _leaf(address user, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, amount));
    }

    function setUp() public {
        token = new ERC20("Test", "TST");
        token.mint(1000e18);

        // 构造 4 叶子树(两两 hash 后再两两 hash)
        bytes32 l0 = _leaf(alice, ALICE_AMOUNT);
        bytes32 l1 = _leaf(bob,   BOB_AMOUNT);
        bytes32 l2 = _leaf(carol, CAROL_AMOUNT);
        bytes32 l3 = _leaf(dave,  DAVE_AMOUNT);

        bytes32 n01 = keccak256(abi.encodePacked(l0 < l1 ? l0 : l1, l0 < l1 ? l1 : l0));
        bytes32 n23 = keccak256(abi.encodePacked(l2 < l3 ? l2 : l3, l2 < l3 ? l3 : l2));
        root = keccak256(abi.encodePacked(n01 < n23 ? n01 : n23, n01 < n23 ? n23 : n01));

        airdrop = new MerkleAirdrop(token, root);
        token.transfer(address(airdrop), 1000e18);

        // 给每个用户准备 proof(从叶子到根的兄弟节点,按 OZ 的 sorted pair 顺序)
        aliceProof = new bytes32[](2);
        aliceProof[0] = l1;
        aliceProof[1] = n23;

        bobProof = new bytes32[](2);
        bobProof[0] = l0;
        bobProof[1] = n23;

        carolProof = new bytes32[](2);
        carolProof[0] = l3;
        carolProof[1] = n01;

        daveProof = new bytes32[](2);
        daveProof[0] = l2;
        daveProof[1] = n01;
    }

    function test_Claim() public {
        uint256 balBefore = token.balanceOf(alice);

        vm.prank(alice);
        airdrop.claim(ALICE_AMOUNT, aliceProof);

        assertEq(token.balanceOf(alice), balBefore + ALICE_AMOUNT);
        assertTrue(airdrop.claimed(alice));
    }

    function test_ClaimInvalidProof() public {
        bytes32[] memory badProof = new bytes32[](2);
        badProof[0] = bytes32(uint256(0xdead));
        badProof[1] = bytes32(uint256(0xbeef));

        vm.prank(alice);
        vm.expectRevert(MerkleAirdrop.InvalidProof.selector);
        airdrop.claim(ALICE_AMOUNT, badProof);
    }

    function test_ClaimByNonWhitelist() public {
        address eve = address(0xE7E);

        vm.prank(eve);
        vm.expectRevert(MerkleAirdrop.InvalidProof.selector);
        airdrop.claim(123e18, aliceProof);
    }

    function test_ClaimTwice() public {
        vm.startPrank(alice);
        airdrop.claim(ALICE_AMOUNT, aliceProof);
        vm.expectRevert(MerkleAirdrop.AlreadyClaimed.selector);
        airdrop.claim(ALICE_AMOUNT, aliceProof);
        vm.stopPrank();
    }

    function test_AllFourClaim() public {
        uint256 total = ALICE_AMOUNT + BOB_AMOUNT + CAROL_AMOUNT + DAVE_AMOUNT;
        uint256 balBefore = token.balanceOf(address(this));

        vm.prank(alice); airdrop.claim(ALICE_AMOUNT, aliceProof);
        vm.prank(bob);   airdrop.claim(BOB_AMOUNT,   bobProof);
        vm.prank(carol); airdrop.claim(CAROL_AMOUNT, carolProof);
        vm.prank(dave);  airdrop.claim(DAVE_AMOUNT,  daveProof);

        assertEq(token.balanceOf(alice), ALICE_AMOUNT);
        assertEq(token.balanceOf(bob),   BOB_AMOUNT);
        assertEq(token.balanceOf(carol), CAROL_AMOUNT);
        assertEq(token.balanceOf(dave),  DAVE_AMOUNT);
        assertEq(token.balanceOf(address(airdrop)), 0);
        assertEq(token.totalSupply() - balBefore, total);
    }
}
