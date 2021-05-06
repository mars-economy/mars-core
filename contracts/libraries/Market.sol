// SPDX-License-Identifier: MIT

library Market {
    struct UserOutcomeInfo {
        bytes16 outcomeUuid;
        bool suspended;
        uint256 stakeAmount;
        uint256 currentReward;
        bool rewardReceived;
    }
}
