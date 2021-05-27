import { ethers, upgrades } from "hardhat"
import { expect } from "chai"
import { Contract, Signer } from "ethers"
import { bytes32, timeout, wait, now, timeoutAppended } from "./utils/utils"
import {
  TestERC20,
  MarsPredictionMarket,
  MarsPredictionMarket__factory,
  MarsPredictionMarketFactory,
} from "../typechain"
import { setgroups } from "node:process"

import {tokens} from "./utils/utils"

describe("Prediction Market", async () => {
  let owner: Signer
  let users: Signer[]
  let predictionMarket: MarsPredictionMarket
  let predictionMarketFactory: MarsPredictionMarketFactory
  let token: TestERC20

  let timeEnd: number
  const YES = ethers.utils.arrayify("0xc53ef995914f4b409b22e6128c2bcf17")
  const NO = ethers.utils.arrayify("0xc2c2c6cb226b42c4b36bf4b4dcb6ba17")
  const MILESTONE = ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814")

  beforeEach(async () => {
    [owner, ...users] = await ethers.getSigners()
    timeEnd = await timeoutAppended(ethers.provider, 60 * 60 * 24 * 2)

    token = (await (await ethers.getContractFactory("TestERC20")).deploy(tokens(1_000_000), "Test Token", 18, "TTK")) as TestERC20
    for (const user of users) {
      await token.transfer(await user.getAddress(), tokens(10_000))
    }

    predictionMarketFactory = (await (await ethers.getContractFactory("MarsPredictionMarketFactory"))
    .connect(owner)
    .deploy()) as MarsPredictionMarketFactory
  
    predictionMarketFactory.connect(owner).initialize(await owner.getAddress())

    let tx = await predictionMarketFactory.connect(owner).createMarket(
      token.address, timeEnd, 
      [{uuid: YES, name: "YES", position: 1}], tokens(1), tokens(10)
    )

    let rx = await tx.wait()
    let _newMarket = rx.events![3].args!.contractAddress
    
    predictionMarket = MarsPredictionMarket__factory.connect(_newMarket, owner)
  })

  specify("Test environment", () => {
    expect(predictionMarket.address).to.be.properAddress
  })

  it.only("Debugging", async () => {
    console.log(await (await predictionMarket.getSharePrice(await now(ethers.provider))).toString())
  })

  it("Should return specified timeout", async () => {
    expect(await predictionMarket.getPredictionTimeEnd()).to.equal(timeEnd)
  })

  it("Should return correct number of outcomes", async () => {
    expect(await predictionMarket.getNumberOfOutcomes()).to.equal(1)
  })

  it("Should add outcome and return correct number of outcomes", async () => {
    expect(await predictionMarket.getNumberOfOutcomes()).to.equal(1)
    await predictionMarket.connect(owner).addOutcome(NO, 2, "NO")
    expect(await predictionMarket.getNumberOfOutcomes()).to.equal(2)
  })

})
