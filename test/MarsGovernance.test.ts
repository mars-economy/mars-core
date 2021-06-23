import { ethers } from "hardhat"
import { expect } from "chai"
import { BigNumberish, Signer } from "ethers"
import { AddressZero } from "@ethersproject/constants"
import { bytes32, wait, timeoutAppended, now, tokens } from "./utils/utils"
import { TestERC20, MarsGovernance, Parameters } from "../typechain"
import { getOpcodeLength } from "hardhat/internal/hardhat-network/stack-traces/opcodes"
// import { exit, setgroups } from "node:process"

describe("Governance", async () => {
  let owner: Signer
  let oracle: Signer
  let users: Signer[]
  let marsToken: TestERC20
  let gov: MarsGovernance
  let parameters: Parameters

  const initialBalance = tokens(10_000)
  // const YES = ethers.utils.arrayify("0xc53ef995914f4b409b22e6128c2bcf17")
  // const NO = ethers.utils.arrayify("0xc2c2c6cb226b42c4b36bf4b4dcb6ba17")
  // const MILESTONE = ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814")

  const UNKNOWN = bytes32("Unknown")

  beforeEach(async () => {
    ;[owner, oracle, ...users] = await ethers.getSigners()

    marsToken = (await (await ethers.getContractFactory("TestERC20")).deploy(tokens(20_000), "Test marsToken", 18, "TTK")) as TestERC20

    parameters = (await (await ethers.getContractFactory("Parameters")).connect(owner).deploy()) as Parameters
    parameters.initialize(
      await users[8].getAddress(),
      10,
      20,
      10000,
      60 * 60 * 24,
      60 * 60 * 24 * 7,
      60 * 60 * 24 * 7,
      tokens(100000),
      tokens(20000),
      0,
      0
    )

    for (let i = 0; i < 2; i++) {
      await marsToken.transfer(await users[i].getAddress(), initialBalance)
    }

    gov = (await (await ethers.getContractFactory("MarsGovernance")).deploy(marsToken.address, parameters.address)) as MarsGovernance
  })

  // it("Add oracle", async () => {
  //     let newOracle = await users[1].getAddress()

  //     await expect(gov.addOracle(newOracle)).to.be.ok;

  //     // console.log(await gov.getOracle(newOracle))
  // })

  // it.only("Create Market", async () => {
  //   await expect(gov.createMarket(AddressZero, "0x521a30e96c1b40b08b3e98294e70a2f3", 1, "The first human will set foot on Mars by the year of 2035", "", [{uuid: ethers.utils.arrayify("0xc53ef995914f4b409b22e6128c2bcf17"), position: 1, name: "Yes"}], "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56" ,"2082758399")).to.be.ok

  //   console.log(await gov.getMarket(AddressZero))
  // })

  it("Change outcome", async () => {
    // console.log(await gov.connect(users[1]).iHaveVoted())
    // console.log(await gov.connect(users[1]).haveIVoted(0))

    console.log("false", await gov.getOutcomeStatus(false, await users[1].getAddress()))
    console.log("true", await gov.getOutcomeStatus(true, await users[1].getAddress()))

    await gov.changeOutcome(AddressZero, ["0x521a30e96c1b40b08b3e98294e70a2f3", "0x521a30e96c1b40b08b3e98294e70a2f1"], true)

    // console.log(await gov.getOutcomes(AddressZero))

    await gov.connect(users[1]).voteForOutcome(0, 1)
    
    console.log("false", await gov.getOutcomeStatus(false, await users[1].getAddress()))
    console.log("true", await gov.getOutcomeStatus(true, await users[1].getAddress()))

    expect((await gov.getOutcomes(AddressZero))[1].outcomeInfluence[1]).to.be.equal(initialBalance)
    expect((await gov.getOutcomes(AddressZero))[1].outcomeInfluence[0]).to.be.equal(0)

    await wait(ethers, 60 * 60 * 24 * 7)

    let tx = gov.finishVote(AddressZero)
    expect((await (await tx).wait()).events![0].args!.result).to.be.equal(1)

    console.log("false", await gov.getOutcomeStatus(false, await users[1].getAddress()))
    console.log("true", await gov.getOutcomeStatus(true, await users[1].getAddress()))

    console.log(await gov.connect(users[1]).iHaveVoted())
    console.log(await gov.connect(users[1]).haveIVoted(0))
  })

  //   it("Remove oracle", async () => {
  //     let newOracle = await users[1].getAddress()
  //     await expect(gov.removeOracle(newOracle)).to.be.revertedWith("Oracle not yet added")

  //     await gov.addOracle(newOracle)
  //     await expect(gov.removeOracle(newOracle)).to.be.ok
  // })

  // it("Voting works and can't vote twice", async () => {
  //   let newOracle = await users[1].getAddress()
  //   await gov.addOracle(newOracle)

  //   await gov.connect(users[1]).vote(newOracle, 0, initialBalance)
  //   expect((await gov.getOracle(newOracle))[0]['totalInfluence']).to.be.equal(initialBalance)
  //   expect((await gov.getOracle(newOracle))[1]['voting']['approvalsInfluence']).to.be.equal(initialBalance)
  //   await expect(gov.connect(users[1]).vote(newOracle, 0, initialBalance)).to.be.revertedWith("Already voted")

  //   await gov.connect(users[2]).vote(newOracle, 1, initialBalance)
  //   expect((await gov.getOracle(newOracle))[0]['totalInfluence']).to.be.equal(initialBalance.mul(2))
  //   expect((await gov.getOracle(newOracle))[1]['voting']['approvalsInfluence']).to.be.equal(initialBalance)
  //   expect((await gov.getOracle(newOracle))[1]['voting']['againstInfluence']).to.be.equal(initialBalance)

  //   await gov.connect(users[3]).vote(newOracle, 2, initialBalance)
  //   expect((await gov.getOracle(newOracle))[0]['totalInfluence']).to.be.equal(initialBalance.mul(3))
  //   expect((await gov.getOracle(newOracle))[1]['voting']['approvalsInfluence']).to.be.equal(initialBalance)
  //   expect((await gov.getOracle(newOracle))[1]['voting']['againstInfluence']).to.be.equal(initialBalance)
  //   expect((await gov.getOracle(newOracle))[1]['voting']['abstainInfluence']).to.be.equal(initialBalance)

  //   await expect(gov.connect(users[2]).vote(newOracle, 3, initialBalance)).to.be.reverted; //not existing vote
  // })

  // it("Should pass vote", async () => {
  //   let newOracle = await users[1].getAddress()
  //   await gov.addOracle(newOracle)
  //   await gov.connect(users[1]).vote(newOracle, 0, initialBalance)
  //   await wait(ethers, 60*60*24*7);
  //   let tx = gov.finishVote(newOracle)
  //   console.log((await (await tx).wait()).events![0].args!.result)
  // })

  // it("Should not pass vote", async () => {
  //   let newOracle = await users[1].getAddress()
  //   await gov.addOracle(newOracle)
  //   await gov.connect(users[1]).vote(newOracle, 1, initialBalance)
  //   await wait(ethers, 60*60*24*7);
  //   let tx = gov.finishVote(newOracle)
  //   console.log((await (await tx).wait()).events![0].args!.result)
  // })
})
