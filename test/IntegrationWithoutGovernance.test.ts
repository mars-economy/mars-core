import { ethers } from "hardhat"
import { expect } from "chai"
import { Signer } from "ethers"
import { bytes32, timeout, wait, now, timeoutAppended } from "./utils/utils"
import {
  ERC20,
  ERC20__factory,
  MarsPredictionMarket,
  MarsPredictionMarket__factory,
  MarsPredictionMarketFactory,
  Settlement,
} from "../typechain"
import { setgroups } from "node:process"

describe("Prediction Market", async () => {
  let owner: Signer
  let oracle: Signer
  let users: Signer[]
  let predictionMarketTimeout: number
  let predictionMarket: MarsPredictionMarket
  let predictionMarketFactory: MarsPredictionMarketFactory
  let daiToken: ERC20
  let marsToken: ERC20
  let settlement: Settlement

  const initialBalance = 10_000
  const YES = ethers.utils.arrayify("0xc53ef995914f4b409b22e6128c2bcf17")
  const NO = ethers.utils.arrayify("0xc2c2c6cb226b42c4b36bf4b4dcb6ba17")
  const MILESTONE = ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814")

  const UNKNOWN = bytes32("Unknown")

  before(async () => {
    ;[owner, oracle, ...users] = await ethers.getSigners()
    predictionMarketTimeout = await timeoutAppended(ethers.provider, 5)
  })

  beforeEach(async () => {
    daiToken = (await (await ethers.getContractFactory("ERC20")).deploy(1_000_000, "Test daiToken", 18, "TTK")) as ERC20
    marsToken = (await (await ethers.getContractFactory("ERC20")).deploy(20_000_000, "Test marsToken", 18, "TTK")) as ERC20

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

    console.log("timeend", timeEnd)

    await settlement.connect(owner).addOracle(oracle1)
    await settlement.connect(owner).addOracle(oracle2)

    await marsToken.connect(owner).transfer(oracle1, 1_000_000)
    await marsToken.connect(owner).transfer(oracle2, 1_000_000)
    await marsToken.connect(oracle1_).approve(settlement.address, 1_000_000)
    await marsToken.connect(oracle2_).approve(settlement.address, 1_000_000)
    await settlement.connect(oracle1_).acceptAndStake()
    expect((await settlement.getOracles()).length).to.be.equal(1)
    await settlement.connect(oracle2_).acceptAndStake()
    expect((await settlement.getOracles()).length).to.be.equal(2)

    //first way to add outcomes
    let tx = await predictionMarketFactory.connect(owner).createMarket(
      MILESTONE, 1, "Example", "Example", daiToken.address, timeEnd, 
      [{uuid: YES, name: "YES", position: 1}]
    )

    // getting market address from event
    let rx = await tx.wait()
    let _newMarket = rx.events![2].args!.contractAddress

    //second way to add outcomes
    await predictionMarketFactory.connect(owner).addOutcome(_newMarket, NO, 2, "NO")

    await settlement.connect(owner).registerMarket(_newMarket, [YES, NO], timeEnd)

    predictionMarket = MarsPredictionMarket__factory.connect(_newMarket, owner)
    expect(await predictionMarket.getNumberOfOutcomes()).to.be.equal(2)

    let yesToken = ERC20__factory.connect((await predictionMarket.getTokens())[0], owner)
    let noToken = ERC20__factory.connect((await predictionMarket.getTokens())[1], owner)

    expect(await settlement.reachedConsensus(_newMarket)).to.be.equal(false)

    await daiToken.connect(users[0]).approve(predictionMarket.address, 1_000)
    await daiToken.connect(users[1]).approve(predictionMarket.address, 1_000)

    await checkBalances([users[0], users[1]], [10000, 10000])

    await predictionMarket.connect(users[0]).predict(YES, 1000)
    await predictionMarket.connect(users[1]).predict(NO, 1000)

    await expect(settlement.connect(oracle1_).voteWinningOutcome(_newMarket, YES)).to.be.revertedWith("VOTING PERIOD HASN'T ENDED")

    await wait(ethers, 60 * 60 * 24 * 2)

    await settlement.connect(oracle1_).voteWinningOutcome(_newMarket, YES)
    await settlement.connect(oracle2_).voteWinningOutcome(_newMarket, YES)

    await expect(predictionMarket.connect(users[0]).getReward()).to.be.revertedWith("PREDICTION IS NOT YET CONCLUDED")

    expect(await settlement.reachedConsensus(_newMarket)).to.be.equal(true)
    
    console.log("user0", await predictionMarket.connect(users[0]).getUserPredictionState())
    // console.log(await yesToken.balanceOf(await users[0].getAddress()))
    // console.log(await noToken.balanceOf(await users[0].getAddress()))
    console.log("user1", await predictionMarket.connect(users[1]).getUserPredictionState())
    // console.log(await yesToken.balanceOf(await users[1].getAddress()))
    // console.log(await noToken.balanceOf(await users[1].getAddress()))
    
    await wait(ethers, 60 * 60 * 24 * 8)

    await yesToken.connect(users[0]).approve(predictionMarket.address, 1000)
    await noToken.connect(users[1]).approve(predictionMarket.address, 1000)

    await checkBalances([users[0], users[1]], [9000, 9000])

    console.log("user0", await predictionMarket.getUserPredictionState())
    console.log("user1", await predictionMarket.getUserPredictionState())

    expect(await predictionMarket.connect(users[0]).getReward()).to.be.ok
    expect(await predictionMarket.connect(users[1]).getReward()).to.be.ok

    await checkBalances([users[0], users[1]], [10994, 9000])
  })

  //   it("Should get reward without governance voting if consensus reached and win correct number of tokens", async () => {
  //     let newMarket = "0x2ee51F0bCC1ece7B94091e5E250b08e8276256D9" //name
  //     let oracle1 = await oracle.getAddress()
  //     let oracle1_ = oracle
  //     let oracle2 = await users[4].getAddress()
  //     let oracle2_ = users[4]
  //     let disputeOpener = users[5]

  //     await marsToken.connect(owner).transfer(oracle1, 1_000_000)
  //     await marsToken.connect(owner).transfer(oracle2, 1_000_000)

  //     await settlement.connect(owner).addOracle(oracle1)
  //     await settlement.connect(owner).addOracle(oracle2)

  //     await marsToken.connect(oracle1_).approve(settlement.address, 1_000_000)
  //     await marsToken.connect(oracle2_).approve(settlement.address, 1_000_000)

  //     // await MarsPredictionMarketFactory.createMarket("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814", "1", "By 2022", "", daiToken.address, "1640995200")
  //     //   .createMarket(newMarket, [YES, NO], daiToken.address, await timeoutAppended(ethers.provider, 60 * 60 * 24 * 8))

  //     await settlement.connect(oracle1_).acceptAndStake()
  //     expect((await settlement.getOracles()).length).to.be.equal(1)
  //     await settlement.connect(oracle2_).acceptAndStake()
  //     expect((await settlement.getOracles()).length).to.be.equal(2)

  //     expect((await predictionMarketFactory.getMarkets()).length).to.be.equal(1)
  //     let _newMarket = (await predictionMarketFactory.connect(owner).getMarkets())[0]
  //     predictionMarket = MarsPredictionMarket__factory.connect(_newMarket, owner)
  //     expect(await predictionMarket.getNumberOfOutcomes()).to.be.equal(2)

  //     expect(await settlement.reachedConsensus(newMarket)).to.be.equal(false)

  //     await settlement.connect(oracle1_).voteWinningOutcome(newMarket, YES)
  //     await settlement.connect(oracle2_).voteWinningOutcome(newMarket, YES)

  //     expect(await settlement.reachedConsensus(newMarket)).to.be.equal(true)

  //     await expect(settlement.connect(users[5]).openDispute(newMarket)).to.be.revertedWith("VOTING PERIOD HASN'T ENDED")

  //     await approveAndPredict(users[0], YES, 1000)
  //     await approveAndPredict(users[1], YES, 3000)
  //     await approveAndPredict(users[2], NO, 1000)
  //     await approveAndPredict(users[3], NO, 1000)

  //     // //checking balances before getReward()
  //     await checkBalances(users, [9000, 7000, 9000, 9000])

  //     await wait(ethers, 60 * 60 * 24 * 6)

  //     await marsToken.connect(owner).transfer(await disputeOpener.getAddress(), 100_000)
  //     await marsToken.connect(disputeOpener).approve(settlement.address, 100_000)

  //     // await expect(settlement.connect(disputeOpener).startVoting(newMarket)).to.be.revertedWith("CONSENSUS HAS NOT BEEN REACHED")

  //     // // can uncomment if we want to test governance
  //     // // expect(await settlement.connect(disputeOpener).openDispute(newMarket)).to.be.ok

  //     // //governance voting for correct outcome
  //     // //what happens if oracles originally chose wrong outcome AND voters support wrong outcome?
  //     // // await governance.connect(users[0]).voteForOutcome(newMarket, 1);
  //     // // expect((await governance.getChangeOutcomeState(newMarket)).outcomeInfluence[0]).to.be.equal(0)
  //     // // expect((await governance.getChangeOutcomeState(newMarket)).outcomeInfluence[1]).to.be.equal(1000)
  //     // // expect((await governance.getProposalState(newMarket)).totalInfluence).to.be.equal(1_000) //rechecking because we reused old address

  //     await predictionMarket.connect(owner).setSettlement(settlement.address)
  //     await expect(predictionMarket.connect(users[0]).getReward()).to.be.revertedWith("PREDICTION IS NOT YET CONCLUDED")

  //     await wait(ethers, 60 * 60 * 24 * 10)

  //     // // await governance.connect(users[0]).finishVote(newMarket)

  //     let yesToken = ERC20__factory.connect((await predictionMarket.getTokens())[0], owner)
  //     let noToken = ERC20__factory.connect((await predictionMarket.getTokens())[1], owner)

  //     await yesToken.connect(users[0]).approve(predictionMarket.address, 1000)
  //     await yesToken.connect(users[1]).approve(predictionMarket.address, 3000)

  //     expect(await predictionMarket.connect(users[0]).getReward()).to.be.ok
  //     await expect(predictionMarket.connect(users[0]).getReward()).to.be.revertedWith("USER ALREADY CLAIMED")
  //     expect(await predictionMarket.connect(users[1]).getReward()).to.be.ok
  //     expect(await predictionMarket.connect(users[2]).getReward()).to.be.ok
  //     expect(await predictionMarket.connect(users[3]).getReward()).to.be.ok

  //     // checking reward after getReward()
  //     await checkBalances(users, [10500, 11500, 9000, 9000])
  //   })

  const approveAndPredict = async (user: Signer, outcome: string, amount: number) => {
    await daiToken.connect(user).approve(predictionMarket.address, amount)
    await predictionMarket.connect(user).predict(outcome, amount)
  }

  const checkBalances = async (users: Signer[], amounts: number[]) => {
    for (let i = 0; i < amounts.length; i++) {
      expect(await daiToken.balanceOf(await users[i].getAddress())).to.be.equal(amounts[i])
    }
  }
})
