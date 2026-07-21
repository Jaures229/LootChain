// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LootChain is ERC721, Ownable {

    // ─── Structures ───────────────────────────────────────────
    
    enum Rarity { Common, Rare, Epic, Legendary }

    struct Item {
        string  name;
        Rarity  rarity;
        uint8   power;      // 1 - 100
        uint8   defense;    // 1 - 100
        uint8   speed;      // 1 - 100
    }

    // ─── Storage ──────────────────────────────────────────────

    uint256 private _nextTokenId;

    mapping(uint256 => Item) private _items;

    // Noms possibles par type d'item
    string[5] private _weaponNames = [
        "Sword of Embers",
        "Frost Dagger",
        "Thunder Axe",
        "Shadow Blade",
        "Ancient Staff"
    ];

    string[5] private _armorNames = [
        "Iron Shield",
        "Dragon Scale",
        "Phantom Cloak",
        "Storm Gauntlets",
        "Relic Armor"
    ];

    // CID du dossier images sur IPFS
    string private _imageCID;
    // ─── Events ───────────────────────────────────────────────

    event LootDropped(
        address indexed player,
        uint256 indexed tokenId,
        string  name,
        Rarity  rarity,
        uint8   power,
        uint8   defense,
        uint8   speed
    );

    // ─── Constructor ──────────────────────────────────────────

    constructor(string memory baseURI_) ERC721("LootChain", "LOOT") Ownable(msg.sender) {
        _imageCID = baseURI_;
    }

    // ─── Fonctions principales ────────────────────────────────

    /// @notice Mint un item aléatoire pour un joueur
    /// @dev Seul le owner (serveur de jeu) peut appeler cette fonction
    function mintLoot(address player) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;

        // Génération pseudo-aléatoire basée sur les données du block
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            player,
            tokenId
        )));

        _items[tokenId] = _generateItem(seed);
        _safeMint(player, tokenId);

        Item memory item = _items[tokenId];
        emit LootDropped(player, tokenId, item.name, item.rarity, item.power, item.defense, item.speed);

        return tokenId;
    }

    /// @notice Retourne les stats d'un item
    function getItem(uint256 tokenId) external view returns (Item memory) {
        require(ownerOf(tokenId) != address(0), "Item inexistant");
        return _items[tokenId];
    }

    /// @notice Retourne tous les tokenIds appartenant a un joueur
    function getPlayerLoot(address player) external view returns (uint256[] memory) {
        uint256 total = _nextTokenId;
        uint256 count = balanceOf(player);
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < total; i++) {
            if (ownerOf(i) == player) {
                result[index++] = i;
            }
        }
        return result;
    }

    // ─── Logique interne ──────────────────────────────────────

    function _generateItem(uint256 seed) private view returns (Item memory) {
        // Rareté : Common 60% | Rare 25% | Epic 12% | Legendary 3%
        uint256 rarityRoll = seed % 100;
        Rarity rarity;

        if      (rarityRoll < 60) rarity = Rarity.Common;
        else if (rarityRoll < 85) rarity = Rarity.Rare;
        else if (rarityRoll < 97) rarity = Rarity.Epic;
        else                      rarity = Rarity.Legendary;

        // Nom : arme ou armure selon le seed
        bool isWeapon = (seed >> 8) % 2 == 0;
        string memory name = isWeapon
            ? _weaponNames[(seed >> 16) % 5]
            : _armorNames[(seed >> 16) % 5];

        // Stats : plage selon la rareté
        uint8 baseMin  = _baseMin(rarity);
        uint8 baseMax  = _baseMax(rarity);
        uint8 range    = baseMax - baseMin;

        uint8 power   = baseMin + uint8((seed >> 24) % range);
        uint8 defense = baseMin + uint8((seed >> 32) % range);
        uint8 speed   = baseMin + uint8((seed >> 40) % range);

        return Item(name, rarity, power, defense, speed);
    }

    function _baseMin(Rarity rarity) private pure returns (uint8) {
        if (rarity == Rarity.Common)    return 1;
        if (rarity == Rarity.Rare)      return 25;
        if (rarity == Rarity.Epic)      return 50;
        return 75; // Legendary
    }

    function _baseMax(Rarity rarity) private pure returns (uint8) {
        if (rarity == Rarity.Common)    return 25;
        if (rarity == Rarity.Rare)      return 50;
        if (rarity == Rarity.Epic)      return 75;
        return 100; // Legendary
    }

    // ─── Métadonnées ──────────────────────────────────────────

    /// @notice Retourne l'URI des métadonnées du NFT
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(ownerOf(tokenId) != address(0), "Item inexistant");

        Item memory item = _items[tokenId];

        // Construction du JSON en mémoire
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{',
                '"name": "',         item.name,                    '",',
                '"description": "A powerful item from LootChain.", ',
                '"image": "ipfs://', _imageCID, '/',
                                    _itemImageName(item.name),    '",',
                '"attributes": [',
                    '{"trait_type": "Rarity",  "value": "', _rarityName(item.rarity), '"},',
                    '{"trait_type": "Power",   "value": ',  Strings.toString(item.power),   '},',
                    '{"trait_type": "Defense", "value": ',  Strings.toString(item.defense), '},',
                    '{"trait_type": "Speed",   "value": ',  Strings.toString(item.speed),   '}',
                ']',
            '}'
        ))));

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /// @notice Met à jour le CID IPFS des images (si on change les assets)
    function setImageCID(string calldata newCID) external onlyOwner {
        _imageCID = newCID;
    }

    // ─── Helpers privés ───────────────────────────────────────

    function _rarityName(Rarity rarity) private pure returns (string memory) {
        if (rarity == Rarity.Common)    return "Common";
        if (rarity == Rarity.Rare)      return "Rare";
        if (rarity == Rarity.Epic)      return "Epic";
        return "Legendary";
    }

    function _itemImageName(string memory name) private pure returns (string memory) {
        // Mappe le nom de l'item vers son fichier image
        if (keccak256(bytes(name)) == keccak256(bytes("Sword of Embers")))  return "sword_of_embers.png";
        if (keccak256(bytes(name)) == keccak256(bytes("Frost Dagger")))     return "frost_dagger.png";
        if (keccak256(bytes(name)) == keccak256(bytes("Thunder Axe")))      return "thunder_axe.png";
        if (keccak256(bytes(name)) == keccak256(bytes("Shadow Blade")))     return "shadow_blade.png";
        if (keccak256(bytes(name)) == keccak256(bytes("Ancient Staff")))    return "ancient_staff.png";
        if (keccak256(bytes(name)) == keccak256(bytes("Iron Shield")))      return "iron_shield.png";
        if (keccak256(bytes(name)) == keccak256(bytes("Dragon Scale")))     return "dragon_scale.png";
        if (keccak256(bytes(name)) == keccak256(bytes("Phantom Cloak")))    return "phantom_cloak.png";
        if (keccak256(bytes(name)) == keccak256(bytes("Storm Gauntlets")))  return "storm_gauntlets.png";
        return "relic_armor.png";
    }
}
