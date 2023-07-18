// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WhiteList is Ownable {
    mapping(address => bool) public whiteListed;

    event WhiteListed(address addr, bool status);

    modifier areWhiteListed(address[] memory addrs) {
        for (uint i = 0; i < addrs.length; i++) {
            if (!whiteListed[addrs[i]]) revert();
        }
        _;
    }

    modifier areNotWhiteListed(address[] memory addrs) {
        for (uint i = 0; i < addrs.length; i++) {
            if (whiteListed[addrs[i]]) revert();
        }
        _;
    }

    function whitelist(address[] memory addrs) public {
        for (uint i = 0; i < addrs.length; i++) {
            if (whiteListed[addrs[i]]) {
                revert();
            }
            whiteListed[addrs[i]] = true;
        }
    }
}
