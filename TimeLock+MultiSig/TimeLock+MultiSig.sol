// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract TimeLock {
    address public admin;

    uint MINIMUM_DELAY = 60;
    uint MAXIMUM_DELAY = 1000;
    uint GRADE_PERIOD = 1 days;
    uint CONFIRMATIONS_REQUIRED = 3;

    struct Transaction {
        bytes32 txId;
        address to;
        uint value;
        bytes data;
        uint confirmations;
    }

    mapping(bytes32 => Transaction) public txs;

    mapping(bytes32 => mapping(address => bool)) public confirmations;

    mapping(bytes32 => bool) public queue;
    mapping(address => bool) public isOwner;

    event Queued(bytes32 _txId, uint _timestamp, address _proposer);
    event Discard(bytes32 _txId, uint _timestamp, address _discarder);
    event Executed(bytes32 _txId, uint _timestamp);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not an owner");
        _;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not an owner");
        _;
    }



    function addToQueue(
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external onlyOwner returns(bytes32){
        require(_timestamp <= MAXIMUM_DELAY || _timestamp >= MINIMUM_DELAY, "Incorrect Delay");
        bytes32 txId = keccak256(abi.encode(
            _to,
            _value,
            _func,
            _data,
            _timestamp
        ));
        require(!queue[txId], "already queued");

        queue[txId] = true;
        txs[txId] = Transaction({
            txId: txId,
            to: _to,
            value: _value,
            data: _data,
            confirmations: 0
         });

        emit Queued(txId, _timestamp, msg.sender);

        return txId;
    }

    function confirm(bytes32 txId) external onlyOwner {
        require(!confirmations[txId][msg.sender], "already voted");
        require(queue[txId], "not queued");
        Transaction storage transaction = txs[txId];

        confirmations[txId][msg.sender] = true;
        transaction.confirmations++;
    }

    function cancelConfirmation(bytes32 txId) external onlyOwner {
        require(confirmations[txId][msg.sender], "You are not confirm");
        require(queue[txId], "not queued");
        Transaction storage transaction = txs[txId];

        confirmations[txId][msg.sender] = false;
        transaction.confirmations--;
    }

    function execute(        
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external onlyOwner returns(bytes memory){
        require(block.timestamp < _timestamp, "too early");
        require(block.timestamp > _timestamp + GRADE_PERIOD, "tx expired");
                
        bytes32 txId = keccak256(abi.encode(
            _to,
            _value,
            _func,
            _data,
            _timestamp
        )); 

        Transaction storage transaction = txs[txId];

        require(transaction.confirmations >= CONFIRMATIONS_REQUIRED, "not enough confirmations");

        require(queue[txId], "not queued");

        delete queue[txId];
        delete txs[txId];

        bytes memory data;  
        if(bytes(_func).length > 0) {
            data = abi.encode(
                keccak256(bytes(_func)),
                _data
            );
        } else {
            data = _data;
        }

        (bool success, bytes memory resp) = _to.call{value: _value}(data);
        require(success);

        emit Executed(txId, block.timestamp);

        return resp;
    }

    function discard(bytes32 txId) external onlyOwner {
        require(queue[txId], "not queued");

        delete queue[txId];

        emit Discard(txId, block.timestamp, msg.sender);

    }

    function setOwner(address _newOwner) external onlyAdmin{
        isOwner[_newOwner] = true;
    }

    function removeOwner(address _Owner) external onlyAdmin{
        isOwner[_Owner] = false;
    }

}   