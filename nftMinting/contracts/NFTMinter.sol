// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMinter is ERC721, Ownable {
    struct WhitelistPhase {
        uint256 phaseStartTime;
        uint256 phaseEndTime;
        mapping(address => bool) whitelist;
    }

    uint256 private currentPhase;
    mapping(uint256 => WhitelistPhase) private whitelistPhases;

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

    constructor(uint256 startTime, uint256 endTime) ERC721("VishalD", "VD") {
        require(startTime > block.timestamp, "Add suitable start time");
        require(
            endTime == 0 || endTime >= startTime,
            "End time must be greater than or equal to start time"
        );

        addPhase(startTime, endTime);
    }

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

        currentPhase++;
        whitelistPhases[currentPhase].phaseStartTime = startTime;
        whitelistPhases[currentPhase].phaseEndTime = endTime;

        emit NewPhaseAdded(currentPhase, startTime, endTime);
    }

    // adding whitelisted addresses for the specific phase
    function updateWhitelistForPhase(
        address wallet,
        uint256 phaseId,
        bool isWhitelisted
    ) external onlyOwner {
        require(phaseId > 0 && phaseId <= currentPhase, "Invalid phase ID");
        require(wallet != address(0), "Invalid wallet address");

        whitelistPhases[phaseId].whitelist[wallet] = isWhitelisted;
        emit UpdatedWhiteList(phaseId, wallet, isWhitelisted);
    }

    // for te provided phase, check if the wallet is whitelisted or not
    function isWhitelistedForPhase(
        address wallet,
        uint256 phaseId
    ) public view returns (bool) {
        require(phaseId > 0 && phaseId <= currentPhase, "Invalid phase ID");
        require(wallet != address(0), "Invalid wallet address");

        return whitelistPhases[phaseId].whitelist[wallet];
    }

    // for the ongoing phase, check if the wallet whitelisted or not
    function isWhitelistedForCurrentPhase(
        address wallet
    ) public view returns (bool) {
        return isWhitelistedForPhase(wallet, currentPhase);
    }

    // check if the ongoing phase is active or not
    function isCurrentPhaseActive() public view returns (bool) {
        if (currentPhase == 0) {
            return false;
        }

        WhitelistPhase storage phase = whitelistPhases[currentPhase];
        if (block.timestamp >= phase.phaseStartTime) {
            if (
                phase.phaseEndTime == 0 || block.timestamp <= phase.phaseEndTime
            ) {
                return true;
            }
        }

        return false;
    }

    // for the ongoing phase, whitelisted members can mint the nft
    function mintNFT(
        address to,
        uint256 tokenId
    ) external onlyWhitelisted phaseIsActive {
        _safeMint(to, tokenId);
    }

    ///// getter functions

    function getWhitelistPhases(
        uint256 phaseId
    ) public view returns (uint256, uint256) {
        require(phaseId > 0 && phaseId <= currentPhase, "Invalid phase ID");
        WhitelistPhase storage phase = whitelistPhases[phaseId];
        return (phase.phaseStartTime, phase.phaseEndTime);
    }

    function getWhitelist(
        address wallet,
        uint256 phaseId
    ) external view returns (bool) {
        require(phaseId > 0 && phaseId <= currentPhase, "Invalid phase ID");
        return whitelistPhases[phaseId].whitelist[wallet];
    }

    function getCurrentPhase() external view returns (uint256) {
        return currentPhase;
    }
}
