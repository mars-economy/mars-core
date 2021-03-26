import { ethers } from "hardhat"
import { expect } from "chai"
import { Signer } from "ethers"
import { deployMars, Mars } from "./utils/mars"
import { bytes32, timeout } from "./utils/utils"

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

  it("Should create prediction market", async () => {
    const tx = mars.predictionMarketFactory.createMarket(mars.marsToken.address, timeout(5))
    await expect(tx).not.to.be.reverted
  })
})
