import hre from "hardhat"
import { ethers, network } from "hardhat"
import { BigNumber, Contract } from "ethers"
import { LogDescription } from "ethers/lib/utils"

import { categories, milestones, markets, outcomes } from "./data"

export var ADDR = {
  // governance: "", not needed for now
  marsToken: "0x77dA5632d829b457cd6d0dE37768eF9d5C879A6C",
  settlement: "0x79CE12Ed5e31770C095D9092D5dC52CA96B28960",
  predictionMarketFactory: "0xd01d78252Bf63d9b8AbF084d659b6857a37674C8",
  register: "0x3f0Ae69BC1622149aFbA380711F1F89eE5674033",
  parameters: "",
  governance: ""
}

export async function populateMarkets() {
  for (var i = 0; i < categories.length; i++) {
    console.log(i, categories.length - 1)
    await createCategory(categories[i][0], parseInt(categories[i][1]), categories[i][2], categories[i][3])
  }
  console.log("CATEGORIES DONE")

  for (var i = 0; i < milestones.length; i++) {
    console.log(i, milestones.length - 1)
    await createMilestone(milestones[i][0], milestones[i][1], parseInt(milestones[i][2]), milestones[i][3], milestones[i][4])
  }
  console.log("MILESTONES DONE")

  for (var i = 0; i < markets.length; i++) {
    console.log(i, markets.length - 1)
    await createMarket(
      markets[i][0],
      parseInt(markets[i][1]),
      markets[i][2],
      markets[i][3],
      "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56",
      parseInt(markets[i][4]),
      parseInt(markets[i][5]),
      outcomes[i],
      parseInt(markets[i][6]),
      parseInt(markets[i][7])
    )
  }
  console.log("MARKETS DONE")
}

async function createCategory(uuid: string, position: number, name: string, description: string) {
  const Register = await ethers.getContractFactory("Register")
  const register = await Register.attach(ADDR["register"])

  const [me] = await ethers.getSigners()
  await (await register.connect(me).updateCategory(ethers.utils.arrayify(uuid), position, name, description)).wait()
}

async function createMilestone(uuid: string, categoryUuid: string, position: number, name: string, description: string) {
  const Register = await ethers.getContractFactory("Register")
  const register = await Register.attach(ADDR["register"])

  const [me] = await ethers.getSigners()
  await (
    await register
      .connect(me)
      .updateMilestone(ethers.utils.arrayify(uuid), ethers.utils.arrayify(categoryUuid), position, name, description, 1)
  ).wait()
}

async function getPredictionMarketCreatedEvents(
  predictionMarketFactory: Contract,
  fromBlock: number | undefined
): Promise<LogDescription[]> {
  const eventFragment = predictionMarketFactory.interface.getEvent("PredictionMarketCreatedEvent")
  const topic = predictionMarketFactory.interface.getEventTopic(eventFragment)
  const filter = { topics: [topic], address: predictionMarketFactory.address, fromBlock }
  const swapLogs = await predictionMarketFactory.provider.getLogs(filter)
  return swapLogs.map((log) => predictionMarketFactory.interface.parseLog(log))
}

var options = { gasLimit: 7000000 }

async function createMarket(
  milestoneUuid: string,
  position: number,
  name: string,
  description: string,
  token: string,
  dueDate: number,
  predictionTimeEnd: number,
  outcomes: any,
  startSharePrice: number,
  endSharePrice: number
) {
  const factory = await ethers.getContractFactory("MarsPredictionMarketFactory")
  const predictionMarketFactory = await factory.attach(ADDR["predictionMarketFactory"])
  const Register = await ethers.getContractFactory("Register")
  const register = await Register.attach(ADDR["register"])
  const Settlement = await ethers.getContractFactory("Settlement")
  const settlement = await Settlement.attach(ADDR["settlement"])

  const [me] = await ethers.getSigners()
  let tx = await predictionMarketFactory.connect(me).createMarket(token, predictionTimeEnd, outcomes, startSharePrice, endSharePrice)

  tx = await tx.wait()

  const events = await getPredictionMarketCreatedEvents(predictionMarketFactory, tx.blockNumber)

  const marketAddress = events[0].args._market
  console.log("Created market " + marketAddress)

  await (
    await register
      .connect(me)
      .registerMarket(marketAddress, milestoneUuid, position, name, description, token, dueDate, predictionTimeEnd, outcomes)
  ).wait()

  await (await settlement.connect(me).registerMarket(marketAddress, dueDate)).wait()

  const MarsPredictionMarket = await ethers.getContractFactory("MarsPredictionMarket")
  const market = await MarsPredictionMarket.attach(marketAddress)

  await (await market.connect(me).setSettlement(ADDR["settlement"])).wait()

  await (await market.connect(me).setParameters(ADDR["parameters"])).wait()
}
