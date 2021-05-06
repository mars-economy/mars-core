// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IPredictionMarket.sol";
import "./interfaces/IShareToken.sol";
import "./dependencies/tokens/MarsERC20OutcomeToken.sol";
import "./Settlement.sol";
import "./Owned.sol";
import "./libraries/Market.sol";

import "hardhat/console.sol"; //TODO: REMOVE

contract MarsPredictionMarket is IPredictionMarket, Owned {
    bytes16[] public outcomes;
    //list of outcomes
    address[] public outcomeTokens;
    //list of tokens

    uint256 public immutable predictionTimeEnd; //when buying stops
    uint256 public predictionMarketBalancingStart; //when 80:20 balancing beings, not yet implemented, should be immutable
    address public immutable token; //DAI or some other stable ERC20 token used to buy shares for outcomes
    bytes16 public winningOutcome;
    uint256 public fee = 9970; // 0.03%, 100 = 1%
    uint256 public feeDivisor = 10000;

    mapping(bytes16 => address) public tokenOutcomeAddress;
    //outcome => address of token
    uint256 totalPredicted;
    //sum from all predictors on all outcomes
    mapping(address => bool) claimed;

    Settlement settlement;
    address governance;

    constructor(
        address _token,
        uint256 _predictionTimeEnd,
        address _settlement
    ) Owned(msg.sender) {
        predictionTimeEnd = _predictionTimeEnd;
        // predictionContractEnd // ADDME
        // predictionMarketBalancingStart // ADDME

        settlement = Settlement(_settlement);
        token = _token;

        governance = msg.sender;
    }

    function getUserPredictionState() external view override returns (UserOutcomeInfo[] memory) {
        UserOutcomeInfo[] memory app = new UserOutcomeInfo[](outcomes.length);

        for (uint256 i = 0; i < outcomes.length; i++) {
            app[i].outcomeUuid = outcomes[i];
            app[i].stakeAmount = IERC20(tokenOutcomeAddress[outcomes[i]]).balanceOf(msg.sender);
            uint256 totalSupply = IERC20(tokenOutcomeAddress[outcomes[i]]).totalSupply();
            if (totalSupply != 0) {
                uint256 amount =
                    ((IERC20(tokenOutcomeAddress[outcomes[i]]).balanceOf(msg.sender) * totalPredicted) /
                        IERC20(tokenOutcomeAddress[outcomes[i]]).totalSupply());
                if (winningOutcome == bytes16(0) || winningOutcome == outcomes[i]) app[i].currentReward = amount;
            }
            //else app[i].currentReward = 0, but that goes by default
            app[i].rewardReceived = outcomes[i] == winningOutcome ? claimed[msg.sender] : false;
        }
        return app;
    }

    function addOutcome(
        bytes16 uuid,
        uint8 position,
        string memory name
    ) external override onlyOwner {
        outcomes.push(uuid);
        address newToken = address(new MarsERC20OutcomeToken(string(abi.encodePacked(uuid)), 18, "MPO")); // IERC20(token).decimals
        outcomeTokens.push(newToken);
        tokenOutcomeAddress[uuid] = newToken;
    }

    function getWinningOutcome() internal returns (bytes16) {
        winningOutcome = settlement.getWinningOutcome(address(this));
        return winningOutcome;
    }

    function getReward() external override {
        winningOutcome = winningOutcome != bytes16(0) ? winningOutcome : getWinningOutcome();
        // require(winningOutcome != "", "MARS: PREDICTION IS NOT YET CONCLUDED"); //obsolete?
        require(claimed[msg.sender] == false, "USER ALREADY CLAIMED");

        claimed[msg.sender] = true;

        uint256 userOutcomeTokens = MarsERC20OutcomeToken(tokenOutcomeAddress[winningOutcome]).balanceOf(msg.sender);
        uint256 outcomeBalance = MarsERC20OutcomeToken(tokenOutcomeAddress[winningOutcome]).totalSupply();

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

        require(IERC20(token).transferFrom(msg.sender, address(this), _amount), "MARS: FAILED TO TRANSFER FROM BUYER"); // TODO: discuss

        uint256[] memory tokensAmount = new uint256[](outcomes.length);
        uint256 maxValue;
        uint256 sumOfOthers;

        //add protocol fee
        uint256 _amountWithFee = (_amount * fee) / feeDivisor;

        if (false) {
            //if date has passed or flag set
            for (uint256 i = 0; i < outcomes.length; i++) {
                //find most predicted outcome
                tokensAmount[i] = IERC20(tokenOutcomeAddress[outcomes[i]]).totalSupply();
                sumOfOthers += tokensAmount[i];
                if (tokensAmount[i] > maxValue) {
                    maxValue = tokensAmount[i];
                }
            }

            require(maxValue + _amount > ((totalPredicted + _amount) * 4) / 5); //calculate if most predicted outcome is > 80% bought then all others
            require(
                MarsERC20OutcomeToken(tokenOutcomeAddress[_outcome]).mint(msg.sender, _amountWithFee),
                "MARS: FAILED TO TRANSFER TO BUYER"
            );
            emit PredictionEvent(msg.sender, _outcome, _amountWithFee);
            totalPredicted += _amountWithFee;
        } else {
            require(
                MarsERC20OutcomeToken(tokenOutcomeAddress[_outcome]).mint(msg.sender, _amountWithFee),
                "MARS: FAILED TO TRANSFER TO BUYER"
            );
            emit PredictionEvent(msg.sender, _outcome, _amountWithFee);
            totalPredicted += _amountWithFee;
        }
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
        require(msg.sender == governance, "ONLY GOVERNER CAN DO THIS ACTION");
        settlement = Settlement(_newSettlement);
    }
}
