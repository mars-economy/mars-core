import { categories, markets, milestones, outcomes } from "../deploy/data"

import { ethers, upgrades } from "hardhat"
import { expect } from "chai"
import { BigNumberish, Signer } from "ethers"
import { setgroups } from "node:process"
import { AddressZero } from "@ethersproject/constants";
import { MarsPredictionMarketFactory, Register, Settlement, Parameters } from "../typechain"
import { bytes32, wait, timeoutAppended, now, tokens } from "./utils/utils"

describe("Register", async () => {
    let owner: Signer
    let register: Register
    let marsFactory: MarsPredictionMarketFactory
    let settlement: Settlement
    let parameters: Parameters

    before(async () => {
      [owner] = await ethers.getSigners()
    })
  
    beforeEach(async () => {
        const registerContract = await ethers.getContractFactory("Register");

        settlement = (await (await ethers.getContractFactory("Settlement"))
            .connect(owner)
            .deploy()) as Settlement

        parameters = (await (await ethers.getContractFactory("Parameters"))
            .connect(owner)
            .deploy()) as Parameters
        
        parameters.initialize(AddressZero, 10, 20, 10000, 60*60*24, 60*60*24*7, 60*60*24*7, tokens(100000), tokens(20000), 0, 0)
        
        settlement.connect(owner).initialize(AddressZero, parameters.address)
        
        register = await upgrades.deployProxy(registerContract, [settlement.address, parameters.address]) as Register
        
        marsFactory = (await (await ethers.getContractFactory("MarsPredictionMarketFactory"))
            .connect(owner)
            .deploy()) as MarsPredictionMarketFactory
        
        marsFactory.connect(owner).initialize(settlement.address)
        
    })
  
    it("returns no values", async () => {
        expect((await register.getPredictionData(await now(ethers.provider))).length).to.be.equal(4)
        expect((await register.getPredictionData(await now(ethers.provider)))[0].length).to.be.equal(0)
        expect((await register.getPredictionData(await now(ethers.provider)))[1].length).to.be.equal(0)
        expect((await register.getPredictionData(await now(ethers.provider)))[2].length).to.be.equal(0)
        expect((await register.getPredictionData(await now(ethers.provider)))[3].length).to.be.equal(0)
    })

    it("Should return a lot of values", async () => {
        for (let i of categories)
            await expect(register.updateCategory(i[0], i[1], i[2], i[3])).to.emit(register, "CategoryUpdatedEvent")
        for (let i of milestones)
            await expect(register.updateMilestone(i[0], i[1], i[2], i[3], i[4], 0)).to.emit(register, "MilestoneUpdatedEvent")
        for (let i = 0; i < markets.length; i++) {
            let tx = await marsFactory.connect(owner).createMarket(AddressZero, parseInt(markets[i][4]), outcomes[i], tokens(1), tokens(10))
            let rx = await tx.wait()
            let addr = await rx.events![4].args!._market

            await expect(register.registerMarket(                
                        addr,
                        markets[i][0], parseInt(markets[i][1]), markets[i][2], markets[i][3], 
                        AddressZero, parseInt(markets[i][4]), parseInt(markets[i][4]), outcomes[i])).to.emit(register, "PredictionMarketRegisteredEvent")
        }

        let data = await register.getPredictionData(await now(ethers.provider))
        expect (data.length).to.be.equal(4)
        expect (data[0].length).to.be.equal(categories.length)
        expect (data[1].length).to.be.equal(milestones.length)
        expect (data[2].length).to.be.equal(markets.length)
        expect (data[3].length).to.be.equal(outcomes.length*2)
        console.log(data)
    })

    it("Should show slot correctly", async () =>{
    for (let i of categories)
        await expect(register.updateCategory(i[0], i[1], i[2], i[3])).to.emit(register, "CategoryUpdatedEvent")
    for (let i of milestones)
        await expect(register.updateMilestone(i[0], i[1], i[2], i[3], i[4], 0)).to.emit(register, "MilestoneUpdatedEvent")
    for (let i = 0; i < markets.length; i++) {
        let tx = await marsFactory.connect(owner).createMarket(AddressZero, parseInt(markets[i][4]), outcomes[i], tokens(1), tokens(10))
        let rx = await tx.wait()
        let addr = await rx.events![4].args!._market

        await expect(register.registerMarket(                
                    addr,
                    markets[i][0], parseInt(markets[i][1]), markets[i][2], markets[i][3], 
                    AddressZero, parseInt(markets[i][4]), parseInt(markets[i][4]), outcomes[i])).to.emit(register, "PredictionMarketRegisteredEvent")
    }
    expect(await register.slot("0xc53ef995914f4b409b22e6128c2bcf17")).to.be.equal(0);
    expect(await register.slot("0x8bd19e518f4f46dcae86a19480696416")).to.be.equal(3);
    expect(await register.slot("0x521a30e96c1b40b08b3e98294e70a2f3")).to.be.equal(2);
    })

    it("Should upgrade, not lose data, and new funcs should also work", async() =>{
        for (let i of categories)
            await expect(register.updateCategory(i[0], i[1], i[2], i[3])).to.emit(register, "CategoryUpdatedEvent")

        const RegisterV2 = await ethers.getContractFactory("RegisterV2");
        const upgraded = await upgrades.upgradeProxy(register.address, RegisterV2);

        let data = await upgraded.getPredictionData(await now(ethers.provider))
        expect (data.length).to.be.equal(4)
        expect (data[0].length).to.be.equal(categories.length)
        expect (await upgraded.owner()).to.be.equal(await owner.getAddress())

        await upgraded.setValue(1232)
        expect (await upgraded.getValue()).to.be.equal(1232)
    })
})