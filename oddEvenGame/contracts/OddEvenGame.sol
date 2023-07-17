// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "hardhat/console.sol";

error OddEvenGame__NotEnoughEthEntered();
error OddEvenGame__TransferFailed();
error OddEvenGame__NotOpen();
error OddEvenGame__UpKeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);

contract OddEvenGame is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Types declarations */
    enum OddEvenGameState {
        OPEN,
        CALCULATING
    }

    /* State variables */
    uint256 private immutable i_entranceFee; // entrace fee
    Player[] private s_players; // dynamic array to store players and their bet
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    struct Player {
        address payable player;
        bool bet;
    }

    /* OddEvenGame variables */
    address private s_recentWinner;
    OddEvenGameState private s_lotteryState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /* Events */
    event OddEvenGameEnter(address indexed player);
    event RequestedOddEvenGameWinner(uint256 indexed requestID);
    event WinningAmountTranfered(uint256 winningAmount);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lotteryState = OddEvenGameState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    // odd -> false, even -> true
    function enterToOddEvenGame(bool bet) public payable {
        if (msg.value < i_entranceFee) {
            revert OddEvenGame__NotEnoughEthEntered();
        }

        if (s_lotteryState != OddEvenGameState.OPEN) {
            revert OddEvenGame__NotOpen();
        }

        s_players.push(Player(payable(msg.sender), bet));

        emit OddEvenGameEnter(msg.sender);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        // returns requestID which contrains who's in it and other information
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert OddEvenGame__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }

        s_lotteryState = OddEvenGameState.CALCULATING;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedOddEvenGameWinner(requestId);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upKeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (OddEvenGameState.OPEN == s_lotteryState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);

        upKeepNeeded = (isOpen && timePassed && hasBalance && hasPlayers);
        return (upKeepNeeded, "0x0");
    }

    function distributeWinnings(bool bet) private {
        uint256 totalPot = address(this).balance;
        uint256 winnersCount = 0;

        for (uint256 i = 0; i < s_players.length; i++) {
            Player memory player = s_players[i];

            if (player.bet == bet) {
                winnersCount += 1;
            }
        }

        uint256 winningsPerWinner = totalPot / winnersCount;

        for (uint256 i = 0; i < s_players.length; i++) {
            Player memory player = s_players[i];

            if (player.bet == bet) {
                (bool success, ) = player.player.call{value: winningsPerWinner}(
                    ""
                );

                if (!success) {
                    revert OddEvenGame__TransferFailed();
                }
            }
        }

        emit WinningAmountTranfered(winningsPerWinner);
        // Emit event with winner accounts
        address[] memory winners = getWinnerAccounts(bet);
        emit WinnersDeclared(winners);
    }

    event WinnersDeclared(address[] winners);

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        console.log("enterd the lottery");
        uint256 val = randomWords[0] % 2;
        if (val == 0) {
            distributeWinnings(false);
        } else {
            distributeWinnings(true);
        }

        // reset s_players
        delete s_players;
        s_lotteryState = OddEvenGameState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function getWinnerAccounts(
        bool bet
    ) public view returns (address[] memory) {
        uint256 winnersCount = 0;
        uint256[] memory winnerIndexes = new uint256[](s_players.length);

        for (uint256 i = 0; i < s_players.length; i++) {
            Player memory player = s_players[i];

            if (player.bet == bet) {
                winnerIndexes[winnersCount] = i;
                winnersCount += 1;
            }
        }

        address[] memory winners = new address[](winnersCount);

        for (uint256 i = 0; i < winnersCount; i++) {
            winners[i] = s_players[winnerIndexes[i]].player;
        }

        return winners;
    }

    /* View/Pure functions*/

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        Player memory player = s_players[index];
        return player.player;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getOddEvenGameState() public view returns (OddEvenGameState) {
        return s_lotteryState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
