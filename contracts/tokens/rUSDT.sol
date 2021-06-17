pragma solidity ^0.5.16;

import '../OpenZeppelin/upgradeability/AdminUpgradeabilityProxy.sol';
import "../RErc20.sol";

contract USDTImplementation is RErc20 {}
contract USDTProxy is AdminUpgradeabilityProxy {
    constructor(
        address _implementation,
        address _admin,
        bytes memory _data
    ) public payable AdminUpgradeabilityProxy(_implementation, _admin, _data) {}
}

