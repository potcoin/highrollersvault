const hre = require("hardhat");

async function main() {
    const vaultContract = await hre.ethers.getContractAt("MATICHighRollerVault", "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512");

    // Fetch the participants
    const [addresses, participants] = await vaultContract.getParticipants();

    console.log("Participants in the Vault:");
    for (let i = 0; i < addresses.length; i++) {
        console.log(`Address: ${addresses[i]}`);
        console.log(`Amount: ${hre.ethers.utils.formatEther(participants[i].amount)} MATIC`);
        console.log(`Deposited At: ${new Date(participants[i].depositedAt * 1000).toLocaleString()}`);
        console.log("--------------------------------------------------");
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

