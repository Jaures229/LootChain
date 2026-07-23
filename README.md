# LootChain 🗡️

> NFT loot drop system on the Ethereum blockchain — ERC-721 items with on-chain stats and IPFS images.

## Overview

LootChain is a smart contract that simulates an RPG loot drop system on the blockchain. Each dropped item is a unique NFT with randomly generated stats (power, defense, speed) and a rarity tier. Item images are stored on IPFS via Pinata.

## Features

- 🎲 **Random loot generation** — stats and rarity derived from a pseudo-random seed
- ⚔️ **10 unique items** — 5 weapons and 5 armor pieces
- 💎 **4 rarity tiers** — Common (60%), Rare (25%), Epic (12%), Legendary (3%)
- 🖼️ **IPFS metadata** — images stored on IPFS, metadata encoded on-chain in Base64
- 🔐 **Access control** — only authorized minters can drop loot (MINTER_ROLE)
- ✅ **13/13 tests passing**

## Contracts

| Contract | Network | Address |
|---|---|---|
| `LootChain.sol` | Sepolia | `0xC7303adbea291ABc9D7D74DdB4268a63b679B755` |

## Items

| Weapons | Armor |
|---|---|
| Sword of Embers | Iron Shield |
| Frost Dagger | Dragon Scale |
| Thunder Axe | Phantom Cloak |
| Shadow Blade | Storm Gauntlets |
| Ancient Staff | Relic Armor |

## Rarity & Stats

| Rarity | Probability | Stat Range |
|---|---|---|
| Common | 60% | 1 – 24 |
| Rare | 25% | 25 – 49 |
| Epic | 12% | 50 – 74 |
| Legendary | 3% | 75 – 100 |

## Tech Stack

- **Solidity** `^0.8.20`
- **Foundry** (forge, cast, anvil)
- **OpenZeppelin** — ERC721, AccessControl, Base64, Strings
- **IPFS / Pinata** — decentralized image storage
- **Sepolia** testnet

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/)
- MetaMask wallet with Sepolia ETH
- Alchemy RPC URL
- Etherscan API key

### Installation

```bash
git clone https://github.com/Jaures229/LootChain
cd LootChain
forge install
```

### Environment setup

Create a `.env` file:

```
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_alchemy_url
ETHERSCAN_API_KEY=your_etherscan_key
```

### Run tests

```bash
forge test -vv
```

### Deploy

```bash
source .env
forge script script/DeployLootChain.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvv
```

## Contract Functions

### Write

| Function | Access | Description |
|---|---|---|
| `mintLoot(address player)` | MINTER_ROLE | Mint a random NFT item to a player |
| `setImageCID(string cid)` | Admin | Update the IPFS CID for item images |

### Read

| Function | Description |
|---|---|
| `getItem(uint256 tokenId)` | Returns the stats of an item |
| `getPlayerLoot(address player)` | Returns all token IDs owned by a player |
| `tokenURI(uint256 tokenId)` | Returns Base64-encoded JSON metadata |

## Project Structure

```
LootChain/
├── src/
│   └── LootChain.sol       # Main NFT contract
├── test/
│   └── LootChain.t.sol     # 13 tests
├── script/
│   └── DeployLootChain.s.sol
└── foundry.toml
```

## Part of the LootChain Ecosystem

```
LootChain       → NFT loot drop system       (this repo)
LootChain Shop  → Gold token + in-game shop
LootChain Game  → 2D Unity game (coming soon)
```

---