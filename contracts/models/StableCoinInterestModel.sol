pragma solidity ^0.5.16;

import "../WhitePaperInterestRateModel.sol";

contract StableCoinInterestModel is WhitePaperInterestRateModel {
    constructor(uint baseRatePerYear, uint multiplierPerYear)
        WhitePaperInterestRateModel(baseRatePerYear, multiplierPerYear) public {}
}
