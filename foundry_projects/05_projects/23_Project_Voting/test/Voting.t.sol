// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/Voting.sol";

contract VotingTest is Test {
    Voting public voting;
    address chairperson;
    address voter1 = address(0x1);
    address voter2 = address(0x2);
    address voter3 = address(0x3);

    function setUp() public {
        voting = new Voting();
        chairperson = address(this);
    }

    function testInitialState() public {
        assertEq(voting.getCandidateCount(), 0);
    }

    function testAddCandidate() public {
        voting.addCandidate("Alice");
        assertEq(voting.getCandidateCount(), 1);

        (string memory name, uint256 votes) = voting.getCandidate(0);
        assertEq(name, "Alice");
        assertEq(votes, 0);
    }

    function testAddMultipleCandidates() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.addCandidate("Charlie");
        assertEq(voting.getCandidateCount(), 3);
    }

    function testVote() public {
        voting.addCandidate("Alice");
        voting.vote(0);
        (string memory name, uint256 votes) = voting.getCandidate(0);
        assertEq(votes, 1);
    }

    function testCannotVoteTwice() public {
        voting.addCandidate("Alice");
        voting.vote(0);
        vm.expectRevert(Voting.AlreadyVoted.selector);
        voting.vote(0);
    }

    function testMultipleVoters() public {
        voting.addCandidate("Alice");

        vm.prank(voter1);
        voting.vote(0);

        vm.prank(voter2);
        voting.vote(0);

        vm.prank(voter3);
        voting.vote(0);

        (, uint256 votes) = voting.getCandidate(0);
        assertEq(votes, 3);
    }

    function testInvalidCandidate() public {
        voting.addCandidate("Alice");
        vm.prank(voter1);
        vm.expectRevert(Voting.InvalidCandidate.selector);
        voting.vote(99);
    }

    function testOnlyChairpersonCanAdd() public {
        vm.prank(voter1);
        vm.expectRevert(Voting.NotChairperson.selector);
        voting.addCandidate("Bob");
    }
}