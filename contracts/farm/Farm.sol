pragma solidity ^0.5.16;

import '../OpenZeppelin/math/SafeMath.sol';
import '../EIP20Interface.sol';
import '../OpenZeppelin/ownership/Ownable.sol';

contract Farm is Ownable {
    /* ========== STATE VARIABLES ========== */
    using SafeMath for uint256;
    EIP20Interface public rewardsToken;
    EIP20Interface public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 60 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _owner,
        address _rewardsToken,
        address _stakingToken
    ) public {
        rewardsToken = EIP20Interface(_rewardsToken);
        stakingToken = EIP20Interface(_stakingToken);
        notEntered = true;
        _transferOwnership(_owner);
    }


    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function getTime() public view returns(uint256) {
        return block.timestamp;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        uint256 t = getTime();
        return t > periodFinish ? periodFinish : t;
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }


    function stake(uint256 amount) public
    nonReentrant
    updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        require(stakingToken.transferFrom(msg.sender, address(this), amount), 'transferFrom failed');
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public
    nonReentrant
    updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        require(stakingToken.transfer(msg.sender, amount), 'transfer Failed');
        emit Withdrawn(msg.sender, amount);
    }


    function claim() public
    nonReentrant
    updateReward(msg.sender) {
       uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            require(rewardsToken.transfer(msg.sender, reward), 'transfer Failed');
            emit RewardPaid(msg.sender, reward);
        }
    }


    /* ========== RESTRICTED FUNCTIONS ========== */
    function addReward(uint256 reward, uint256 newDuration) external onlyOwner updateReward(address(0)) {
        rewardsDuration = newDuration;
        uint256 current = getTime();
        if (current >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(current);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = current;
        periodFinish = current.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    bool notEntered;
    modifier nonReentrant() {
        require(notEntered, "re-entered");
        notEntered = false;
        _;
        notEntered = true; // get a gas-refund post-Istanbul
    }

    /* ========== EVENTS ========== */
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}
