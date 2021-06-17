pragma solidity ^0.5.0;

import './OpenZeppelin/upgradeability/AdminUpgradeabilityProxy.sol';

contract ControllerProxy is AdminUpgradeabilityProxy {
    constructor(
        address _implementation,
        address _admin,
        bytes memory _data
    ) public payable AdminUpgradeabilityProxy(_implementation, _admin, _data) {}
}
