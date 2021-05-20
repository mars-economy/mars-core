const categories = Array(
    Array(
    "0x5ffabec44f7a4cd58bf8fae36fe99003",
    "1",
    "Preparing for Mars",
    "At an accelerating rate, private companies and national space agencies together are conducting rapid iterative testing and preparing to  pilot missions. Engineers, scientists, artists, and designers around the world are laying the groundwork as humanity ventures to the next frontier."
    ),
    Array(
    "0xb00b5428da0349e48763781ed54d7579",
    "2",
    "Crossing the frontier",
    "Sending humans aboard a spacecraft to Mars will be no easy feat. How can we enable spacecraft to safely make the interplanetary journey between Earth and Mars while minimizing travel times and expenses?"
    ),
    Array(
    "0x64b11d8713b44ac2a32a55523c5a066d",
    "3",
    "Discovering the Red Planet",
    "Exploring Mars and generating scientific data from the planet's surface will be critical to the success of future missions as the insights gathered will enable humans to survive on this new frontier."
    ),
    Array(
    "0x8bd19e518f4f46dcae86a19480696416",
    "4",
    "A new home",
    "One of the first steps will be establishing a base on Mars, like the McMurdo Station in Antarctica or like the International Space Station, can be used as a hub for innovation, entrepreneurship, and space tourism."
    )
)
const milestones = Array(
Array("0x0f7f86d810024f96ad265b067ec6c348", "0x5ffabec44f7a4cd58bf8fae36fe99003", "1", "Crew for first Human Exploration Announced", ""),
Array("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814", "0xb00b5428da0349e48763781ed54d7579", "1", "First Orbital Flight of Starship", ""),
Array("0x521a30e96c1b40b08b3e98294e70a2f3", "0x64b11d8713b44ac2a32a55523c5a066d", "2", "First Human on Mars", ""),
Array("0xb938ddb63e9c495c824913ed85b48471", "0x8bd19e518f4f46dcae86a19480696416", "4", "Martian Colonization reaches 10000 humans", ""),
Array(
"0xc9dceba8d2ef45a2a0c5ca5465d4a129",
"0x64b11d8713b44ac2a32a55523c5a066d",
"1",
"Bringing Mars to Earth: Return Mars sample to Earth",
""
),
Array(
"0xa69b77f3bda54f38bac865785d81ea4e",
"0xb00b5428da0349e48763781ed54d7579",
"2",
"First Operational Earth-Mars logistics trip",
""
),
Array(
"0x132d38ff1bbf43d2a21383cc639f27fc",
"0xb00b5428da0349e48763781ed54d7579",
"3",
"First Operational Starship Earth return trip",
""
),
Array(
"0xc7c761629cfd40c0836604b7b547cbb9",
"0x8bd19e518f4f46dcae86a19480696416",
"1",
"First Rocket 3D printed on Mars is launched",
""
),
Array("0xc54d2a758cbd4e9ba66ca13930ef1d97", "0x8bd19e518f4f46dcae86a19480696416", "2", "First permanent habitat is operational", ""),
Array(
"0x7080980bc410420697265caf98eb149a",
"0x8bd19e518f4f46dcae86a19480696416",
"3",
"First utilization of Space Resources to supply habitat",
""
),
Array("0x95c6d5feed2f4e79a2d0aff3eba2a0e5", "0x64b11d8713b44ac2a32a55523c5a066d", "3", "Perseverance finds trace of life", "")
)
const markets = Array(
    Array(
    "0x0f7f86d810024f96ad265b067ec6c348",
    "1",
    "NASA will announce the planned crew members for first Human Exploration of Mars by the year of 2027",
    "",
    "1830297599"
    ),
    Array(
    "0x13a12ea1f1cb4b6e96a3fbdfcf8c9814",
    "1",
    "Starship will have its first orbital flight and safely land without exploding by the year of 2022",
    "",
    "1672531199"
    ),
    Array("0x521a30e96c1b40b08b3e98294e70a2f3", "1", "The first human will set foot on Mars by the year of 2035", "", "2082758399"),
    Array(
    "0xb938ddb63e9c495c824913ed85b48471",
    "1",
    "Mars-based activities have led to 10000 humans on Mars by the year of 2050",
    "",
    "2556143999"
    ),
    Array("0xc9dceba8d2ef45a2a0c5ca5465d4a129", "1", "An unmanned spacecraft will deliver Mars regolith samples to Earth by 2026", "", "1798761599"),
    Array("0xa69b77f3bda54f38bac865785d81ea4e", "1", "A spacecraft will deliver the first elements of a habitat for crewed exploration by 2028", "", "1861919999"),
    Array("0x132d38ff1bbf43d2a21383cc639f27fc", "1", "A Starship will return to Earth from a Mars trip by 2030", "", "1924991999"),
    Array("0xc7c761629cfd40c0836604b7b547cbb9", "1", "The first rocket or other spacecraft with parts produced on Mars will be launched by 2040", "", "2240611199"),
    Array("0xc54d2a758cbd4e9ba66ca13930ef1d97", "1", "The first permanent habitat constructed on the Mars surface will begin hosting astronauts by 2035", "", "2082758399"),
    Array("0x7080980bc410420697265caf98eb149a", "1", "A utilization of Space Resources found on Mars will take place to service a permanent crewed habitat by 2040", "", "2240611199"),
    Array("0x95c6d5feed2f4e79a2d0aff3eba2a0e5", "1", "The Mars Rover Perseverance will find traces of organic life on Mars in this decade", "", "1893455999")
)
const outcomes = Array(
    Array({uuid: "0xc53ef995914f4b409b22e6128c2bcf17", position: 1, name: "Yes"}, {uuid: "0xc2c2c6cb226b42c4b36bf4b4dcb6ba17", position: 1, name: "No"}),
    Array({uuid: "0x6f471a5b81d04c5c82336577df545a01", position: 1, name: "Yes"}, {uuid: "0x67626b863c99496dbce796d7c83415d6", position: 1, name: "No"}),
    Array({uuid: "0x63cf388c13914c9ea34e3947344a3a91", position: 1, name: "Yes"}, {uuid: "0xc15005a06937422780754f8d498fc25f", position: 1, name: "No"}),
    Array({uuid: "0xedf5058c59d34d5fa671b2035e4d9c1e", position: 1, name: "Yes"}, {uuid: "0x8a6bc88956ec4cf2ab28dd6b9d9a21d0", position: 1, name: "No"}),
    Array({uuid: "0x25174325d51d4db6801a1630ab6f0f8d", position: 1, name: "Yes"}, {uuid: "0x6ff4a1448cec42e1ba6acf2a10c83556", position: 1, name: "No"}),
    Array({uuid: "0xbf9cb9177ed84ee8b6b144f4a4c9c27d", position: 1, name: "Yes"}, {uuid: "0x5b9a045d776d45e89f321543c1a9a889", position: 1, name: "No"}),
    Array({uuid: "0x9484bbcd57484d6d9d871dff09acd73d", position: 1, name: "Yes"}, {uuid: "0x516e10a64c924de080054d0b252c3c31", position: 1, name: "No"}),
    Array({uuid: "0x8e67a039bcbb4805ace5d704336de274", position: 1, name: "Yes"}, {uuid: "0x7bd685df601d47d38ecc135b7f1b0915", position: 1, name: "No"}),
    Array({uuid: "0x8ded5a1b185040c6a7e745a64b91d8ad", position: 1, name: "Yes"}, {uuid: "0x6e91d0a8239e4e68bf3a82bb450d6898", position: 1, name: "No"}),
    Array({uuid: "0x86ac0df9c34d469fac158ce6d9696ad8", position: 1, name: "Yes"}, {uuid: "0x5e6d846b3ae246fe8a5c09d4b13f00fc", position: 1, name: "No"}),
    Array({uuid: "0x65971f65796749e4be49a707038e7784", position: 1, name: "Yes"}, {uuid: "0x13390113b9e34e96bd3b6443513e5786", position: 1, name: "No"})
  )

import { ethers, upgrades } from "hardhat"
import { expect } from "chai"
import { BigNumberish, Signer } from "ethers"
import { setgroups } from "node:process"
import { AddressZero } from "@ethersproject/constants";
import { MarsPredictionMarketFactory, Register, Settlement } from "../typechain"
import { bytes32, wait, timeoutAppended, now, tokens } from "./utils/utils"

describe("Register", async () => {
    let owner: Signer
    let register: Register
    let marsFactory: MarsPredictionMarketFactory
    let settlement: Settlement

    before(async () => {
      [owner] = await ethers.getSigners()
    })
  
    beforeEach(async () => {
        const registerContract = await ethers.getContractFactory("Register");
    
        register = await upgrades.deployProxy(registerContract, []) as Register


        settlement = (await (await ethers.getContractFactory("Settlement"))
            .connect(owner)
            .deploy()) as Settlement

        settlement.connect(owner).initialize(AddressZero)

        marsFactory = (await (await ethers.getContractFactory("MarsPredictionMarketFactory"))
            .connect(owner)
            .deploy()) as MarsPredictionMarketFactory
        
        marsFactory.connect(owner).initialize(await owner.getAddress(), settlement.address)

    })
  
    it("returns no values", async () => {
        expect((await register.getPredictionData()).length).to.be.equal(4)
        expect((await register.getPredictionData())[0].length).to.be.equal(0)
        expect((await register.getPredictionData())[1].length).to.be.equal(0)
        expect((await register.getPredictionData())[2].length).to.be.equal(0)
        expect((await register.getPredictionData())[3].length).to.be.equal(0)
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

        let data = await register.getPredictionData()
        expect (data.length).to.be.equal(4)
        expect (data[0].length).to.be.equal(categories.length)
        expect (data[1].length).to.be.equal(milestones.length)
        expect (data[2].length).to.be.equal(markets.length)
        expect (data[3].length).to.be.equal(outcomes.length*2)
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

        let data = await upgraded.getPredictionData()
        expect (data.length).to.be.equal(4)
        expect (data[0].length).to.be.equal(categories.length)
        expect (await upgraded.owner()).to.be.equal(await owner.getAddress())

        await upgraded.setValue(1232)
        expect (await upgraded.getValue()).to.be.equal(1232)
    })
})