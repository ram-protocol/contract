pragma solidity ^0.5.16;

import "../WhitePaperInterestRateModel.sol";

contract Linear_2_14 is WhitePaperInterestRateModel {
    constructor(uint baseRatePerYear, uint multiplierPerYear)
        WhitePaperInterestRateModel(baseRatePerYear, multiplierPerYear) public {}
}
