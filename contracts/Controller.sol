pragma solidity ^0.5.16;

contract Controller {
    /******** Controller Error Reporter ********/

    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        CONTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED,
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    event Failure(uint error, uint info, uint detail);

    /******** Controller Storage ********/

    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    address public oracle;

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
    mapping(address => address[]) public accountAssets;

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

    bool public transferGuardianPaused;

    bool public seizeGuardianPaused;

    mapping(address => bool) public mintGuardianPaused;

    mapping(address => bool) public borrowGuardianPaused;

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
    address[] public allMarkets;

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

    /// @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    /// @notice Borrow caps enforced by borrowAllowed for each rToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint) public borrowCaps;

    /// @notice The portion of RAM that each contributor receives per block
    mapping(address => uint) public ramContributorSpeeds;

    /// @notice Last block at which a contributor's RAM rewards have been allocated
    mapping(address => uint) public lastContributorBlock;

    /******** Controller User Interface ********/

    /// @notice Indicator that this is a Controller contract (for inspection)
    bool public constant isController = true;

    /******** Assets You Are In ********/

    function enterMarkets(address[] calldata rTokens) external returns (uint[] memory);
    function exitMarket(address rToken) external returns (uint);

    /******** Policy Hooks ********/

    function mintAllowed(address rToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address rToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address rToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address rToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address rToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address rToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address rToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address rToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address rTokenBorrowed,
        address rTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address rTokenBorrowed,
        address rTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address rTokenCollateral,
        address rTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address rTokenCollateral,
        address rTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address rToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address rToken, address src, address dst, uint transferTokens) external;

    /******** Liquidity/Liquidation Calculations ********/

    function liquidateCalculateSeizeTokens(
        address rTokenBorrowed,
        address rTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}
