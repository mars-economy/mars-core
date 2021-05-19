// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./MarsERC20OutcomeToken.sol";
import "./interfaces/IPredictionMarket.sol";
import "./libraries/Market.sol";
import "./interfaces/ISettlement.sol";

import "hardhat/console.sol";

contract MarsPredictionMarket is IPredictionMarket, Initializable, OwnableUpgradeable {
    bytes16[] public outcomes;
    //list of outcomes
    address[] public outcomeTokens;
    //list of tokens

    uint256 public predictionTimeStart; //when contract was created
    uint256 public predictionTimeEnd; //when buying stops

    uint256 public startSharePrice;
    uint256 public endSharePrice;

    address public token; //ERC20 token used to buy shares for outcomes
    bytes16 public winningOutcome;
    uint256 public notFee;
    uint256 public feeDivisor;

    mapping(bytes16 => address) public tokenOutcomeAddress;
    //outcome => address of token
    uint256 public totalPredicted;
    //sum from all predictors on all outcomes
    mapping(address => bool) public claimed;

    ISettlement settlement;

    function initialize(
        address _token,
        uint256 _predictionTimeEnd,
        address _settlement,
        Market.Outcome[] memory outcomes,
        address owner
    ) external initializer {
        __Ownable_init();
        transferOwnership(owner);

        predictionTimeStart = block.timestamp;
        predictionTimeEnd = _predictionTimeEnd;

        require(predictionTimeEnd > predictionTimeStart, "Endtime has to be more then start time");

        for (uint256 i = 0; i < outcomes.length; i++) {
            _addOutcome(outcomes[i].uuid, outcomes[i].position, outcomes[i].name);
        }

        settlement = ISettlement(_settlement);
        token = _token;

        notFee = 9970; // 0.3%, 100 = 1%
        feeDivisor = 10000;

        startSharePrice = 1_000_000;
        endSharePrice = 10_000_000;
    }

    // function collect() {
    //     if oracle;
    //     if owner;
    // }

    function roundWeek(uint256 _date) public pure returns (uint256) {
        return _date / 7 days;
    }

    // startSharePrice = 1 ether;
    // endSharePrice = 10 ether;
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

        for (uint256 i = 0; i < outcomes.length; i++) {
            bytes16 outcomesId = outcomes[i];
            address outcome = tokenOutcomeAddress[outcomesId];

            app[i].outcomeUuid = outcomesId;
            app[i].stakeAmount = MarsERC20OutcomeToken(outcome).stakedAmount(_wallet);
            uint256 totalSupply = MarsERC20OutcomeToken(outcome).totalSupply();
            if (totalSupply != 0) {
                uint256 amount = (MarsERC20OutcomeToken(outcome).balanceOf(_wallet) * totalPredicted) / totalSupply;
                if (winningOutcome == bytes16(0) || winningOutcome == outcomesId) app[i].currentReward = amount;
            }
            //else app[i].currentReward = 0, but that goes by default
            app[i].rewardReceived = outcomesId == winningOutcome ? claimed[_wallet] : false;

            uint256 outcomeBalance = MarsERC20OutcomeToken(outcome).totalSupply();
            outcomeBalance = outcomeBalance == 0 ? 1 : outcomeBalance;

            app[i].suspended = _currentTime > predictionTimeEnd ||
                _currentTime < predictionTimeStart ||
                !isPredictionProfitable(outcomesId, _currentTime)
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

        // newToken.initialize("Mars Economy outcome token", 18, "MPO"); // changed from abi.encodePacked(uuid)
        // newToken.transferOwnership(owner());

        outcomeTokens.push(address(newToken));
        tokenOutcomeAddress[uuid] = address(newToken);
    }

    function getReward() external override {
        bytes16 _winningOutcome = winningOutcome;
        if (_winningOutcome == bytes16(0)) {
            _winningOutcome = settlement.getWinningOutcome(address(this));
            winningOutcome = _winningOutcome;
        }

        require(claimed[msg.sender] == false, "USER ALREADY CLAIMED");

        claimed[msg.sender] = true;

        uint256 userOutcomeTokens = MarsERC20OutcomeToken(tokenOutcomeAddress[winningOutcome]).balanceOf(msg.sender);
        uint256 outcomeBalance = MarsERC20OutcomeToken(tokenOutcomeAddress[winningOutcome]).totalSupply();
        // uint256 _stakeAmount = MarsERC20OutcomeToken(tokenOutcomeAddress[winningOutcome]).stakedAmount(msg.sender);

        outcomeBalance = outcomeBalance == 0 ? 1 : outcomeBalance;

        uint256 reward = (userOutcomeTokens * totalPredicted) / outcomeBalance;
        //amount of tokens the owner put on the winning outcome * amount of tokens put by all owners on all outcomes
        // / amount of tokens all owners put on the winning outcome

        uint256 currentAmount = MarsERC20OutcomeToken(tokenOutcomeAddress[winningOutcome]).balanceOf(msg.sender); //amount of tokens he has
        require(
            MarsERC20OutcomeToken(tokenOutcomeAddress[winningOutcome]).transferFrom(msg.sender, address(this), currentAmount),
            "MARS: FAILED TO TRANSFER FROM BUYER"
        );

        require(IERC20(token).transfer(msg.sender, reward), "MARS: FAILED TO TRANSFER TO BUYER");
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
        require(block.timestamp < predictionTimeEnd, "MARS: PREDICTION TIME HAS PASSED");
        require(IERC20(token).transferFrom(msg.sender, address(this), _amount), "MARS: FAILED TO TRANSFER FROM BUYER");

        uint256 _amountWithFee = (_amount * notFee * 1_000_000) / feeDivisor / getSharePrice(block.timestamp);

        require(
            MarsERC20OutcomeToken(tokenOutcomeAddress[_outcome]).mint(msg.sender, _amountWithFee, (_amount * notFee) / feeDivisor),
            "MARS: FAILED TO TRANSFER TO BUYER"
        );
        totalPredicted += (_amount * notFee) / feeDivisor;

        require(isPredictionProfitable(_outcome, block.timestamp), "Prediction is not profitable");
        emit PredictionEvent(msg.sender, _outcome, _amountWithFee);
    }

    function isPredictionProfitable(bytes16 _outcome, uint256 _currentTime) public view returns (bool) {
        uint256 outcomeBalance = MarsERC20OutcomeToken(tokenOutcomeAddress[_outcome]).totalSupply();

        if (outcomeBalance != 0)
            return !((getSharePrice(_currentTime) * notFee) / feeDivisor > (totalPredicted * 1_000_000) / outcomeBalance + 1); //+1 in case of rounding
        return true;
    }

    function getTokens() external view override returns (address[] memory) {
        return outcomeTokens;
    }

    modifier outcomeDefined(bytes16 _outcome) {
        require(tokenOutcomeAddress[_outcome] != address(0), "MARS: OUTCOME NOT DEFINED");
        _;
    }

    function setSettlement(address _newSettlement) external override onlyOwner {
        settlement = ISettlement(_newSettlement);
    }
}
