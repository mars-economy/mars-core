// SPDX-License-Identifier: MIT

library Market {
    struct UserOutcomeInfo {
        bytes16 outcomeUuid;
        bool suspended;
        uint256 stakeAmount;
        uint256 currentReward;
        bool rewardReceived;
        uint256 sharePrice;
    }

    struct Outcome {
        bytes16 uuid;
        uint8 position;
        string name;
    }
}
