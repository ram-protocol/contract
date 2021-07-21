pragma solidity ^0.5.16;
import '@openzeppelin/upgrades/contracts/upgradeability/AdminUpgradeabilityProxy.sol';
import "../RErc20.sol";

contract BNBImplementation is RErc20 {}
contract BNBProxy is AdminUpgradeabilityProxy {
    constructor(
        address _implementation,
        address _admin,
        bytes memory _data
    ) public payable AdminUpgradeabilityProxy(_implementation, _admin, _data) {}
}
