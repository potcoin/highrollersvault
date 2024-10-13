const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Mock VRF Coordinator
  const MockVRFCoordinator = await hre.ethers.getContractFactory("MockVRFCoordinatorV2");
  const mockVRFCoordinator = await MockVRFCoordinator.deploy();
  await mockVRFCoordinator.deployed();
  console.log("Mock VRF Coordinator deployed to:", mockVRFCoordinator.address);

  // Deploy NFT Contract
  const HighRollerNFT = await hre.ethers.getContractFactory("HighRollerNFT");
  const nftContract = await HighRollerNFT.deploy(deployer.address);
  await nftContract.deployed();
  console.log("HighRollerNFT deployed to:", nftContract.address);

  // Deploy Vault Contract
  const MATICHighRollerVault = await hre.ethers.getContractFactory("MATICHighRollerVault");
  const vaultContract = await MATICHighRollerVault.deploy(
    nftContract.address,
    1, // subscriptionId (mocked)
    mockVRFCoordinator.address,
    hre.ethers.constants.HashZero // keyHash (mocked)
  );
  await vaultContract.deployed();
  console.log("MATICHighRollerVault deployed to:", vaultContract.address);

  // Transfer ownership of NFT contract to vault
  await nftContract.transferOwnership(vaultContract.address);
  console.log("Ownership of NFT contract transferred to Vault.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
