// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "./HighRollerNFT.sol";

/**
 * @title PotCoin High Roller Vault
 * @dev Vault for users to deposit PotCoin (POT) and participate in NFT raffles
 *      Integrates Chainlink VRF v2.5 for randomness
 */
contract PotCoinHighRollerVault is VRFConsumerBaseV2Plus {
    using VRFV2PlusClient for VRFV2PlusClient.RandomWordsRequest;

    HighRollerNFT public highRollerNFT; // NFT contract interface
    IERC20 public potCoin; // PotCoin (POT) ERC20 token interface
    uint256 public constant MINIMUM_HOLDING = 1 * 10**18; // 100,000 POT for testing
    uint256 public constant HOLDING_PERIOD = 5 * 60; // 5 minutes in seconds

    // Chainlink VRF variables
    mapping(uint256 => bool) private requests; // Track request IDs

    // Subscription ID
    uint256 public s_subscriptionId;

    // VRF Coordinator address and keyHash
    bytes32 public keyHash;

    // VRF request parameters
    uint32 public callbackGasLimit = 2500000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords;

    // Structure to store participant data
    struct Participant {
        uint256 depositedAt;
        uint256 amount;
    }

    mapping(address => Participant) public participants; // Mapping to track participants' data
    address[] public eligibleParticipants; // List of eligible participants for the raffle

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event RandomnessRequested(uint256 requestId);
    event RandomnessFulfilled(uint256 requestId, uint256[] randomWords);
    event WinnerSelected(address indexed winner, uint256 nftId);

    /**
     * @dev Constructor to initialize contract parameters
     */
    constructor(
        HighRollerNFT _highRollerNFT,
        IERC20 _potCoin,
        uint256 subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    )
        VRFConsumerBaseV2Plus(_vrfCoordinator)
    {
        potCoin = _potCoin;
        highRollerNFT = _highRollerNFT;
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
    }

    /**
     * @dev Allows a user to deposit PotCoin into the vault
     */
    function deposit(uint256 _amount) external {
        require(_amount >= MINIMUM_HOLDING, "Must deposit at least 100,000 POT");

        // Transfer PotCoin tokens to the contract
        potCoin.transferFrom(msg.sender, address(this), _amount);

        Participant storage participant = participants[msg.sender];

        // Update participant data
        participant.amount += _amount;
        participant.depositedAt = block.timestamp;

        // Add to eligibility list if new participant
        if (participant.amount == _amount) {
            eligibleParticipants.push(msg.sender);
        }

        emit Deposit(msg.sender, _amount);
    }

    /**
     * @dev Allows a user to withdraw PotCoin from the vault
     */
    function withdraw(uint256 _amount) external {
        Participant storage participant = participants[msg.sender];

        // Ensure that the participant has enough balance to withdraw
        require(participant.amount >= _amount, "Insufficient balance");

        // Ensure that the holding period of 5 minutes is respected
        require(block.timestamp >= participant.depositedAt + HOLDING_PERIOD, "Cannot withdraw before 5 minutes");

        // Update the participant's amount after successful withdrawal
        participant.amount -= _amount;

        // Remove from eligible participants if amount is less than MINIMUM_HOLDING
        if (participant.amount < MINIMUM_HOLDING) {
            _removeFromEligibleParticipants(msg.sender);
        }

        // Transfer PotCoin back to the participant
        potCoin.transfer(msg.sender, _amount);

        emit Withdrawal(msg.sender, _amount);
    }

    function _removeFromEligibleParticipants(address user) internal {
        uint256 length = eligibleParticipants.length;
        for (uint256 i = 0; i < length; i++) {
            if (eligibleParticipants[i] == user) {
                eligibleParticipants[i] = eligibleParticipants[length - 1];
                eligibleParticipants.pop();
                break;
            }
        }
    }

    /**
     * @dev Check if a participant is eligible for the NFT raffles
     */
    function isEligible(address user) public view returns (bool) {
        Participant memory participant = participants[user];
        return participant.amount >= MINIMUM_HOLDING && (block.timestamp - participant.depositedAt) >= HOLDING_PERIOD;
    }

    /**
     * @dev Requests randomness from Chainlink VRF v2.5 and draws winners
     */
    function drawWinner(uint32 _numWords, bool enableNativePayment) external onlyOwner returns (uint256 requestId) {
        require(eligibleParticipants.length > 0, "No eligible participants");
        require(_numWords <= eligibleParticipants.length, "More winners than participants");

        numWords = _numWords;

        VRFV2PlusClient.ExtraArgsV1 memory extraArgs = VRFV2PlusClient.ExtraArgsV1({
            nativePayment: enableNativePayment
        });
        bytes memory packedExtraArgs = VRFV2PlusClient._argsToBytes(extraArgs);

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: packedExtraArgs
            })
        );

        requests[requestId] = true;
        emit RandomnessRequested(requestId);
        return requestId;
    }

    /**
     * @dev Callback function used by Chainlink VRF v2.5 to return random values
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        require(requests[requestId], "Request ID not found");
        uint256 participantsCount = eligibleParticipants.length;
        require(participantsCount > 0, "No eligible participants");
        require(randomWords.length <= participantsCount, "More winners than participants");

        // Use the random words to select winners
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 randIndex = randomWords[i] % participantsCount;
            address winner = eligibleParticipants[randIndex];

            // Mint NFT to the winner
            highRollerNFT.mint(winner);

            emit WinnerSelected(winner, i);

            // Remove the winner from eligible participants to prevent duplicate wins
            eligibleParticipants[randIndex] = eligibleParticipants[participantsCount - 1];
            eligibleParticipants.pop();
            participantsCount--;
        }

        emit RandomnessFulfilled(requestId, randomWords);
        delete requests[requestId];
    }

    function getParticipants() external view returns (address[] memory, Participant[] memory) {
        uint256 numParticipants = eligibleParticipants.length;
        Participant[] memory participantData = new Participant[](numParticipants);

        for (uint256 i = 0; i < numParticipants; i++) {
            participantData[i] = participants[eligibleParticipants[i]];
        }

        return (eligibleParticipants, participantData);
    }

    /**
     * @dev Function to set the VRF parameters if needed
     */
    function setVRFParameters(
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) external onlyOwner {
        keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    /**
     * @dev Fallback function to accept MATIC payments (required for native payments with Chainlink VRF)
     */
    receive() external payable {}
}
