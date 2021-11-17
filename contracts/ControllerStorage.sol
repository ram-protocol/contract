pragma solidity 0.5.17;

import { RToken } from "./RToken.sol";
import "./PriceOracle.sol";

contract UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Unitroller
    */
    address public controllerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingControllerImplementation;
}

contract ControllerV1Storage is UnitrollerAdminStorage {

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint public maxAssets;

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => RToken[]) public accountAssets;

}

contract ControllerV2Storage is ControllerV1Storage {
    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;

        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint collateralFactorMantissa;

        /// @notice Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;

        /// @notice Whether or not this market receives RAM
        bool isRammed;
    }

    /**
     * @notice Official mapping of rTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;


    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;
}

contract ControllerV3Storage is ControllerV2Storage {
    struct RamMarketState {
        /// @notice The market's last updated ramBorrowIndex or ramSupplyIndex
        uint224 index;

        /// @notice The block number the index was last updated at
        uint32 block;
    }

    struct RateDecay {
        /// @notice The ram rate decay factor per period, scaled by 1e18
        uint192 rateMantissa;

        /// @notice Seconds to decay ram rate
        uint32 period;

        /// @notice Last updated at
        uint32 block;
    }

    /// @notice A list of all markets
    RToken[] public allMarkets;

    /// @notice The rate at which the flywheel distributes RAM, per block
    uint public ramRate;

    /// @notice The rate decay of RAM
    RateDecay public ramRateDecay;

    /// @notice The portion of ramRate that each market currently receives
    mapping(address => uint) public ramSpeeds;

    /// @notice The RAM market supply state for each market
    mapping(address => RamMarketState) public ramSupplyState;

    /// @notice The RAM market borrow state for each market
    mapping(address => RamMarketState) public ramBorrowState;

    /// @notice The RAM borrow index for each market for each supplier as of the last time they accrued RAM
    mapping(address => mapping(address => uint)) public ramSupplierIndex;

    /// @notice The RAM borrow index for each market for each borrower as of the last time they accrued RAM
    mapping(address => mapping(address => uint)) public ramBorrowerIndex;

    /// @notice The RAM accrued but not yet transferred to each user
    mapping(address => uint) public ramAccrued;
}

contract ControllerV4Storage is ControllerV3Storage {
    // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    // @notice Borrow caps enforced by borrowAllowed for each rToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint) public borrowCaps;
}

contract ControllerV5Storage is ControllerV4Storage {
    /// @notice The portion of RAM that each contributor receives per block
    mapping(address => uint) public ramContributorSpeeds;

    /// @notice Last block at which a contributor's RAM rewards have been allocated
    mapping(address => uint) public lastContributorBlock;
}
