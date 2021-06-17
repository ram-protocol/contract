pragma solidity ^0.5.16;

import { StandaloneERC20 } from "../OpenZeppelin/ERC20/StandaloneERC20.sol";

contract Ram is StandaloneERC20 {
    function initialize(
        uint256 initialSupply,
        address initialHolder,
        address[] memory minters,
        address[] memory pausers
    ) public initializer {
        StandaloneERC20.initialize('Ram', 'RAM', 18, initialSupply, initialHolder, minters, pausers);
    }
}
