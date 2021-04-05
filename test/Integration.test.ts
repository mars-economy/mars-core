import { ethers } from "hardhat"
import { expect } from "chai"
import { Signer } from "ethers"
import { bytes32, timeout, wait } from "./utils/utils"
import {
  ERC20,
  ERC20__factory,
  MarsPredictionMarket,
  MarsPredictionMarket__factory,
  MarsPredictionMarketFactory,
  Settlement,
  MarsGovernance,
} from "../typechain"

describe("Prediction Market", async () => {
  let owner: Signer
  let oracle: Signer
  let users: Signer[]
  let predictionMarketTimeout: number
  let predictionMarket: MarsPredictionMarket
  let predictionMarketFactory: MarsPredictionMarketFactory
  let daiToken: ERC20
  let marsToken: ERC20
  let govToken: ERC20
  let governance: MarsGovernance
  let settlement: Settlement

  const initialBalance = 10_000
  const YES = bytes32("Yes")
  const NO = bytes32("No")
  const UNKNOWN = bytes32("Unknown")

  before(async () => {
    ;[owner, oracle, ...users] = await ethers.getSigners()
    predictionMarketTimeout = timeout(5)
  })

  beforeEach(async () => {
    daiToken = (await (await ethers.getContractFactory("ERC20")).deploy(1_000_000, "Test daiToken", 18, "TTK")) as ERC20
    govToken = (await (await ethers.getContractFactory("ERC20")).deploy(1_000_000, "Test govToken", 18, "TTK")) as ERC20
    marsToken = (await (await ethers.getContractFactory("ERC20")).deploy(1_000_000, "Test marsToken", 18, "TTK")) as ERC20

    for (const user of users) {
      await daiToken.transfer(await user.getAddress(), initialBalance)
    }

    predictionMarketFactory = (await (await ethers.getContractFactory("MarsPredictionMarketFactory"))
      .connect(owner)
      .deploy(await owner.getAddress())) as MarsPredictionMarketFactory
    governance = (await (await ethers.getContractFactory("MarsGovernance")).connect(owner).deploy(govToken.address)) as MarsGovernance
    settlement = (await (await ethers.getContractFactory("Settlement"))
      .connect(owner)
      .deploy(marsToken.address, governance.address)) as Settlement

    await governance.connect(owner).setFactory(predictionMarketFactory.address)
    await governance.setSettlement(settlement.address)
  })

  it("Governance adds oracles and oracle can stake MARS tokens", async () => {
    let testaddr = await oracle.getAddress()

    await governance.connect(owner).addOracle(testaddr)

    await govToken.connect(owner).transfer(await users[0].getAddress(), 1_000)
    await governance.connect(users[0]).vote(testaddr, 1)

    expect((await governance.getProposalState(testaddr)).approvalsInfluence).to.be.equal(1_000)
    expect((await governance.getProposalState(testaddr)).totalInfluence).to.be.equal(1_000)

    await wait(ethers, 60 * 60 * 24 * 1)
    await expect(governance.connect(users[1]).finishVote(testaddr)).to.be.revertedWith("VOTING PERIOD HASN'T ENDED")

    await wait(ethers, 60 * 60 * 24 * 1)
    expect(await governance.connect(users[1]).finishVote(testaddr)).to.be.ok
    expect(await governance.getProposalResult(testaddr)).to.be.equal(1)

    await marsToken.connect(owner).transfer(testaddr, 1_000_000)

    await marsToken.connect(oracle).approve(settlement.address, 1_000_000)
    await settlement.connect(oracle).acceptAndStake()

    expect((await settlement.getOracles())[0]).to.be.equal(testaddr)
  })

  it("Governance creates Market", async () => {
    let testaddr = "0x2ee51F0bCC1ece7B94091e5E250b08e8276256D9"

    await governance.connect(owner).createMarket(testaddr, [YES, NO], daiToken.address)

    await govToken.connect(owner).transfer(await users[0].getAddress(), 1_000)

    await governance.connect(users[0]).vote(testaddr, 1)

    await expect(governance.connect(users[1]).vote(testaddr, 1)).to.be.revertedWith("NO GOV TOKENS IN ACCOUNT")
    expect((await governance.getProposalState(testaddr)).approvalsInfluence).to.be.equal(1_000)
    expect((await governance.getProposalState(testaddr)).totalInfluence).to.be.equal(1_000)

    await expect(governance.connect(users[1]).finishVote(testaddr)).to.be.revertedWith("VOTING PERIOD HASN'T ENDED")

    await wait(ethers, 60 * 60 * 24 * 2)

    expect(await governance.connect(users[1]).finishVote(testaddr)).to.be.ok
    expect(await governance.getProposalResult(testaddr)).to.be.equal(1)

    expect((await predictionMarketFactory.getMarkets()).length).to.be.equal(1)
    let newMarket = (await predictionMarketFactory.connect(owner).getMarkets())[0]
    predictionMarket = MarsPredictionMarket__factory.connect(newMarket, owner)
  })
})
