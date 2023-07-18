// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WhiteList.sol";

contract NFTMinter is ERC721, Ownable {
    struct WhitelistPhase {
        uint256 phaseStartTime;
        uint256 phaseEndTime;
        mapping(address => bool) whitelist;
    }

    uint256 private currentPhase;
    mapping(uint256 => WhitelistPhase) private whitelistPhases;

    constructor() ERC721("MyNFT", "NFT") {
        addPhase(block.timestamp, 0); // Initial phase with no end time
    }

    modifier onlyWhitelisted() {
        require(
            isWhitelisted(msg.sender),
            "Only whitelisted addresses can mint NFTs"
        );
        _;
    }

    function addPhase(uint256 startTime, uint256 endTime) internal {
        currentPhase++;
        whitelistPhases[currentPhase].phaseStartTime = startTime;
        whitelistPhases[currentPhase].phaseEndTime = endTime;
    }

    function addToWhitelist(address wallet) external onlyOwner {
        require(
            currentPhase > 0,
            "No phase available. Please add a phase first."
        );
        whitelistPhases[currentPhase].whitelist[wallet] = true;
    }

    function removeFromWhitelist(address wallet) external onlyOwner {
        require(
            currentPhase > 0,
            "No phase available. Please add a phase first."
        );
        whitelistPhases[currentPhase].whitelist[wallet] = false;
    }

    function isWhitelisted(address wallet) public view returns (bool) {
        for (uint256 i = currentPhase; i > 0; i--) {
            if (block.timestamp >= whitelistPhases[i].phaseStartTime) {
                if (
                    whitelistPhases[i].phaseEndTime == 0 ||
                    block.timestamp <= whitelistPhases[i].phaseEndTime
                ) {
                    return whitelistPhases[i].whitelist[wallet];
                }
            }
        }
        return false;
    }

    function mintNFT(address to, uint256 tokenId) external onlyWhitelisted {
        _safeMint(to, tokenId);
    }
}
