// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IPredictionMarket.sol";
import "./interfaces/IShareToken.sol";
import "./dependencies/tokens/IERC20.sol";
import "./dependencies/tokens/ERC20.sol";
import "./Settlement.sol";
import "./Owned.sol";

contract MarsPredictionMarket is IPredictionMarket, Owned {
    mapping(uint256 => IShareToken) public shareTokens;

    bytes16[] public outcomes;
    //list of outcomes
    address[] public outcomeTokens;
    //list of tokens

    uint256 public immutable predictionTimeEnd; //when buying stops
    uint256 public predictionMarketBalancingStart; //when 80:20 balancing beings, not yet implemented, should be immutable
    address public immutable token; //DAI or some other stable ERC20 token used to buy shares for outcomes
    bytes16 public winningOutcome;

    mapping(address => mapping(bytes16 => uint256)) userOutcomeTokens;
    //user => (outcomes => tokensBought)
    mapping(bytes16 => uint256) public outcomeBalance;
    //outcome => totalTokensSold
    mapping(bytes16 => address) public tokenOutcomeAddress;
    //outcome => address of token
    uint256 totalPredicted;
    //sum from all predictors on all outcomes
    mapping(address => bool) claimed;

    Settlement settlement;

    constructor(
        address _token,
        uint256 _predictionTimeEnd
    ) Owned(msg.sender) {
        predictionTimeEnd = _predictionTimeEnd;
        // predictionContractEnd // ADDME
        // predictionMarketBalancingStart // ADDME

        token = _token;
    }

    function addOutcome(
		bytes16 uuid, 
		uint8 position, 
		string memory name
	) external override onlyOwner {
        outcomes.push(uuid);
        address newToken = address(new ERC20(1_000_000_000_000_000_000_000_000_000, string(abi.encodePacked(uuid)), 18, "MPO"));
        outcomeTokens.push(newToken);
        tokenOutcomeAddress[uuid] = newToken;
    }

    function getWinningOutcome() internal returns (bytes16) {
        return settlement.getWinningOutcome(address(this));
    }

    function getReward() external override {
        winningOutcome = getWinningOutcome();
        // require(winningOutcome != "", "MARS: PREDICTION IS NOT YET CONCLUDED"); //obsolete?
        require(claimed[msg.sender] == false, "USER ALREADY CLAIMED");

        claimed[msg.sender] = true;

        uint256 reward = (userOutcomeTokens[msg.sender][winningOutcome] * totalPredicted) / outcomeBalance[winningOutcome];
        //amount of tokens the owner put on the winning outcome * amount of tokens put by all owners on all outcomes
        // / amount of tokens all owners put on the winning outcome

        uint256 currentAmount = IERC20(tokenOutcomeAddress[winningOutcome]).balanceOf(msg.sender); //amount of tokens he has
        require(
            IERC20(tokenOutcomeAddress[winningOutcome]).transferFrom(msg.sender, address(this), currentAmount),
            "MARS: FAILED TO TRANSFER FROM BUYER"
        );
        require(IERC20(token).transfer(msg.sender, reward), "MARS: FAILED TO TRANSFER TO BUYER");
    }

    function getNumberOfOutcomes() external view override returns (uint256) {
        return outcomes.length;
    }

    function getPredictionTimeEnd() external view override returns (uint256) {
        return predictionTimeEnd;
    }

    function getBalancingTimeStart() external view override returns (uint256) {
        return predictionMarketBalancingStart;
    }

    function predict(bytes16 _outcome, uint256 _amount) external override outcomeDefined(_outcome) {
        require(block.timestamp < predictionTimeEnd, "MARS: PREDICTION TIME HAS PASSED");

        emit Prediction(msg.sender, _outcome);

        require(IERC20(token).transferFrom(msg.sender, address(this), _amount), "MARS: FAILED TO TRANSFER FROM BUYER"); // TODO: discuss
        require(IERC20(tokenOutcomeAddress[_outcome]).transfer(msg.sender, _amount), "MARS: FAILED TO TRANSFER TO BUYER");

        userOutcomeTokens[msg.sender][_outcome] += _amount;
        outcomeBalance[_outcome] += _amount;
        totalPredicted += _amount;
    }

    function userOutcomeBalance(bytes16 _outcome) external view override returns (uint256) {
        return userOutcomeTokens[msg.sender][_outcome];
    }

    function getTokens() external view override returns (address[] memory) {
        return outcomeTokens;
    }

    modifier outcomeDefined(bytes16 _outcome) {
        require(!_outcomeDefined(_outcome), "MARS: OUTCOME NOT DEFINED");
        _;
    }

    function _outcomeDefined(bytes16 _outcome) internal view returns (bool) {
        return tokenOutcomeAddress[_outcome] == address(0);
    }

    function setSettlement(address _newSettlement) external override {
        settlement = Settlement(_newSettlement);
    }
}
