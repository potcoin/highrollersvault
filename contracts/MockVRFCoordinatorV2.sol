// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MockVRFCoordinatorV2 {
    event RandomWordsRequested(
        bytes32 keyHash,
        uint64 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address sender
    );

    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId) {
        emit RandomWordsRequested(
            keyHash,
            subId,
            requestConfirmations,
            callbackGasLimit,
            numWords,
            msg.sender
        );
        return 1; // Mock requestId
    }

    function fulfillRandomWords(
        address consumer,
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        // Call the consumer contract's fulfillRandomWords function
        VRFConsumerBaseV2(consumer).fulfillRandomWords(requestId, randomWords);
    }
}

interface VRFConsumerBaseV2 {
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}
