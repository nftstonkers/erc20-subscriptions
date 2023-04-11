// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

 
error INV_ADD();
error AL_SUB;

 
contract Subscription is Pausable, Ownable {

    modifier onlyValidAddress {
        if(msg.sender == address(0))
            revert INV_ADD();
        _;
    }

    modifier canSubscribe(uint256 id) {
        if(userSubscriptions[msg.sender][id] >= block.timestamp)
            revert AL_SUB();
        _;
    }

    struct SubscriptionInfo {
        string name;
        uint256 cost;
        uint256 period;
        address paidTo;
        address creator;
    }

    SubscriptionInfo[] public subscriptions;
    mapping(address => mapping(uint256 => uint256)) public userSubscriptions;
    
    event NewSubscription(address indexed owner, uint256 id);
    event NewSubscriber(address indexed subscriber, address indexed owner, uint256 id, uint256 expiry);

    
    function createSubscription(string memory _name, uint256 _cost, uint256 _duration, address _paidTo) external onlyValidAddress whenNotPaused {
        require(_duration>0, "Invalid duration");
        subscriptions.push(SubscriptionInfo(_name,_cost,_duration,_paidTo,msg.sender));
        emit NewSubscription(msg.sender, subscriptions.length);

    }

    function purchase(uint256 id) public payable onlyValidAddress canSubscribe(id) onlyValidAddress whenNotPaused {
        require(subscriptions[id].cost == msg.value, "Invalid Amount Received");
        userSubscriptions[msg.sender][id] = block.timestamp + subscriptions[id].period;
        payable(subscriptions[id].paidTo).transfer(msg.value);
        emit NewSubscriber(msg.sender, subscriptions[id].creator, id, userSubscriptions[msg.sender][id]);
    }

    function togglePause() external onlyValidAddress onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function isSubscriber(address _user, uint256 _subscriptionId) external view returns(bool) {
        return (userSubscriptions[_user][_subscriptionId] > block.timestamp);
    }

}
