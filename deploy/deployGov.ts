import { ethers, network } from "hardhat"
import { BigNumber, Contract } from "ethers"
import { tokens } from "../test/utils/utils"
import hre from "hardhat"

import fs from "fs"

import { populateMarkets, ADDR } from "./populate"

let myAddr: any

async function deployMarsToken(wethAddress: string) {
  const MarsERC20Token = await ethers.getContractFactory("MarsERC20Token")
  const marsToken = await MarsERC20Token.deploy("Decentralized Mars Token", "$DMT", 1684108800)
  await marsToken.deployed()

  ADDR["marsToken"] = marsToken.address
  console.log("marsToken", marsToken.address)
  return marsToken
}

async function deployParameters(wethAddress: string) {
  const Parameters = await ethers.getContractFactory("Parameters")
  const parameters = await hre.upgrades.deployProxy(
    Parameters,
    [myAddr, 10, 20, 10000, 60 * 60 * 24, 60 * 60 * 24 * 7, 60 * 60 * 24 * 7, tokens(100000), tokens(20000), 0, 0],
    { initializer: "initialize" }
  )
  await parameters.deployed()

  ADDR["parameters"] = parameters.address
  console.log("parameters", parameters.address)
  return parameters.address
}

async function deployGovernance(wethAddress: string) {
  const MarsGovernance = await ethers.getContractFactory("MarsGovernance")
  const governance = await hre.upgrades.deployProxy(
    MarsGovernance,
    [ADDR["marsToken"], ADDR["parameters"]],
    { initializer: "initialize" }
  )
  await governance.deployed()

  ADDR["governance"] = governance.address
  console.log("governance", governance.address)
  return governance.address
}

async function main() {
  myAddr = (await hre.ethers.getSigners())[0].address

  await deployMarsToken("")
  await deployParameters("")
  await deployGovernance("") 

  fs.writeFileSync("gov-addresses.json", JSON.stringify(ADDR, null, "\t"))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
