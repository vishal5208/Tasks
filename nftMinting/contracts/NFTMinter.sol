// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract NFTMinter is ERC721, Ownable {
    struct WhitelistPhase {
        uint256 phaseStartTime;
        uint256 phaseEndTime;
        mapping(address => bool) whitelist;
    }

    uint256 private tokenIdCounter = 1;
    mapping(uint256 => WhitelistPhase) private whitelistPhases;

    uint256 private numPhases;

    // events
    event NewPhaseAdded(
        uint indexed phaseId,
        uint indexed startTimeStamp,
        uint indexed endTimeStamp
    );

    event UpdatedWhiteList(
        uint indexed phaseId,
        address indexed wallet,
        bool isWhiteListed
    );

    event CurrentPhaseUpdated(uint indexed currentPhase);

    constructor() ERC721("VishalD", "VD") {}

    // Modifiers
    modifier onlyWhitelisted() {
        require(
            isWhitelistedForCurrentPhase(msg.sender),
            "Only whitelisted addresses can mint NFTs"
        );
        _;
    }

    modifier phaseIsActive() {
        require(isCurrentPhaseActive(), "Phase is not currently active");
        _;
    }

    // onyly owner can add new pahse
    function addPhase(uint256 startTime, uint256 endTime) public onlyOwner {
        require(startTime > block.timestamp, "Add suitable start time");
        require(
            endTime == 0 || endTime >= startTime,
            "End time must be greater than or equal to start time"
        );

        numPhases++;
        whitelistPhases[numPhases].phaseStartTime = startTime;
        whitelistPhases[numPhases].phaseEndTime = endTime;

        emit NewPhaseAdded(numPhases, startTime, endTime);
    }

    // adding whitelisted addresses for the specific phase
    function updateWhitelistForPhase(
        address wallet,
        uint256 phaseId,
        bool isWhitelisted
    ) external onlyOwner {
        require(phaseId > 0 && phaseId <= numPhases, "Invalid phase ID");
        require(wallet != address(0), "Invalid wallet address");

        whitelistPhases[phaseId].whitelist[wallet] = isWhitelisted;
        emit UpdatedWhiteList(phaseId, wallet, isWhitelisted);
    }

    // for the provided phase, check if the wallet is whitelisted or not
    function isWhitelistedForPhase(
        address wallet,
        uint256 phaseId
    ) public view returns (bool) {
        require(phaseId > 0 && phaseId <= numPhases, "Invalid phase ID");
        require(wallet != address(0), "Invalid wallet address");

        return whitelistPhases[phaseId].whitelist[wallet];
    }

    // for the ongoing phase, check if the wallet is whitelisted or not
    function isWhitelistedForCurrentPhase(
        address wallet
    ) public view returns (bool) {
        uint256 currentPhaseId = getCurrentPhaseId();
        require(currentPhaseId > 0, "Current phase is 0");
        return isWhitelistedForPhase(wallet, currentPhaseId);
    }

    // check if the ongoing phase is active or not
    function isCurrentPhaseActive() public view returns (bool) {
        uint256 currentPhaseId = getCurrentPhaseId();

        require(currentPhaseId > 0, "Current phase is 0");

        WhitelistPhase storage phase = whitelistPhases[currentPhaseId];
        uint256 currentTimestamp = block.timestamp;

        if (
            currentTimestamp >= phase.phaseStartTime &&
            (phase.phaseEndTime == 0 || currentTimestamp <= phase.phaseEndTime)
        ) {
            return true;
        }

        return false;
    }

    // for the ongoing phase, whitelisted members can mint the NFT
    function mintNFT() external onlyWhitelisted phaseIsActive {
        uint256 tokenId = tokenIdCounter;
        tokenIdCounter++;
        _safeMint(msg.sender, tokenId);
    }

    ///// getter functions

    function getNumPhases() public view returns (uint256) {
        return numPhases;
    }

    function getWhitelistPhases(
        uint256 phaseId
    ) public view returns (uint256, uint256) {
        require(phaseId > 0 && phaseId <= numPhases, "Invalid phase ID");
        WhitelistPhase storage phase = whitelistPhases[phaseId];
        return (phase.phaseStartTime, phase.phaseEndTime);
    }

    function getWhitelist(
        address wallet,
        uint256 phaseId
    ) external view returns (bool) {
        require(phaseId > 0 && phaseId <= numPhases, "Invalid phase ID");
        return whitelistPhases[phaseId].whitelist[wallet];
    }

    function getCurrentPhaseId() public view returns (uint256) {
        uint256 currentTimestamp = block.timestamp;

        for (uint256 i = 1; i <= numPhases; i++) {
            WhitelistPhase storage phase = whitelistPhases[i];

            if (
                currentTimestamp >= phase.phaseStartTime &&
                currentTimestamp <= phase.phaseEndTime
            ) {
                return i;
            }
        }

        return 0; // No active phase
    }
}
