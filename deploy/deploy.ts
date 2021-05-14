import { ethers, network } from "hardhat"
import fs from "fs"

import { MarsERC20Token } from "../typechain"



async function deployMarsToken() {
  
  const MarsERC20Token = await ethers.getContractFactory("MarsERC20Token")
  const marsToken = await MarsERC20Token.deploy("Decentralized Mars Token", "$DMT", 1684108800)
  await marsToken.deployed()
  console.log("marsToken:", marsToken.address)

  fs.writeFileSync("marsToken.json", JSON.stringify({"marsToken": marsToken.address}, null, "\t"))
  return marsToken.address
}

async function main() {
  await deployMarsToken();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })