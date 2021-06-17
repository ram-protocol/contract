pragma solidity ^0.5.16;

import '../OpenZeppelin/ownership/Ownable.sol';

import "./TTFarmPriceOracle.sol";
import "../OpenZeppelin/math/SafeMath.sol";

contract TTFarmPriceOracleV2 is TTFarmPriceOracle, Ownable {
    using SafeMath for uint;

    event TokenAdded(address indexed rToken, uint8 decimals, string query);
    event TokenRemoved(address indexed rToken);

    struct UnderlyingToken {
        uint8 decimals;
        /** @dev fixed price (NOT scaled by 10 ** decimals) */
        uint248 fixedPrice;
        /** @dev Query symbol registered in TTFarm Quotation */
        string query;
    }

    uint public constant FIXED_DECIMALS = 36;
    uint public constant QUOTATION_DECIMALS = 18;

    mapping(address => UnderlyingToken) private info;

    constructor(TTFarmQuotation q)
        TTFarmPriceOracle(q)
        Ownable ()
        public {}

    function getUnderlyingPrice(RToken rToken) public view returns (uint) {
        UnderlyingToken memory token = info[address(rToken)];

        // Return price 0 if the rToken isn`t support
        if (token.fixedPrice == 0 && bytes(token.query).length == 0) return 0;

        if (token.fixedPrice != 0) {
            return uint256(token.fixedPrice) * 10 ** (
                FIXED_DECIMALS
                    .sub(token.decimals, '[TTFarmPriceOracleV2] Invalid stable token decimals')
            );
        }

        return quot.getValue(token.query) * 10 ** (
            FIXED_DECIMALS
                .sub(QUOTATION_DECIMALS, '[TTFarmPriceOracleV2] Quotation decimals overflow')
                .sub(token.decimals, '[TTFarmPriceOracleV2] Invalid token decimals')
        );
    }

    function addToken(
        RToken rToken,
        uint8 decimals,
        string calldata query,
        uint248 fixedPrice
    ) external onlyOwner {
        require(decimals > 0, '[TTFarmPriceOracleV2] Decimals 0');
        require(
            fixedPrice > 0 || bytes(query).length > 0,
            '[TTFarmPriceOracleV2] Must specify fixed price or quotation query string'
        );

        info[address(rToken)] = UnderlyingToken({
            decimals: decimals,
            fixedPrice: fixedPrice,
            query: query
        });

        emit TokenAdded(address(rToken), decimals, query);
    }

    function removeToken(address rToken) external onlyOwner {
        require(info[rToken].decimals != 0, '[TTFarmPriceOracleV2] The address is not registered');
        delete info[rToken];

        emit TokenRemoved(rToken);
    }
}
