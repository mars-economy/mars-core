// import { ethers, upgrades } from "hardhat"

const { ethers, upgrades } = require("hardhat");

import { expect } from "chai"
import { Contract, Signer } from "ethers"
import { bytes32, timeout, wait, now, timeoutAppended } from "./utils/utils"
import { MarsERC20Token } from "../typechain"
import { setgroups } from "node:process"

import {tokens} from "./utils/utils"

describe("MarsERC20Token", async () => {
  let owner: Signer
  let users: Signer[]
  let marsToken: MarsERC20Token

  beforeEach(async () => {
    ;[owner, ...users] = await ethers.getSigners()

    marsToken = (await (await ethers.getContractFactory("MarsERC20Token")).deploy("Mars", "DTK", 1683774000)) as MarsERC20Token
    await marsToken.deployed()
  })

  it("transferOwnership works", async() => {
    await marsToken.transferOwnership(await owner.getAddress())
    expect(await owner.getAddress() == await marsToken.owner())
  })
  
  it("transferOwnership works only for admin", async() => {
    let tx = marsToken.connect(users[0]).transferOwnership(await users[1].getAddress())
    await expect(tx).to.be.reverted
    expect(await owner.getAddress() == await marsToken.owner())
  })

  it("Owner of contract doesn't have initial balance", async() => {
    expect((await marsToken.balanceOf(await owner.getAddress())).toNumber()).to.be.equal(0)
  })
  
  it("Contract itself has no initial balance", async() => {
    let amount = (await marsToken.balanceOf(marsToken.address)).toString()

    expect(amount).to.be.equal("0")
  })

  it("Only owner can transfer tokens", async () => {
    let errorMessage = "Ownable: caller is not the owner"

    await expect(marsToken.connect(users[0])["mint(address,uint256,uint256)"](await users[0].getAddress(), 1000, 0))
      .to.be.revertedWith(errorMessage);
    
    await expect(marsToken.connect(owner)["mint(address,uint256,uint256)"](await users[0].getAddress(), 1000, 0))
      .to.be.not.revertedWith(errorMessage);

  })

  it("EmissionController can transfer as much as he wants", async () => {
    let errorMessage = "ONLY Emission Controller can mint"
    let eC = users[5]
    let eCa = await users[5].getAddress()

    await expect(marsToken.connect(eC)["mint(address,uint256)"](await users[0].getAddress(), 1000))
      .to.be.revertedWith(errorMessage);

    await marsToken.connect(owner).setEmissionController(eCa)

    await expect(marsToken.connect(eC)["mint(address,uint256)"](await users[0].getAddress(), tokens(1_000_000_000_000)))
      .to.be.not.revertedWith(errorMessage);
  })

  it("Coreteam once received can't transfer tokens until specified date", async () => {
    await marsToken.connect(owner)["mint(address,uint256,uint256)"](await users[0].getAddress(), 1000, 0)
    expect((await marsToken.getLockPeriod()).toNumber()).to.be.greaterThan(timeout(0))

    await expect(marsToken.connect(users[0]).transfer(await users[1].getAddress(), 1000))
      .to.be.revertedWith("MarsERC20: Tokens are locked until lockPeriod")
  })

  it("Other participants, once received can transfer tokens at any time", async () => {
    await marsToken.connect(owner)["mint(address,uint256,uint256)"](await users[0].getAddress(), 1000, 1)
    expect((await marsToken.getLockPeriod()).toNumber()).to.be.greaterThan(timeout(0))

    await expect(marsToken.connect(users[0]).transfer(await users[1].getAddress(), 1000))
      .to.be.not.revertedWith("MarsERC20: Tokens are locked until lockPeriod")
  })

  it("Coreteam can transfer tokens after", async () => {
    await marsToken.connect(owner)["mint(address,uint256,uint256)"](await users[0].getAddress(), 1000, 0)
    expect((await marsToken.getLockPeriod()).toNumber()).to.be.greaterThan(timeout(0))

    await wait(ethers, 60*60*24*365*3)

    await expect(marsToken.connect(users[0]).transfer(await users[1].getAddress(), 1000))
      .to.be.not.revertedWith("MarsERC20: Tokens are locked until lockPeriod")
  })

it("Only owner can change lockPeriod", async () => {
    let errorMessage = "Ownable: caller is not the owner"

    await expect(marsToken.connect(users[0]).setLockPeriod(12345))
      .to.be.revertedWith(errorMessage);
    
    expect((await marsToken.getLockPeriod()).toNumber()).to.be.equal(1683774000)
    
    await expect(marsToken.connect(owner).setLockPeriod(12345))
      .to.be.not.revertedWith(errorMessage);
    
    expect((await marsToken.getLockPeriod()).toNumber()).to.be.equal(12345)
  })
})