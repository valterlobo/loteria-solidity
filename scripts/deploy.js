// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Loteria = await hre.ethers.getContractFactory("Loteria");
  const loteria = await Loteria.deploy({
    value: hre.ethers.utils.parseEther("0.01"),
  });

  await loteria.deployed();
  console.log("Loteria deployed to:", loteria.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
