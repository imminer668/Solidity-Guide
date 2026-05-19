// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

struct Candidate {
    string name;
    uint256 voteCount;
}

contract Voting {
    address public chairperson;
    mapping(address => bool) public voters;
    Candidate[] public candidates;

    event CandidateAdded(uint256 indexed candidateId, string name);
    event VoteCasted(address indexed voter, uint256 indexed candidateId);

    error AlreadyVoted();
    error InvalidCandidate();
    error NotChairperson();

    constructor() {
        chairperson = msg.sender;
    }

    modifier onlyChairperson() {
        if (msg.sender != chairperson) revert NotChairperson();
        _;
    }

    function addCandidate(string memory _name) external onlyChairperson {
        candidates.push(Candidate({name: _name, voteCount: 0}));
        emit CandidateAdded(candidates.length - 1, _name);
    }

    function vote(uint256 _candidateId) external {
        if (voters[msg.sender]) revert AlreadyVoted();
        if (_candidateId >= candidates.length) revert InvalidCandidate();

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
        emit VoteCasted(msg.sender, _candidateId);
    }

    function getCandidate(uint256 _id) external view returns (string memory name, uint256 voteCount) {
        if (_id >= candidates.length) revert InvalidCandidate();
        Candidate memory c = candidates[_id];
        return (c.name, c.voteCount);
    }

    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }
}