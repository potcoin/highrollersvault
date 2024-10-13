import hardhat from "hardhat";

const {waffle} = hardhat;
import {expect} from "chai";
import hre from "hardhat";
import chaiAsPromised from "chai-as-promised";
import * as chai from "chai";

chai.use(waffle.solidity);
chai.use(chaiAsPromised);


describe("PotCoinHighRollerVault", function () {
    let owner, addr1, addr2, potCoin, vault, nftContract;

    beforeEach(async function () {
        [owner, addr1, addr2] = await hre.ethers.getSigners();

        // Deploy Mock PotCoin ERC20 token
        const PotCoin = await hre.ethers.getContractFactory("MockERC20");
        potCoin = await PotCoin.deploy("PotCoin", "POT", hre.ethers.utils.parseEther("1000000")); // 1 million POT for testing
        await potCoin.deployed();

        // Deploy HighRollerNFT contract
        const HighRollerNFT = await hre.ethers.getContractFactory("HighRollerNFT");
        nftContract = await HighRollerNFT.deploy(owner.address, "https://example.com/metadata/");
        await nftContract.deployed();

        // Deploy PotCoinHighRollerVault contract
        const Vault = await hre.ethers.getContractFactory("PotCoinHighRollerVault");
        vault = await Vault.deploy(
            nftContract.address, // HighRollerNFT contract address
            potCoin.address, // PotCoin contract address
            1, // Chainlink subscriptionId (mocked)
            owner.address, // VRF Coordinator address (mocked)
            hre.ethers.constants.HashZero // keyHash (mocked)
        );
        await vault.deployed();

        // Transfer some PotCoin to addr1 and addr2
        await potCoin.transfer(addr1.address, hre.ethers.utils.parseEther("100000"));
        await potCoin.transfer(addr2.address, hre.ethers.utils.parseEther("100000"));
    });

    it("Should allow participants to deposit PotCoin", async function () {
        // Approve the vault to spend PotCoin on behalf of addr1
        await potCoin.connect(addr1).approve(vault.address, hre.ethers.utils.parseEther("1"));

        // Participant deposits PotCoin
        await vault.connect(addr1).deposit(hre.ethers.utils.parseEther("1")); // 100,000 POT

        // Verify the deposit
        const participant = await vault.participants(addr1.address);
        expect(participant.amount).to.equal(hre.ethers.utils.parseEther("1"));
    });

    it("Should enforce the minimum holding requirement", async function () {
        // Approve a smaller amount of PotCoin for the vault (below 1 POT)
        await potCoin.connect(addr1).approve(vault.address, hre.ethers.utils.parseEther("0.5")); // 0.5 POT

        // Attempt to deposit below the minimum holding threshold (should revert)
        await expect(vault.connect(addr1).deposit(hre.ethers.utils.parseEther("0.5"))).to.be.revertedWith(
            "Must deposit at least 1 POT"
        );
    });

    it("Should allow withdrawals after the holding period and update user balance", async function () {
        // Approve the vault to spend PotCoin on behalf of addr1
        await potCoin.connect(addr1).approve(vault.address, hre.ethers.utils.parseEther("100000"));

        // Check addr1's PotCoin balance before the deposit
        const initialBalance = await potCoin.balanceOf(addr1.address);

        // Participant deposits PotCoin
        await vault.connect(addr1).deposit(hre.ethers.utils.parseEther("100000"));

        // Check addr1's PotCoin balance after the deposit
        const balanceAfterDeposit = await potCoin.balanceOf(addr1.address);
        expect(balanceAfterDeposit).to.equal(initialBalance.sub(hre.ethers.utils.parseEther("100000")));

        // Fast forward time to simulate passing of the holding period
        await hre.ethers.provider.send("evm_increaseTime", [5 * 60]); // Increase time by 5 minutes
        await hre.ethers.provider.send("evm_mine"); // Mine the next block

        // Withdraw the deposit
        await vault.connect(addr1).withdraw(hre.ethers.utils.parseEther("100000"));

        // Check participant balance is now 0 in the vault
        const participant = await vault.participants(addr1.address);
        expect(participant.amount).to.equal(0);

        // Check addr1's PotCoin balance after the withdrawal
        const finalBalance = await potCoin.balanceOf(addr1.address);
        expect(finalBalance).to.equal(initialBalance);
    });


    it("Should prevent withdrawals before the holding period", async function () {
        // Approve the vault to spend PotCoin on behalf of addr1
        await potCoin.connect(addr1).approve(vault.address, hre.ethers.utils.parseEther("100000"));

        // Participant deposits PotCoin
        await vault.connect(addr1).deposit(hre.ethers.utils.parseEther("100000"));

        // Attempt to withdraw before the holding period (should revert)
        await expect(vault.connect(addr1).withdraw(hre.ethers.utils.parseEther("100000"))).to.be.revertedWith(
            "Cannot withdraw before 5 minutes"
        );
    });

});
