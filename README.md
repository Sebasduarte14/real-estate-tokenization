# 🏠 Real Estate Tokenization Platform

> A decentralized system for fractional real estate ownership using ERC-1155 tokens. Property owners tokenize real estate assets, investors purchase fractions with stablecoins, and rental income is distributed proportionally to all token holders.

![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.20-363636?style=flat&logo=solidity&logoColor=white)
![Foundry](https://img.shields.io/badge/Foundry-FFD700?style=flat&logo=ethereum&logoColor=black)
![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-4776E6?style=flat&logo=openzeppelin&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

---

## 📋 Overview

Real estate is the largest asset class in the world, yet access remains limited to those with significant capital. This platform enables fractional ownership of properties by tokenizing them as ERC-1155 tokens on the Ethereum blockchain. A property worth $500,000 can be split into 10,000 fractions at $50 each — making real estate investment accessible to anyone.

Rental income flows on-chain: tenants pay in stablecoins, and smart contracts distribute rent proportionally to every fraction holder automatically. No intermediaries, no bank delays, fully transparent.

### How It Works

```
Admin registers property (1000 fractions @ 100 USDC each)
        │
        ▼
Investors purchase fractions with USDC
        │
        ▼
ERC-1155 tokens minted to buyers
        │
        ▼
Monthly rent deposited by admin
        │
   ┌────┴────┐
   ▼         ▼
Holder A    Holder B
owns 100    owns 50
fractions   fractions
(10%)       (5%)
   │         │
   ▼         ▼
Claims      Claims
10% rent    5% rent
```

## 🏗️ Architecture

The system follows a **separation of concerns** design with four specialized contracts:

```
┌──────────────────────────────────────────────────────────┐
│                    ADMIN (deployer)                       │
│  Registers properties · Sets roles · Deposits rent       │
└────────┬──────────────────┬──────────────────┬───────────┘
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────────┐ ┌───────────────┐ ┌─────────────────┐
│ PropertyRegistry│ │ PropertyToken │ │ RentDistributor  │
│                 │ │   (ERC-1155)  │ │                  │
│ • Register      │ │               │ │ • Deposit rent   │
│   properties    │◄┤ • Purchase    │ │ • Claim earnings │
│ • Store metadata│ │   fractions   │ │ • Proportional   │
│ • Track sales   │ │ • Mint tokens │ │   distribution   │
│ • Deactivate    │ │ • Withdraw    │ │                  │
└─────────────────┘ └───────┬───────┘ └──────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  Marketplace  │
                    │               │
                    │ • List tokens │
                    │ • Buy/sell    │
                    │ • Secondary   │
                    │   market      │
                    └───────────────┘

Token flow:  Investor → USDC → PropertyToken → ERC-1155 fractions
Rent flow:   Admin → USDC → RentDistributor → fraction holders
```

### Contract Roles & Permissions

| Role | Assigned To | Can Do |
|------|------------|--------|
| `DEFAULT_ADMIN_ROLE` | Deployer | Manage all roles |
| `ADMIN_ROLE` | Deployer | Register properties, set token contract |
| `OPERATOR_ROLE` | Operator | Deactivate properties |
| `TOKEN_MANAGER_ROLE` | PropertyToken contract | Update fractionsSold |

## 📦 Contracts

### PropertyRegistry.sol
The administrative backbone. Stores property data on-chain and controls which contracts can modify state. Properties are registered with total fractions, price per fraction, and a metadata URI pointing to off-chain data (images, legal docs, location) stored on IPFS.

### PropertyToken.sol (ERC-1155)
Handles fractional ownership. Each `tokenId` maps to a registered property, and the token supply represents the total fractions. Investors pay in ERC-20 stablecoins and receive ERC-1155 tokens representing their ownership share.

### RentDistributor.sol
Manages rental income distribution. The admin deposits rent payments in stablecoins, and fraction holders claim their proportional share based on their token balance at the time of distribution.

### Marketplace.sol
Secondary market for trading fractions between users. Sellers list fractions at their desired price, buyers purchase with stablecoins, and ownership transfers atomically.

## ⚙️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Solidity ^0.8.20 |
| Framework | Foundry |
| Token Standard | ERC-1155 (fractional ownership) |
| Payments | ERC-20 stablecoin (USDC/DAI compatible) |
| Access Control | OpenZeppelin AccessControl (role-based) |
| Ownership | OpenZeppelin Ownable |
| Architecture | Multi-contract with cross-contract communication |

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Git

### Setup

```bash
git clone https://github.com/Sebasduarte14/real-estate-tokenization.git
cd real-estate-tokenization

forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge build
forge test -vvv
```

### Deployment Flow

```bash
# 1. Start local node
anvil

# 2. Deploy contracts (in another terminal)
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

The deployment script handles the correct order:
1. Deploy a mock stablecoin (for testing)
2. Deploy PropertyRegistry
3. Deploy PropertyToken (with Registry and stablecoin addresses)
4. Deploy RentDistributor (with Token and stablecoin addresses)
5. Grant `TOKEN_MANAGER_ROLE` to PropertyToken via `setTokenContract()`

### Example Usage

```solidity
// Admin registers a property: 1000 fractions at 100 USDC each
registry.registerProperty(1000, 100e18, "ipfs://QmPropertyMetadata...");

// Admin connects the PropertyToken contract
registry.setTokenContract(address(propertyToken));

// Investor approves USDC spending
usdc.approve(address(propertyToken), 5000e18);

// Investor buys 50 fractions (cost: 50 × 100 = 5000 USDC)
propertyToken.purchaseFraction(1, 50);

// Admin deposits monthly rent (1000 USDC)
rentDistributor.depositRent(1, 1000e18);

// Investor claims proportional rent (50/1000 = 5% → 50 USDC)
rentDistributor.claimRent(1);
```

## 🔒 Security Considerations

- **Role-based access control** — Administrative functions protected by specific roles, not just ownership
- **Cross-contract permissions** — PropertyToken requires `TOKEN_MANAGER_ROLE` to update Registry state
- **Stablecoin payments** — Eliminates ETH price volatility risk for real estate valuations
- **Checks-Effects-Interactions** — State updates before external calls in all functions
- **Existence validation** — All functions verify property exists via `tokenId != 0` before operating

### Potential Improvements

- Add `ReentrancyGuard` to all functions with external calls
- Implement ERC-1155 `uri()` override to return per-property metadata from Registry
- Add property appreciation/depreciation mechanisms
- Implement KYC/whitelist for regulatory compliance (ERC-3643)
- Create a DAO governance layer for property management decisions
- Add support for multiple stablecoins per property
- Implement time-locked vesting for large fraction purchases

## 🧠 Design Decisions

**Why ERC-1155 over ERC-721 + ERC-20?**
ERC-1155 handles multiple token types in a single contract. Each property is a token ID with its own supply (fractions). This is more gas-efficient than deploying a separate ERC-20 per property and avoids the overhead of managing multiple contracts.

**Why separate Registry and Token contracts?**
Separation of concerns. The Registry handles data and administration, the Token handles ownership and transfers. This allows upgrading one without affecting the other, and keeps each contract focused on a single responsibility.

**Why stablecoins instead of ETH?**
Real estate prices are denominated in fiat currency. Using a stablecoin (USDC/DAI) ensures that a fraction priced at $100 remains at $100 regardless of crypto market volatility. This mirrors how real-world real estate transactions work.

**Why AccessControl over Ownable for the Registry?**
The Registry needs multiple permission levels: admins who register properties, operators who can pause them, and contracts that can update sales data. `Ownable` only supports a single owner — `AccessControl` provides the granular role system needed for a multi-actor platform.

## 📄 License

MIT

---

**Built by [Sebastián Duarte](https://github.com/Sebasduarte14)** — Blockchain Developer | Civil Engineer | Medellín, Colombia
