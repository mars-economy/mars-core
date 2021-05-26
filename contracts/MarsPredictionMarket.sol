// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./MarsERC20OutcomeToken.sol";
import "./interfaces/IPredictionMarket.sol";
import "./libraries/Market.sol";
import "./Parameters.sol";
import "./interfaces/ISettlement.sol";

contract MarsPredictionMarket is IPredictionMarket, Initializable, OwnableUpgradeable {
    bytes16[] public outcomes;
    //list of outcomes
    address[] public outcomeTokens;
    //list of tokens

    uint256 public predictionTimeStart; //when contract was created
    uint256 public predictionTimeEnd; //when buying stops
    uint256 public predictorsNumber;

    uint256 public startSharePrice;
    uint256 public endSharePrice;

    IERC20 public token; //ERC20 token used to buy shares for outcomes
    bytes16 public winningOutcome;

    uint256 public oracleFeeAccumulated;
    uint256 public protocolFeeAccumulated;

    mapping(bytes16 => address) public tokenOutcomeAddress;
    //outcome => address of token
    uint256 public totalPredicted;
    //sum from all predictors on all outcomes
    mapping(address => bool) public claimed;

    ISettlement settlement;
    Parameters parameters;

    function initialize(
        address _token,
        uint256 _predictionTimeEnd,
        // address _settlement,
        Market.Outcome[] memory outcomes,
        address owner,
        uint256 _startSharePrice,
        uint256 _endSharePrice
    ) external initializer {
        __Ownable_init();
        transferOwnership(owner);

        predictionTimeStart = block.timestamp;
        predictionTimeEnd = _predictionTimeEnd;

        require(predictionTimeEnd > predictionTimeStart, "Endtime has to be more then start time");

        for (uint256 i = 0; i < outcomes.length; i++) {
            _addOutcome(outcomes[i].uuid, outcomes[i].position, outcomes[i].name);
        }

        // settlement = ISettlement(_settlement);
        token = IERC20(_token);

        startSharePrice = _startSharePrice;
        endSharePrice = _endSharePrice;
    }

    function roundWeek(uint256 _date) public pure returns (uint256) {
        return (_date / 7 days) * 7 days;
    }

    function getSharePrice(uint256 _currentTime) public view returns (uint256) {
        if (_currentTime > predictionTimeEnd || _currentTime < predictionTimeStart) return 0;
        return (((endSharePrice - startSharePrice) / (predictionTimeEnd - predictionTimeStart)) *
            (roundWeek(_currentTime - predictionTimeStart)) +
            startSharePrice);
    }

    function getUserPredictionState(address _wallet, uint256 _currentTime)
        external
        view
        override
        returns (Market.UserOutcomeInfo[] memory)
    {
        Market.UserOutcomeInfo[] memory app = new Market.UserOutcomeInfo[](outcomes.length);

        uint256 protocolFee = parameters.getProtocolFee();
        uint256 oracleFee = parameters.getOracleFee();
        uint256 divisor = parameters.getDivisor();
        uint256 notFee = divisor - protocolFee - oracleFee;

        for (uint256 i = 0; i < outcomes.length; i++) {
            bytes16 outcomesId = outcomes[i];
            address outcome = tokenOutcomeAddress[outcomesId];

            app[i].outcomeUuid = outcomesId;
            app[i].stakeAmount = MarsERC20OutcomeToken(outcome).stakedAmount(_wallet);
            uint256 totalSupply = MarsERC20OutcomeToken(outcome).totalSupply();
            if (totalSupply != 0) {
                if (winningOutcome == bytes16(0) || winningOutcome == outcomesId)
                    app[i].currentReward = (MarsERC20OutcomeToken(outcome).balanceOf(_wallet) * totalPredicted) / totalSupply;
            }
            //else app[i].currentReward = 0, but that goes by default
            app[i].rewardReceived = outcomesId == winningOutcome ? claimed[_wallet] : false;

            uint256 _outcomeBalance = MarsERC20OutcomeToken(outcome).totalSupply();
            app[i].outcomeBalance = _outcomeBalance;
            _outcomeBalance = _outcomeBalance == 0 ? 1 : _outcomeBalance;

            app[i].suspended = _currentTime > predictionTimeEnd ||
                _currentTime < predictionTimeStart ||
                !isPredictionProfitable(outcomesId, _currentTime, notFee, divisor)
                ? true
                : false;
            app[i].sharePrice = getSharePrice(_currentTime);
        }
        return app;
    }

    function addOutcome(
        bytes16 uuid,
        uint8 position,
        string memory name
    ) external override onlyOwner {
        _addOutcome(uuid, position, name);
    }

    function _addOutcome(
        bytes16 uuid,
        uint8 position,
        string memory name
    ) internal {
        outcomes.push(uuid);
        MarsERC20OutcomeToken newToken = new MarsERC20OutcomeToken("Mars Economy outcome token", 18, "MPO", owner());

        outcomeTokens.push(address(newToken));
        tokenOutcomeAddress[uuid] = address(newToken);
    }

    function collectOracleFee() external {
        require(settlement.oracleCorrectlyVoted(address(this), msg.sender));

        uint256 correctlyVoted = settlement.getCorrectlyVotedCount(address(this));

        require(token.transfer(msg.sender, oracleFeeAccumulated / correctlyVoted), "Failed to transfer amount");
    }

    function collectProtocolFee() external onlyOwner {
        if (settlement.getCorrectlyVotedCount(address(this)) == 0)
            require(token.transfer(parameters.getReceiver(), oracleFeeAccumulated + protocolFeeAccumulated), "Failed to transfer amount");
        else require(token.transfer(parameters.getReceiver(), protocolFeeAccumulated), "Failed to transfer amount");
    }

    function getReward() external override {
        bytes16 _winningOutcome = winningOutcome;
        if (_winningOutcome == bytes16(0)) {
            _winningOutcome = settlement.getWinningOutcome(address(this));
            winningOutcome = _winningOutcome;
        }

        require(claimed[msg.sender] == false, "User already claimed");

        claimed[msg.sender] = true;

        uint256 userOutcomeTokens = MarsERC20OutcomeToken(tokenOutcomeAddress[_winningOutcome]).balanceOf(msg.sender);
        uint256 outcomeBalance = MarsERC20OutcomeToken(tokenOutcomeAddress[_winningOutcome]).totalSupply();

        outcomeBalance = outcomeBalance == 0 ? 1 : outcomeBalance;

        uint256 reward = (userOutcomeTokens * totalPredicted) / outcomeBalance;
        //amount of tokens the owner put on the winning outcome * amount of tokens put by all owners on all outcomes
        // / amount of tokens all owners put on the winning outcome

        require(
            MarsERC20OutcomeToken(tokenOutcomeAddress[_winningOutcome]).transferFrom(msg.sender, address(this), userOutcomeTokens),
            "MARS: Failed to transfer from buyer"
        );

        require(token.transfer(msg.sender, reward), "MARS: Failed to transfer to buyer");
    }

    function setPredictionTimeEnd(uint256 _newValue) external onlyOwner {
        require(_newValue < predictionTimeEnd, "MARKET: CAN ONLY DECREASE predictionTimeEnd");
        require(predictionTimeEnd > predictionTimeStart, "Endtime has to be more then start time");
        predictionTimeEnd = _newValue;
    }

    function getNumberOfOutcomes() external view override returns (uint256) {
        return outcomes.length;
    }

    function getPredictionTimeEnd() external view override returns (uint256) {
        return predictionTimeEnd;
    }

    function predict(bytes16 _outcome, uint256 _amount) external override outcomeDefined(_outcome) {
        require(block.timestamp < predictionTimeEnd, "MARS: Prediction time has passed");
        require(token.transferFrom(msg.sender, address(this), _amount), "MARS: Failed to transfer from buyer");

        uint256 protocolFee = parameters.getProtocolFee();
        uint256 oracleFee = parameters.getOracleFee();
        uint256 divisor = parameters.getDivisor();

        uint256 notFee = divisor - protocolFee - oracleFee;

        uint256 _amountWithFee = (_amount * notFee * 1_000_000) / divisor / getSharePrice(block.timestamp);
        oracleFeeAccumulated += (_amount * oracleFee) / divisor;
        protocolFeeAccumulated += (_amount * protocolFee) / divisor;

        require(
            MarsERC20OutcomeToken(tokenOutcomeAddress[_outcome]).mint(msg.sender, _amountWithFee, (_amount * notFee) / divisor),
            "MARS: Failed to transfer to buyer"
        );

        predictorsNumber += 1;
        totalPredicted += (_amount * notFee) / divisor;

        require(isPredictionProfitable(_outcome, block.timestamp, notFee, divisor), "Prediction is not profitable");
        emit PredictionEvent(msg.sender, _outcome, _amountWithFee);
    }

    function isPredictionProfitable(
        bytes16 _outcome,
        uint256 _currentTime,
        uint256 notFee,
        uint256 feeDivisor
    ) public view returns (bool) {
        uint256 outcomeBalance = MarsERC20OutcomeToken(tokenOutcomeAddress[_outcome]).totalSupply();

        if (outcomeBalance != 0)
            return !((getSharePrice(_currentTime) * notFee) / feeDivisor > (totalPredicted * 1_000_000) / outcomeBalance + 1); //+1 in case of rounding
        return true;
    }

    function getTokens() external view override returns (address[] memory) {
        return outcomeTokens;
    }

    modifier outcomeDefined(bytes16 _outcome) {
        require(tokenOutcomeAddress[_outcome] != address(0), "Mars: outcome not defined");
        _;
    }

    function setSettlement(address _newSettlement) external override onlyOwner {
        settlement = ISettlement(_newSettlement);
    }

    function getTokenOutcomeAddress(bytes16 outcomeUuid) external view override returns (address) {
        return tokenOutcomeAddress[outcomeUuid];
    }

    function setParameters(address _newParameters) external onlyOwner {
        parameters = Parameters(_newParameters);
    }
}
