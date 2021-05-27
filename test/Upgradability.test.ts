import { categories, markets, milestones, outcomes } from "../deploy/data"

import { ethers, upgrades } from "hardhat"
import { expect } from "chai"
import { BigNumberish, Signer } from "ethers"
import { setgroups } from "node:process"
import { AddressZero } from "@ethersproject/constants";
import { MarsPredictionMarketFactory, Register, Settlement, Parameters } from "../typechain"
import { bytes32, wait, timeoutAppended, now, tokens } from "./utils/utils"

describe("Upgradability", async () => {
    it("Register is upgradable", async() =>{
        deployAndUpgrade("Register", "RegisterV2")
    })

    it("Factory is upgradable", async() =>{
        deployAndUpgrade("MarsPredictionMarketFactory", "FactoryV2")
    })

    it("Market is upgradable", async() =>{
        deployAndUpgrade("MarsPredictionMarket", "MarketV2")
    })

    it("Settlement is upgradable", async() =>{
        deployAndUpgrade("Settlement", "SettlementV2")
    })

    it("Parameters is upgradable", async() =>{
        deployAndUpgrade("Parameters", "ParametersV2")
    })

    const deployAndUpgrade = async (original: string, newVersion: string) => {
        const Contract = await ethers.getContractFactory(original);
        const instance = await upgrades.deployProxy(Contract, [AddressZero, AddressZero])
        const ContractV2 = await ethers.getContractFactory(newVersion);
        const upgraded = await upgrades.upgradeProxy(instance.address, ContractV2);
        await upgraded.setValue(1232)
        expect (await upgraded.getValue()).to.be.equal(1232)
    }
})