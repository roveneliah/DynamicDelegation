
async function main() {
    // We get the contract to deploy
    const Krause = await ethers.getContractFactory("KRAUSE");
    const krause = await Krause.deploy()
    console.log("krause deployed to:", krause.address);
  
    const Delegation = await ethers.getContractFactory("Delegation");
    const $vote = await Delegation.deploy(krause.address)
  
    console.log("Votes deployed to:", $vote.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });