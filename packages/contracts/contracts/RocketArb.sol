// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface RocketStorageInterface {
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
}

interface RocketMinipoolDelegate {
    function distributeBalance(bool _rewardsOnly) external;
    function getNodeAddress() override external view returns (address);
}

interface RETH {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 _rethAmount) external;
    function getTotalCollateral() external view returns (uint256);
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
}

contract RocketArb {
    RETH immutable rEth;
    RocketStorageInterface immutable rocketStorage;

    constructor(address _rocketStorageAddress, address rEthAddress) {
        rEth = RETH(rEthAddress);
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
    }

    function arb(address nodeAddress, address[] minipools) external {
        distribute(nodeAddress, minipools);

        // Todo ask for a flashloan for all the eth in the rocket minipools

        // Burn rEth
        rEth.burn(rEth.balanceOf(address(this)));

        // Swap for rEth
    }

    function distribute(address _nodeAddress, address[] minipools) internal {
        address withdrawalAddress = rocketStorage.getNodeWithdrawalAddress(_nodeAddress);
        // TODO: Use custom error
        require(msg.sender == withdrawalAddress, "Only withdrawalAddress can call this function");
        rocketStorage.confirmWithdrawalAddress(_nodeAddress);
        uint256 minipoolsLength = minipools.length;
        for (uint256 i = 0; i < minipoolsLength; i++) {
            RocketMinipoolDelegate minipool = RocketMinipoolDelegate(minipools[i]);
            require(minipool.getNodeAddress() == nodeAddress, "Only minipool can call this function");
            minipool.distributeBalance(false);
        }
        rocketStorage.setWithdrawalAddress(_nodeAddress, withdrawalAddress, true);
    }
}
