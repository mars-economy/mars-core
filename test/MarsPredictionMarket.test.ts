import { ethers } from "hardhat"
import { expect } from "chai"
import { Signer } from "ethers"
import { bytes32, timeoutAppended, wait } from "./utils/utils"
import {
  ERC20,
  ERC20__factory,
  MarsPredictionMarket,
  MarsPredictionMarket__factory,
  MarsPredictionMarketFactory,
  Settlement,
} from "../typechain"

describe("Prediction Market", async () => {
  let owner: Signer
  let oracle: Signer
  let users: Signer[]
  let predictionMarketTimeout: number
  let predictionMarket: MarsPredictionMarket
  let predictionMarketFactory: MarsPredictionMarketFactory
  let token: ERC20
  const initialBalance = 10_000
  const YES = bytes32("Yes")
  const NO = bytes32("No")
  const UNKNOWN = bytes32("Unknown")

  before(async () => {
    ;[owner, oracle, ...users] = await ethers.getSigners()
  })

  beforeEach(async () => {
    token = (await (await ethers.getContractFactory("ERC20")).deploy(1_000_000, "Test Token", 18, "TTK")) as ERC20
    for (const user of users) {
      await token.transfer(await user.getAddress(), initialBalance)
    }

    predictionMarketFactory = (await (await ethers.getContractFactory("MarsPredictionMarketFactory"))
      .connect(owner)
      .deploy(await owner.getAddress())) as MarsPredictionMarketFactory

    predictionMarketTimeout = await timeoutAppended(ethers.provider, 15)
    await predictionMarketFactory
      .connect(owner)
      .createMarket(token.address, predictionMarketTimeout, "0x2ee51F0bCC1ece7B94091e5E250b08e8276256D9")

    let newMarket = (await predictionMarketFactory.connect(owner).getMarkets())[0]
    predictionMarket = MarsPredictionMarket__factory.connect(newMarket, owner)

    await predictionMarketFactory.connect(owner).addOutcome(predictionMarket.address, YES)
    await predictionMarketFactory.connect(owner).addOutcome(predictionMarket.address, NO)
  })

  specify("Test environment", () => {
    expect(predictionMarket.address).to.be.properAddress
  })

  it("Should return specified timeout", async () => {
    expect(await predictionMarket.getPredictionTimeEnd()).to.equal(predictionMarketTimeout)
  })

  it("Should return correct number of outcomes", async () => {
    expect(await predictionMarket.getNumberOfOutcomes()).to.equal(2)
  })

  describe("Predict", async () => {
    it("Should create correct tokens", async () => {
      expect((await predictionMarket.getTokens()).length).to.be.equal(2)
      expect((await predictionMarket.getTokens())[0]).to.be.properAddress
      expect((await predictionMarket.getTokens())[1]).to.be.properAddress

      let out1 = (await predictionMarket.getTokens())[0]
      let outcome1 = ERC20__factory.connect(out1, owner)
      let out2 = (await predictionMarket.getTokens())[1]
      let outcome2 = ERC20__factory.connect(out2, owner)

      expect(await outcome1.name()).to.contain("Yes")
      expect(await outcome2.name()).to.contain("No")
      expect((await predictionMarket.getTokens())[2]).to.be.not.ok
      //yes, it makes the test fail "AssertionError: expected undefined to be truthy"
    })

    it("Should emit prediction event", async () => {
      const user = users[0]

      await token.connect(user).approve(predictionMarket.address, 1000)
      const predictTx = predictionMarket.connect(user).predict(YES, 1000)
      await expect(predictTx)
        .to.emit(predictionMarket, "Prediction")
        .withArgs(await user.getAddress(), YES)
    })

    it("Should update user balance", async () => {
      const user = users[0]
      await token.connect(user).approve(predictionMarket.address, 1000)

      await predictionMarket.connect(user).predict(YES, 1000)

      expect(await predictionMarket.connect(user).userOutcomeBalance(YES)).to.be.equal(1000)

      expect(await token.balanceOf(await user.getAddress())).to.equal(initialBalance - 1000)
      expect(await token.balanceOf(predictionMarket.address)).to.equal(1000)

      let yesToken = ERC20__factory.connect((await predictionMarket.getTokens())[0], owner)
      let noToken = ERC20__factory.connect((await predictionMarket.getTokens())[1], owner)

      expect(await yesToken.balanceOf(await user.getAddress())).to.be.equal(1000)
      expect(await noToken.balanceOf(await user.getAddress())).to.be.equal(0)
    })

    it("Should update outcome balance", async () => {
      const user = users[0]
      await token.connect(user).approve(predictionMarket.address, 1000)

      await predictionMarket.connect(user).predict(YES, 1000)

      expect(await predictionMarket.connect(user).userOutcomeBalance(YES)).to.be.equal(1000)
      expect(await predictionMarket.connect(user).outcomeBalance(YES)).to.be.equal(1000)
      expect(await predictionMarket.connect(user).outcomeBalance(NO)).to.be.equal(0)

      let yesToken = ERC20__factory.connect((await predictionMarket.getTokens())[0], owner)
      expect(await yesToken.balanceOf(predictionMarket.address)).to.be.equal((await yesToken.totalSupply()).sub(1000))
    })

    it("Should revert if unknown outcome", async () => {
      const user = users[0]
      await token.connect(user).approve(predictionMarket.address, 1000)
      await expect(predictionMarket.connect(user).predict(UNKNOWN, 1000)).to.be.reverted
    })
  })
})
