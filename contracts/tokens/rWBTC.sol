pragma solidity ^0.5.16;
import '../OpenZeppelin/upgradeability/AdminUpgradeabilityProxy.sol';
import "../RErc20.sol";

contract WBTCImplementation is RErc20 {}
contract WBTCProxy is AdminUpgradeabilityProxy {
    constructor(
        address _implementation,
        address _admin,
        bytes memory _data
    ) public payable AdminUpgradeabilityProxy(_implementation, _admin, _data) {}
}
