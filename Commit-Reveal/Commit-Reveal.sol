// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract ComRev {


    mapping(address => bytes32) public commits;
    mapping(address => uint) public votes;
    bool votingStopped;
    function commitVote(bytes32 _hashedVote) external {
        require(!votingStopped);
        require(commits[msg.sender] == bytes32(0));

        commits[msg.sender] = _hashedVote;
    }

    function revealVote(address _candidate, bytes32 _secret) external {
        require(votingStopped);

        bytes32 commit = keccak256(abi.encodePacked(_candidate, _secret, msg.sender));

        require(commit == commits[msg.sender]);

        delete commits[msg.sender];

        votes[_candidate]++;
    }

    function stopVoting() external {
        require(!votingStopped);

        votingStopped = true;
    }
}