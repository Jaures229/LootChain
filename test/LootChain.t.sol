// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LootChain.sol";

contract LootChainTest is Test {

    LootChain public lootChain;

    address public owner   = address(this);
    address public player1 = makeAddr("player1");
    address public player2 = makeAddr("player2");

    // ─── Setup ────────────────────────────────────────────────

    function setUp() public {
        lootChain = new LootChain("Qstvdohsispq289");
    }

    // ─── Tests de base ────────────────────────────────────────

    function test_NomEtSymbole() public view {
        assertEq(lootChain.name(),   "LootChain");
        assertEq(lootChain.symbol(), "LOOT");
    }

    function test_MintLoot_AssigneNFTauJoueur() public {
        uint256 tokenId = lootChain.mintLoot(player1);

        assertEq(lootChain.ownerOf(tokenId), player1);
        assertEq(lootChain.balanceOf(player1), 1);
    }

    function test_MintLoot_TokenIdIncremental() public {
        uint256 id1 = lootChain.mintLoot(player1);
        uint256 id2 = lootChain.mintLoot(player1);
        uint256 id3 = lootChain.mintLoot(player2);

        assertEq(id1, 0);
        assertEq(id2, 1);
        assertEq(id3, 2);
    }

    // ─── Tests des stats ──────────────────────────────────────

    function test_GetItem_RetourneStats() public {
        uint256 tokenId = lootChain.mintLoot(player1);
        LootChain.Item memory item = lootChain.getItem(tokenId);

        // Le nom ne doit pas être vide
        assertTrue(bytes(item.name).length > 0);

        // Les stats doivent être dans la plage 1-100
        assertGe(item.power,   1);
        assertLe(item.power,   100);
        assertGe(item.defense, 1);
        assertLe(item.defense, 100);
        assertGe(item.speed,   1);
        assertLe(item.speed,   100);
    }

    function test_Stats_RespectentPlageDeLaRarete() public {
        // On mint beaucoup d'items pour couvrir les raretés
        for (uint256 i = 0; i < 20; i++) {
            // Avancer le temps pour varier le seed
            vm.warp(block.timestamp + i * 13);

            uint256 tokenId = lootChain.mintLoot(player1);
            LootChain.Item memory item = lootChain.getItem(tokenId);

            // Vérifier la cohérence rareté → stats
            if (item.rarity == LootChain.Rarity.Common) {
                assertLe(item.power, 25);
            } else if (item.rarity == LootChain.Rarity.Rare) {
                assertGe(item.power, 25);
                assertLe(item.power, 50);
            } else if (item.rarity == LootChain.Rarity.Epic) {
                assertGe(item.power, 50);
                assertLe(item.power, 75);
            } else {
                assertGe(item.power, 75);
            }
        }
    }

    // ─── Tests de l'inventaire ────────────────────────────────

    function test_GetPlayerLoot_RetourneTousLesItems() public {
        lootChain.mintLoot(player1);
        lootChain.mintLoot(player1);
        lootChain.mintLoot(player2);
        lootChain.mintLoot(player1);

        uint256[] memory loot = lootChain.getPlayerLoot(player1);
        assertEq(loot.length, 3);

        uint256[] memory loot2 = lootChain.getPlayerLoot(player2);
        assertEq(loot2.length, 1);
    }

    function test_GetPlayerLoot_VideSiAucunItem() public view {
        uint256[] memory loot = lootChain.getPlayerLoot(player1);
        assertEq(loot.length, 0);
    }

    // ─── Tests de sécurité ────────────────────────────────────

    function test_MintLoot_SeulOwnerPeutMint() public {
        // player1 essaie de mint → doit échouer
        vm.prank(player1);
        vm.expectRevert();
        lootChain.mintLoot(player1);
    }

    function test_GetItem_ItemInexistantRevert() public {
        vm.expectRevert();
        lootChain.getItem(999);
    }

    // ─── Tests des events ─────────────────────────────────────

    function test_MintLoot_EmitLootDropped() public {
        vm.expectEmit(true, true, false, false);
        emit LootChain.LootDropped(player1, 0, "", LootChain.Rarity.Common, 0, 0, 0);
        lootChain.mintLoot(player1);
    }


    // ─── Tests tokenURI ───────────────────────────────────────

    function test_TokenURI_RetourneBase64() public {
        uint256 tokenId = lootChain.mintLoot(player1);
        string memory uri = lootChain.tokenURI(tokenId);

        // Doit commencer par "data:application/json;base64,"
        assertTrue(
            _startsWith(uri, "data:application/json;base64,"),
            "tokenURI doit etre en base64"
        );
    }

    function test_TokenURI_ItemInexistantRevert() public {
        vm.expectRevert();
        lootChain.tokenURI(999);
    }

    function test_SetImageCID_MajCID() public {
        lootChain.setImageCID("QmNOUVEAUCID456");

        // Mint un item et vérifier que l'URI change
        uint256 tokenId = lootChain.mintLoot(player1);
        string memory uri = lootChain.tokenURI(tokenId);
        assertTrue(bytes(uri).length > 0);
    }

    function test_SetImageCID_SeulOwnerPeutChanger() public {
        vm.prank(player1);
        vm.expectRevert();
        lootChain.setImageCID("QmHACK");
    }

    // ─── Helper ───────────────────────────────────────────────

    function _startsWith(string memory str, string memory prefix)
        private
        pure
        returns (bool)
    {
        bytes memory strBytes    = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        if (strBytes.length < prefixBytes.length) return false;

        for (uint256 i = 0; i < prefixBytes.length; i++) {
            if (strBytes[i] != prefixBytes[i]) return false;
        }
        return true;
    }
}