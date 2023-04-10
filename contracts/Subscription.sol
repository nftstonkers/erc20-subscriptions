// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Subscription is Pausable, Ownable {

    modifier onlyValidAddress {
        require(msg.sender != address(0), "Invalid creator address");
        _;
    }

    modifier canSubscribe(uint256 id) {
        require(userSubscriptions[msg.sender][id] < block.timestamp, "Already subscribed");
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
    
    
    function createSubscription(string memory _name, uint256 _cost, uint256 _duration, address _paidTo) external onlyValidAddress whenNotPaused {
        require(_duration>0, "Invalid duration");
        subscriptions.push(SubscriptionInfo(_name,_cost,_duration,_paidTo,msg.sender));
    }

    function purchase(uint256 id) external payable onlyValidAddress canSubscribe(id) onlyValidAddress whenNotPaused {
        require(subscriptions[id].cost == msg.value, "Invalid Amount Received");
        userSubscriptions[msg.sender][id] = block.timestamp + subscriptions[id].period;
        payable(subscriptions[id].paidTo).transfer(msg.value);
    }

    function getSubscriptionsByUser(address _user) external view returns (SubscriptionInfo[] memory) {
        uint256 count = subscriptions.length;
        SubscriptionInfo[] memory userSubscriptionsInfo = new SubscriptionInfo[](count);

        uint256 index = 0;
        for (uint256 i = 0; i < count; i++) {
            if (userSubscriptions[_user][i] > 0) {
                userSubscriptionsInfo[index++] = subscriptions[i];
            }
        }

        // Resize the output array to the actual number of subscriptions
        assembly {
            mstore(userSubscriptionsInfo, index)
        }

        return userSubscriptionsInfo;
    }

    function getSubscriptionsByCreator(address _creator) external view returns (SubscriptionInfo[] memory) {
        uint256 count = subscriptions.length;
        SubscriptionInfo[] memory creatorSubscriptionsInfo = new SubscriptionInfo[](count);

        uint256 index = 0;
        for (uint256 i = 0; i < count; i++) {
            if (subscriptions[i].creator == _creator) {
                creatorSubscriptionsInfo[index++] = subscriptions[i];
            }
        }

        // Resize the output array to the actual number of subscriptions
        assembly {
            mstore(creatorSubscriptionsInfo, index)
        }

        return creatorSubscriptionsInfo;
    }


    function togglePause() external onlyValidAddress onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function isSubscriber(address _user, uint256 _subscriptionId) external view returns(bool) {
        return (userSubscriptions[_user][_subscriptionId] > block.timestamp);
    }

}