import { ethers, network } from "hardhat"
import { BigNumber, Contract } from "ethers"
import { tokens } from "../test/utils/utils"
import hre from "hardhat"

import fs from "fs"

import {populateMarkets, ADDR} from "./populate"

const myAddr = "0x2ee51F0bCC1ece7B94091e5E250b08e8276256D9";

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
  const parameters = await hre.upgrades.deployProxy(Parameters, [
    myAddr, 10, 20, 10000, 60*60*24, 60*60*24*7, 60*60*24*7, tokens(100000), tokens(20000), 0, 0
  ], {initializer: "initialize"})
  await parameters.deployed()

  ADDR["parameters"] = parameters.address
  console.log("parameters", parameters.address)
  return parameters.address
}

async function deploySettlement(wethAddress: string) {
  const Settlement = await ethers.getContractFactory("Settlement")
  const settlement = await hre.upgrades.deployProxy(Settlement, [ADDR["marsToken"], ADDR["parameters"]], {initializer: "initialize"})
  await settlement.deployed()

  ADDR["settlement"] = settlement.address
  console.log("settlement", settlement.address)
  return settlement.address
}

async function deployFactory(wethAddress: string) {
  const MarsPredictionMarketFactory = await ethers.getContractFactory("MarsPredictionMarketFactory")
  const factory = await hre.upgrades.deployProxy(MarsPredictionMarketFactory, [ADDR["settlement"]], {initializer: "initialize"})
  await factory.deployed()

  ADDR["predictionMarketFactory"] = factory.address
  console.log("predictionMarketFactory", factory.address)

  return factory.address
}

async function deployRegister(wethAddress: string) {
  const Register = await ethers.getContractFactory("Register")
  const register = await hre.upgrades.deployProxy(Register, [ADDR["settlement"], ADDR["parameters"]], {initializer: "initialize"})
  await register.deployed()

  ADDR["register"] = register.address
  console.log("register", register.address)
  return register.address
}



async function main() {
  await deployMarsToken("")
  await deployParameters("")
  await deploySettlement("") //address _marsToken, address _parameters
  await deployFactory("") //address _settlement
  await deployRegister("") //address _settlement, address _parameters

  await populateMarkets()

  fs.writeFileSync("new-contract-addresses.json", JSON.stringify(ADDR, null, "\t"))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })