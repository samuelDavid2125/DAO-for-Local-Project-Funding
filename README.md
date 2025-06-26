# 🏛️ DAO for Local Project Funding

A decentralized autonomous organization (DAO) smart contract built on Stacks blockchain for funding local community projects through democratic governance.

## 🌟 Features

- 🗳️ **Democratic Voting**: Community members vote on local initiatives
- 💰 **Stake-based Governance**: Voting power based on member stakes
- 🎯 **Quorum Requirements**: Proposals need minimum participation to pass
- ⏰ **Time-bound Voting**: Configurable voting periods
- 🏦 **Treasury Management**: Secure fund management and distribution
- 📊 **Transparent Tracking**: Full visibility of proposals and votes

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Run `clarinet check` to verify the contract

## 📋 Usage Instructions

### 1. Join the DAO 🤝

```clarity
(contract-call? .DAO-for-Local-Project-Funding join-dao u1000000)
```

Stake STX tokens to become a voting member.

### 2. Fund the Treasury 💳

```clarity
(contract-call? .DAO-for-Local-Project-Funding deposit-treasury u5000000)
```

Add funds to the community treasury for project funding.

### 3. Create a Proposal 📝

```clarity
(contract-call? .DAO-for-Local-Project-Funding create-proposal 
  "School Internet Upgrade" 
  "Install high-speed internet in local elementary school" 
  u2000000 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

Submit proposals for community projects with funding requirements.

### 4. Vote on Proposals 🗳️

```clarity
(contract-call? .DAO-for-Local-Project-Funding vote-on-proposal u1 true)
```

Cast your vote (true for yes, false for no) on active proposals.

### 5. Execute Approved Proposals ✅

```clarity
(contract-call? .DAO-for-Local-Project-Funding execute-proposal u1)
```

Execute proposals that have passed voting and met quorum requirements.

## 🔍 Read-Only Functions

### Get Proposal Details
```clarity
(contract-call? .DAO-for-Local-Project-Funding get-proposal u1)
```

### Check DAO Statistics
```clarity
(contract-call? .DAO-for-Local-Project-Funding get-dao-stats)
```

### View Member Information
```clarity
(contract-call? .DAO-for-Local-Project-Funding get-member-stake 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Check Proposal Status
```clarity
(contract-call? .DAO-for-Local-Project-Funding get-proposal-status u1)
```

## ⚙️ Configuration

### Default Settings
- **Quorum**: 51% of total staked tokens
- **Voting Period**: 1440 blocks (~10 days)

### Admin Functions (Contract Owner Only)
- Set quorum percentage: `set-quorum-percentage`
- Modify voting period: `set-voting-period`

## 🏗️ Project Structure

```
├── contracts/
│   └── DAO-for-Local-Project-Funding.clar
├── tests/
├── settings/
└── README.md
```

## 🔐 Security Features

- ✅ Stake-based membership verification
- ✅ Double-voting prevention
- ✅ Time-bound proposal execution
- ✅ Quorum enforcement
- ✅ Owner-only administrative functions

## 🎯 Use Cases

- 🏫 School infrastructure improvements
- 🌐 Community internet installations  
- 🏥 Local healthcare facility upgrades
- 🛣️ Road and transportation projects
- 🌳 Environmental conservation initiatives

## 📊 Governance Process

1. **Proposal Creation** → Member submits project proposal
2. **Voting Period** → Community votes within time limit
3. **Quorum Check** → Verify minimum participation
4. **Execution** → Approved proposals receive funding
5. **Transparency** → All actions recorded on blockchain

## 🤝 Contributing

Contributions are welcome! Please ensure all changes maintain the contract's security and functionality.

## 📄 License

This project is open source and available under the MIT License.

---

*Built with ❤️ for local communities using Stacks blockchain technology*
```

## Git Commit Message

```

```

## GitHub Pull Request Title

```
🏛️ Add DAO Smart Contract for Community-Driven Local Project Funding
```

## GitHub Pull Request Description

```markdown
## 📋 Summary

This PR introduces a comprehensive DAO (Decentralized Autonomous Organization) smart contract for funding local community projects through democratic governance on the Stacks blockchain.

## ✨ What's Added

- **Complete
