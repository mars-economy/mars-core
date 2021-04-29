import { ethers } from "hardhat"
import { expect } from "chai"
import { Signer, BigNumber } from "ethers"
import { LogDescription } from "ethers/lib/utils"
import { deployMars, Mars } from "./utils/mars"
import { bytes32, timeoutAppended } from "./utils/utils"
import { IPredictionMarketFactory } from "../typechain"

enum MilestoneStatus {
  Historical,
  Current,
  Future,
}

describe("Prediction Market Factory", async () => {
  let owner: Signer
  let user: Signer
  let mars: Mars

  before(async () => {
    ;[owner, user] = await ethers.getSigners()
  })

  beforeEach(async () => {
    mars = await deployMars(ethers, owner)
  })

  specify("Test environment", () => {
    expect(mars.predictionMarketFactory.address).to.be.properAddress
  })

  async function getCategoryUpdatedEvents(fromBlock: number | undefined): Promise<LogDescription[]> {
    const eventFragment = mars.predictionMarketFactory.interface.getEvent("CategoryUpdatedEvent")
    const topic = mars.predictionMarketFactory.interface.getEventTopic(eventFragment)
    const filter = { topics: [topic], address: mars.predictionMarketFactory.address, fromBlock }
    const swapLogs = await mars.predictionMarketFactory.provider.getLogs(filter)
    return swapLogs.map((log) => mars.predictionMarketFactory.interface.parseLog(log))
  }

  async function getMilestoneUpdatedEvents(fromBlock: number | undefined): Promise<LogDescription[]> {
    const eventFragment = mars.predictionMarketFactory.interface.getEvent("MilestoneUpdatedEvent")
    const topic = mars.predictionMarketFactory.interface.getEventTopic(eventFragment)
    const filter = { topics: [topic], address: mars.predictionMarketFactory.address, fromBlock }
    const swapLogs = await mars.predictionMarketFactory.provider.getLogs(filter)
    return swapLogs.map((log) => mars.predictionMarketFactory.interface.parseLog(log))
  }

  async function getPredictionMarketCreatedEvents(fromBlock: number | undefined): Promise<LogDescription[]> {
    const eventFragment = mars.predictionMarketFactory.interface.getEvent("PredictionMarketCreatedEvent")
    const topic = mars.predictionMarketFactory.interface.getEventTopic(eventFragment)
    const filter = { topics: [topic], address: mars.predictionMarketFactory.address, fromBlock }
    const swapLogs = await mars.predictionMarketFactory.provider.getLogs(filter)
    return swapLogs.map((log) => mars.predictionMarketFactory.interface.parseLog(log))
  }

  async function getOutcomeChangedEvents(fromBlock: number | undefined): Promise<LogDescription[]> {
    const eventFragment = mars.predictionMarketFactory.interface.getEvent("OutcomeChangedEvent")
    const topic = mars.predictionMarketFactory.interface.getEventTopic(eventFragment)
    const filter = { topics: [topic], address: mars.predictionMarketFactory.address, fromBlock }
    const swapLogs = await mars.predictionMarketFactory.provider.getLogs(filter)
    return swapLogs.map((log) => mars.predictionMarketFactory.interface.parseLog(log))
  }

  it("Should create a category", async () => {
    const tx = mars.predictionMarketFactory.updateCategory(
      ethers.utils.arrayify("0xb00b5428da0349e48763781ed54d7579"),
      1,
      "Crossing the frontier",
      "Lorem ipsum"
    )

    await expect(tx).not.to.be.reverted

    const events = await getCategoryUpdatedEvents((await tx).blockNumber)

    expect(events.length).to.be.eq(1)
    expect(events[0].args.uuid).to.be.eq("0xb00b5428da0349e48763781ed54d7579")
    expect(events[0].args.position).to.be.eq(1)
    expect(events[0].args.name).to.be.eq("Crossing the frontier")
    expect(events[0].args.description).to.be.eq("Lorem ipsum")
  })

  it("Should create a milestone", async () => {
    const tx1 = mars.predictionMarketFactory.updateCategory(
      ethers.utils.arrayify("0xb00b5428da0349e48763781ed54d7579"),
      1,
      "Crossing the frontier",
      "Lorem ipsum"
    )

    await expect(tx1).not.to.be.reverted

    const events1 = await getCategoryUpdatedEvents((await tx1).blockNumber)

    expect(events1.length).to.be.eq(1)
    expect(events1[0].args.uuid).to.be.eq("0xb00b5428da0349e48763781ed54d7579")
    expect(events1[0].args.position).to.be.eq(1)
    expect(events1[0].args.name).to.be.eq("Crossing the frontier")
    expect(events1[0].args.description).to.be.eq("Lorem ipsum")

    const tx2 = mars.predictionMarketFactory.updateMilestone(
      ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814"),
      ethers.utils.arrayify("0xb00b5428da0349e48763781ed54d7579"),
      1,
      "First success of Spaceship Orbital Flight",
      "Lorem ipsum",
      MilestoneStatus.Current
    )

    await expect(tx2).not.to.be.reverted

    const events2 = await getMilestoneUpdatedEvents((await tx2).blockNumber)

    expect(events2.length).to.be.eq(1)
    expect(events2[0].args.uuid).to.be.eq("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814")
    expect(events2[0].args.position).to.be.eq(1)
    expect(events2[0].args.name).to.be.eq("First success of Spaceship Orbital Flight")
    expect(events2[0].args.description).to.be.eq("Lorem ipsum")
    expect(events2[0].args.status).to.be.eq(MilestoneStatus.Current)
  })

  it("Should create prediction market", async () => {
    const tx1 = mars.predictionMarketFactory.updateCategory(
      ethers.utils.arrayify("0xb00b5428da0349e48763781ed54d7579"),
      1,
      "Crossing the frontier",
      "Lorem ipsum"
    )

    await expect(tx1).not.to.be.reverted

    const tx2 = mars.predictionMarketFactory.updateMilestone(
      ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814"),
      ethers.utils.arrayify("0xb00b5428da0349e48763781ed54d7579"),
      1,
      "First success of Spaceship Orbital Flight",
      "Lorem ipsum",
      MilestoneStatus.Current
    )

    await expect(tx2).not.to.be.reverted

    const tx3 = mars.predictionMarketFactory.createMarket(
      ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814"),
      1,
      "market 1",
      "desc",
      mars.marsToken.address,
      await timeoutAppended(ethers.provider, 5)
    )
    await expect(tx3).not.to.be.reverted

    const events = await getPredictionMarketCreatedEvents((await tx3).blockNumber)

    expect(events.length).to.be.eq(1)
    expect(events[0].args.milestoneUuid).to.be.eq("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814")
    expect(events[0].args.position).to.be.eq(1)
    expect(events[0].args.name).to.be.eq("market 1")
    expect(events[0].args.description).to.be.eq("desc")
    expect(events[0].args.token).to.be.eq(mars.marsToken.address)
    expect(events[0].args.contractAddress).to.be.properAddress
  })

  it("Should add an outcome", async () => {
    const tx1 = mars.predictionMarketFactory.updateCategory(
      ethers.utils.arrayify("0xb00b5428da0349e48763781ed54d7579"),
      1,
      "Crossing the frontier",
      "Lorem ipsum"
    )

    await expect(tx1).not.to.be.reverted

    const tx2 = mars.predictionMarketFactory.updateMilestone(
      ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814"),
      ethers.utils.arrayify("0xb00b5428da0349e48763781ed54d7579"),
      1,
      "First success of Spaceship Orbital Flight",
      "Lorem ipsum",
      MilestoneStatus.Current
    )

    await expect(tx2).not.to.be.reverted

    const tx3 = mars.predictionMarketFactory.createMarket(
      ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814"),
      1,
      "market 1",
      "desc",
      mars.marsToken.address,
      await timeoutAppended(ethers.provider, 5)
    )
    await expect(tx3).not.to.be.reverted

    const events1 = await getPredictionMarketCreatedEvents((await tx3).blockNumber)

    expect(events1.length).to.be.eq(1)
    const predictionMarket = events1[0].args.contractAddress

    const tx4 = mars.predictionMarketFactory.addOutcome(
      predictionMarket,
      ethers.utils.arrayify("0xc53ef995914f4b409b22e6128c2bcf17"),
      1,
      "outcome 1"
    )
    await expect(tx4).not.to.be.reverted

    const events2 = await getOutcomeChangedEvents((await tx4).blockNumber)

    expect(events2.length).to.be.eq(1)
    expect(events2[0].args.uuid).to.be.eq("0xc53ef995914f4b409b22e6128c2bcf17")
    expect(events2[0].args.position).to.be.eq(1)
    expect(events2[0].args.name).to.be.eq("outcome 1")
    expect(events2[0].args.predictionMarket).to.be.eq(predictionMarket)
  })
})
