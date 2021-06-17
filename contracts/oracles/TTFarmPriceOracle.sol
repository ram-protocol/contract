pragma solidity ^0.5.16;

import "../PriceOracle.sol";
import { RToken } from "../RToken.sol";
import { RErc20Storage } from "../RTokenInterfaces.sol";


interface TTFarmQuotation {
    function getValue(string calldata token) external view returns (uint);
}

interface Underlying {
    function underlying() external view returns (address);
}

interface Decimals {
    function decimals() external view returns (address);
}


contract TTFarmPriceOracle is PriceOracle {
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    TTFarmQuotation quot;

    constructor (TTFarmQuotation q) public  {
        quot = q;
    }

    function getUnderlyingPrice(RToken rToken) public view returns (uint) {
        if (compareStrings(rToken.symbol(), "rTT")) {
            return quot.getValue("tt");
        } else if (compareStrings(rToken.symbol(), "rBUSD")) {
            return 1e18;
        } else {
            return 1e30;
        }
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
