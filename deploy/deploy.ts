import { ethers, network } from "hardhat"
import { wethAddress } from "./weth"
import { BigNumber } from "ethers"
import fs from "fs"

var ADDR = {
  daiToken: "",
  marsToken: "",
  govToken: "",
  governance: "",
  settlement: "",
  predictionMarketFactory: "",
}

async function deployGovToken(wethAddress: string) {
  const GovToken = await ethers.getContractFactory("ERC20")
  const govToken = await GovToken.deploy(1_000_000, "Test govToken", 18, "GTK")
  await govToken.deployed()
  console.log("govToken:", govToken.address)
  ADDR["govToken"] = govToken.address
  return govToken.address
}

async function deployMarsToken(wethAddress: string) {
  const MarsToken = await ethers.getContractFactory("ERC20")
  const marsToken = await MarsToken.deploy(1_000_000, "Test marsToken", 18, "GTK")
  await marsToken.deployed()
  console.log("marsToken:", marsToken.address)
  ADDR["marsToken"] = marsToken.address
  return marsToken.address
}

async function deployDaiToken(wethAddress: string) {
  const DaiToken = await ethers.getContractFactory("ERC20")
  const daiToken = await DaiToken.deploy(1_000_000, "Test daiToken", 18, "GTK")
  await daiToken.deployed()
  console.log("daiToken:", daiToken.address)
  ADDR["daiToken"] = daiToken.address
  return daiToken.address
}

async function deployGovernance(wethAddress: string) {
  const Governance = await ethers.getContractFactory("MarsGovernance")
  const governance = await Governance.deploy(ADDR["govToken"])
  await governance.deployed()
  console.log("governance:", governance.address)
  ADDR["governance"] = governance.address
  return governance.address
}

async function deploySettlement(wethAddress: string) {
  const Settlement = await ethers.getContractFactory("Settlement")
  const settlement = await Settlement.deploy(ADDR["marsToken"], ADDR["governance"])
  await settlement.deployed()
  console.log("settlement:", settlement.address)
  ADDR["settlement"] = settlement.address
  return settlement.address
}

async function deployFactory(wethAddress: string) {
  const Factory = await ethers.getContractFactory("MarsPredictionMarketFactory")
  const predictionMarketFactory = await Factory.deploy(ADDR["govToken"])
  await predictionMarketFactory.deployed()
  console.log("predictionMarketFactory:", predictionMarketFactory.address)
  ADDR["predictionMarketFactory"] = predictionMarketFactory.address
  return predictionMarketFactory.address
}

async function main() {
  // const governanceRouter = await deployGovernanceRouter(wethAddress[network.name]);
  await deployDaiToken("")
  await deployMarsToken("")
  await deployGovToken("")
  await deployGovernance("")
  await deployFactory("")
  await deploySettlement("")

  //await governance.setSettlement(settlement.address)
  //await predictionMarket.connect(owner).setSettlement(settlement.address)
  //await governance.connect(owner).setFactory(predictionMarketFactory.address)

  try {
    fs.writeFileSync("contract-addresses.json", JSON.stringify(ADDR, null, "\t"))
  } catch {
    console.log("Failed to create addresses file")
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
