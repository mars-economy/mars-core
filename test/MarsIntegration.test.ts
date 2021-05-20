import { ethers } from "hardhat"
import { expect } from "chai"
import { BigNumberish, Signer } from "ethers"
import { bytes32, wait, timeoutAppended, now, tokens } from "./utils/utils"
import {
  TestERC20,
  TestERC20__factory,
  MarsERC20OutcomeToken__factory,
  MarsPredictionMarket,
  MarsPredictionMarket__factory,
  MarsPredictionMarketFactory,
  Settlement,
} from "../typechain"
import { setgroups } from "node:process"


describe("Integration", async () => {
  let owner: Signer
  let oracle: Signer
  let users: Signer[]
  let predictionMarketTimeout: number
  let predictionMarket: MarsPredictionMarket
  let predictionMarketFactory: MarsPredictionMarketFactory
  let daiToken: TestERC20
  let marsToken: TestERC20
  let settlement: Settlement

  const initialBalance = tokens(10_000)
  const YES = ethers.utils.arrayify("0xc53ef995914f4b409b22e6128c2bcf17")
  const NO = ethers.utils.arrayify("0xc2c2c6cb226b42c4b36bf4b4dcb6ba17")
  const MILESTONE = ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814")

  const UNKNOWN = bytes32("Unknown")

  before(async () => {
    ;[owner, oracle, ...users] = await ethers.getSigners()
    predictionMarketTimeout = await timeoutAppended(ethers.provider, 5)
  })

  beforeEach(async () => {
    daiToken = (await (await ethers.getContractFactory("TestERC20")).deploy(tokens(1_000_000), "Test daiToken", 18, "TTK")) as TestERC20
    marsToken = (await (await ethers.getContractFactory("TestERC20")).deploy(tokens(20_000_000), "Test marsToken", 18, "TTK")) as TestERC20

    for (const user of users) {
      await daiToken.transfer(await user.getAddress(), initialBalance)
    }

    settlement = (await (await ethers.getContractFactory("Settlement"))
      .connect(owner)
      .deploy()) as Settlement

    settlement.connect(owner).initialize(marsToken.address)

    predictionMarketFactory = (await (await ethers.getContractFactory("MarsPredictionMarketFactory"))
      .connect(owner)
      .deploy()) as MarsPredictionMarketFactory
    
    predictionMarketFactory.connect(owner).initialize(await owner.getAddress(), settlement.address)
  })

  it("Can create market, oracle, and vote for new outcome, both vote yes", async () => {
    let oracle1 = await oracle.getAddress()
    let oracle1_ = oracle
    let oracle2 = await users[4].getAddress()
    let oracle2_ = users[4]
    let timeEnd = await timeoutAppended(ethers.provider, 60 * 60 * 24 * 2)

    await settlement.connect(owner).addOracle(oracle1)
    await settlement.connect(owner).addOracle(oracle2)

    await marsToken.connect(owner).transfer(oracle1, tokens(1_000_000))
    await marsToken.connect(owner).transfer(oracle2, tokens(1_000_000))
    await marsToken.connect(oracle1_).approve(settlement.address, tokens(1_000_000))
    await marsToken.connect(oracle2_).approve(settlement.address, tokens(1_000_000))
    await settlement.connect(oracle1_).acceptAndStake()
    expect((await settlement.getOracles()).length).to.be.equal(1)
    await settlement.connect(oracle2_).acceptAndStake()
    expect((await settlement.getOracles()).length).to.be.equal(2)

    //first way to add outcomes
    let tx = await predictionMarketFactory.connect(owner).createMarket(
      daiToken.address, timeEnd, 
      [{uuid: YES, name: "YES", position: 1}], tokens(1), tokens(10)
    )

  const MILESTONE2 = ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9815")
  let tx2 = await predictionMarketFactory.connect(owner).createMarket(
    daiToken.address, timeEnd, [{uuid: YES, name: "YES", position: 1}], tokens(1), tokens(10)
  ) //testing creation of second market. Used to be a bug

    // getting market address from event
    let rx = await tx.wait()
    let _newMarket = rx.events![3].args!._market

    await settlement.connect(owner).registerMarket(_newMarket, [YES, NO], timeEnd)

    predictionMarket = MarsPredictionMarket__factory.connect(_newMarket, owner)
    //second way to add outcomes
    await predictionMarket.connect(owner).addOutcome(NO, 2, "NO")
    await predictionMarket.connect(owner).setSettlement(settlement.address)

    expect(await predictionMarket.getNumberOfOutcomes()).to.be.equal(2)

    let yesToken = MarsERC20OutcomeToken__factory.connect((await predictionMarket.getTokens())[0], owner)
    let noToken = MarsERC20OutcomeToken__factory.connect((await predictionMarket.getTokens())[1], owner)

    expect(await settlement.reachedConsensus(_newMarket)).to.be.equal(false)

    await daiToken.connect(users[0]).approve(predictionMarket.address, tokens(1_000))
    await daiToken.connect(users[1]).approve(predictionMarket.address, tokens(1_000))

    await checkBalances([users[0], users[1]], [tokens(10000), tokens(10000)])

    console.log("user0", await predictionMarket.getUserPredictionState(await users[0].getAddress(), await now(ethers.provider)))
    console.log("user1", await predictionMarket.getUserPredictionState(await users[1].getAddress(), await now(ethers.provider)))  
    
    await predictionMarket.connect(users[0]).predict(YES, tokens(1000))
    await predictionMarket.connect(users[1]).predict(NO, tokens(1000))

    await expect(settlement.connect(oracle1_).voteWinningOutcome(_newMarket, YES)).to.be.revertedWith("VOTING PERIOD HASN'T ENDED")

    await wait(ethers, 60 * 60 * 24 * 2)

    await settlement.connect(oracle1_).voteWinningOutcome(_newMarket, YES)
    await settlement.connect(oracle2_).voteWinningOutcome(_newMarket, YES)

    expect(await settlement.reachedConsensus(_newMarket)).to.be.equal(true)
    
    console.log(111)    
    console.log("user0", await predictionMarket.getUserPredictionState(await users[0].getAddress(), await now(ethers.provider)))
    console.log("user1", await predictionMarket.getUserPredictionState(await users[1].getAddress(), await now(ethers.provider)))
    
    await wait(ethers, 60 * 60 * 24 * 8)

    await yesToken.connect(users[0]).approve(predictionMarket.address, tokens(1000))
    await noToken.connect(users[1]).approve(predictionMarket.address, tokens(1000))

    await checkBalances([users[0], users[1]], [tokens(9000), tokens(9000)])

    console.log(111)
    console.log("user0", await predictionMarket.getUserPredictionState(await users[0].getAddress(), await now(ethers.provider)))
    console.log("user1", await predictionMarket.getUserPredictionState(await users[1].getAddress(), await now(ethers.provider)))  
    
    // console.log(await yesToken.connect(users[0]).stakedAmount())
    expect(await predictionMarket.connect(users[0]).getReward()).to.be.ok
    expect(await predictionMarket.connect(users[1]).getReward()).to.be.ok

    await checkBalances([users[0], users[1]], [tokens(10994), tokens(9000)])
  })


  const checkBalances = async (users: Signer[], amounts: BigNumberish[]) => {
    for (let i = 0; i < amounts.length; i++) {
      expect(await daiToken.balanceOf(await users[i].getAddress())).to.be.equal(amounts[i])
    }
  }
})
