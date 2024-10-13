# PotCoin High Rollers Vault

## Project Description

The **PotCoin High Rollers Vault** is a decentralized raffle system that allows PotCoin (POT) holders to participate in exclusive NFT giveaways. By depositing a minimum of 100,000 POT into the High Rollers Vault (powered by the ERC-4626 vault standard), users are automatically entered into raffles where every PotCoin in the vault represents one chance to win.

The system is designed for transparency and security, allowing users to participate without a lock-up period, though a minimum holding period of 30 days is required for eligibility in giveaways. Winners receive High Roller NFTs directly in their wallets, and these NFTs can be auctioned on platforms like OpenSea.

### Key Features:
- **ERC-4626 Vault**: Secure and transparent vault standard for handling deposits.
- **NFT Giveaways**: Eligible participants are entered into NFT raffles based on the amount of POT held in the vault.
- **Multiple Winner Support**: The system supports selecting multiple winners in a single raffle.
- **No Lock-up Period**: Users can withdraw their tokens anytime but must meet a 30-day minimum holding period to be eligible for raffles.
- **Fully Decentralized**: The system is managed through smart contracts on the Ethereum blockchain.

## Files Description

### 1. `PotCoinHighRollerVault.sol`
This is the core smart contract that implements the High Rollers Vault system. It is responsible for managing PotCoin deposits, checking eligibility for the giveaways, and distributing NFTs to winners. Key components include:
- **depositPot**: Allows users to deposit PotCoins into the vault.
- **withdrawPot**: Enables users to withdraw their PotCoins from the vault.
- **drawWinner**: Admin-only function to select multiple winners for the NFT giveaways.
- **isEligible**: Function to check if a user meets the eligibility criteria (minimum 100,000 POT and 30-day holding period).

### 2. `IERC20.sol`
This is the interface for the ERC-20 token standard, used by the smart contract to interact with PotCoin (POT). This file defines the basic functions like `transfer` and `transferFrom` required for token transfers between users and the vault.

### 3. `ERC721.sol`
This is the interface for the ERC-721 token standard, used by the smart contract to mint and distribute High Roller NFTs. Each NFT is a unique token given to winners of the raffles.

### 4. `ERC4626.sol`
This is the interface for the ERC-4626 tokenized vault standard. It ensures that the vault operates securely and transparently, allowing deposits, withdrawals, and participation in the NFT raffles.

### 5. `Ownable.sol`
This is a utility contract that ensures that only the contract owner can call certain functions, like `drawWinner`, to maintain security over the NFT distribution process.

## Deployment Instructions

### Prerequisites

To deploy this smart contract, ensure that you have the following:
- **Node.js** and **npm** (for package management)
- **Hardhat** (for smart contract deployment)
- **MetaMask** or another wallet with access to an Ethereum-compatible network (e.g., Ethereum, Polygon)
- **PotCoin (POT)**: The ERC-20 PotCoin token contract address.
- **High Roller NFT Contract**: The ERC-721 contract address for High Roller NFTs.

### Step-by-Step Deployment

1. **Clone the repository**:
    ```bash
    git clone https://github.com/your-repo/PotCoinHighRollerVault.git
    cd PotCoinHighRollerVault
    ```

2. **Install dependencies**:
    Make sure you have Hardhat and OpenZeppelin libraries installed.
    ```bash
    npm install
    ```

3. **Compile the contracts**:
    Compile the smart contracts before deployment:
    ```bash
    npx hardhat compile
    ```

4. **Deploy the contract**:
    Open the `scripts/deploy.js` file and edit the addresses for the PotCoin and NFT contracts. Then run the deployment script:
    ```bash
    npx hardhat run scripts/deploy.js --network <your-network>
    ```
    Replace `<your-network>` with the Ethereum network you are deploying to (e.g., `rinkeby`, `mainnet`, or others).

5. **Verify the deployment**:
    Once the contract is deployed, you can verify its address on Etherscan (or a similar block explorer for your network) to ensure it is live and operational.

6. **Interact with the contract**:
    Use your favorite Ethereum wallet (like MetaMask) or a custom frontend to interact with the contract for deposits, withdrawals, and participation in giveaways.

### Example of Contract Deployment Script (`scripts/deploy.js`)
```javascript
const hre = require("hardhat");

async function main() {
  const potCoinAddress = "0x...";  // PotCoin ERC-20 contract address
  const highRollerNFTAddress = "0x...";  // High Roller NFT contract address

  const PotCoinHighRollerVault = await hre.ethers.getContractFactory("PotCoinHighRollerVault");
  const vault = await PotCoinHighRollerVault.deploy(potCoinAddress, highRollerNFTAddress);

  await vault.deployed();
  console.log("PotCoin High Roller Vault deployed to:", vault.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
