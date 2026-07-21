// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LootChain.sol";

contract DeployLootChain is Script {
    function run() external {
        // Récupère la clé privée depuis les variables d'environnement
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        LootChain lootChain = new LootChain("bafybeicmmej3nu5b3gvlcwy2cj7lsppeby5rks76bgmzhwt222odck7pei");

        console.log("LootChain deploye a :", address(lootChain));
        console.log("Owner               :", msg.sender);

        vm.stopBroadcast();
    }
}
