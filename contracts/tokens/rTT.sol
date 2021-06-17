pragma solidity ^0.5.16;
import '../OpenZeppelin/upgradeability/AdminUpgradeabilityProxy.sol';
import "../REther.sol";

contract TTImplementation is REther {}
contract TTProxy is AdminUpgradeabilityProxy {
    constructor(
        address _implementation,
        address _admin,
        bytes memory _data
    ) public payable AdminUpgradeabilityProxy(_implementation, _admin, _data) {}
}
