import { ethers, network } from "hardhat"
import { wethAddress } from "./weth"
import { BigNumber, Contract } from "ethers"
import { LogDescription } from "ethers/lib/utils"
import fs from "fs"

import hre from "hardhat"
import { MarsERC20Token } from "../typechain"

async function deployMarsToken() {
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  
  const marsToken = await hre.upgrades.deployProxy(MarsToken, ["Decentralized Mars Token", "$DMT", 1684108800], {initializer: "initialize"})

  await marsToken.deployed()
  console.log("marsToken:", marsToken.address)
  return marsToken.address
}

async function upgradeMarsToken(addr: any) {
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  const mars = MarsToken.attach(addr) as MarsERC20Token

  const marsToken = await hre.upgrades.upgradeProxy(addr, MarsToken)

  await marsToken.deployed()
  console.log("marsToken:", marsToken.address)
}

async function testMars(addr: any) {
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  const mars = MarsToken.attach(addr) as MarsERC20Token
  console.log("Owner:", await mars.owner())
  console.log("Symbol:", await mars.symbol())
}

async function testMars2(addr: any) {
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  const mars = MarsToken.attach(addr) as MarsERC20Token
  console.log("Owner:", await mars.owner())
  console.log("value:", await mars.getValue())
}

async function main() {
  // let addr = await deployMarsToken()
  // await testMars(addr)
  // await upgradeMarsToken(addr)
  await testMars2("0x3Aa06C6507Df75459090ECE4CC53C7e531982dD0")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })