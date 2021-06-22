import { ethers, network } from "hardhat"
import { wethAddress } from "./weth"
import { BigNumber, Contract } from "ethers"
import { LogDescription } from "ethers/lib/utils"
import fs from "fs"

import hre from "hardhat"
import { MarsERC20Token } from "../typechain"

var ADDR = {
  daiToken: "",
  marsToken: "",
  govToken: "",
  governance: "",
  settlement: "",
  predictionMarketFactory: "",
}

async function deployGovToken(wethAddress: string) {
  const GovToken = await ethers.getContractFactory("ERC20")
  const govToken = await GovToken.deploy(1_000_000, "Test govToken", 18, "GTK")
  await govToken.deployed()
  console.log("govToken:", govToken.address)
  ADDR["govToken"] = govToken.address
  return govToken.address
}

// async function deployMarsToken(wethAddress: string) {
//   const MarsToken = await ethers.getContractFactory("MarsERC20Token")
//   const marsToken = await MarsToken.deploy()
//   await marsToken.initialize(BigNumber.from(1_000_000_000).mul(BigNumber.from(10).pow(18)), "Test marsToken", 18, "DMT")

//   await marsToken.deployed()
//   console.log("marsToken:", marsToken.address)
//   ADDR["marsToken"] = marsToken.address
//   return marsToken.address
// }

async function deployMarsToken(wethAddress: string) {
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  // const marsToken = await MarsToken.deploy()

  const marsToken = await hre.upgrades.deployProxy(
    MarsToken,
    [BigNumber.from(1_000_000_000).mul(BigNumber.from(10).pow(18)), "Test marsToken", 18, "DMT"],
    { initializer: "initialize" }
  )

  await marsToken.deployed()
  console.log("marsToken:", marsToken.address)
  ADDR["marsToken"] = marsToken.address
  return marsToken.address
}

async function testMars() {
  let addr = "0x22cabD17a710fa04383C7EcE5B33014d231630Dd"
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  const mars = MarsToken.attach(addr) as MarsERC20Token
  console.log("Owner:", await mars.owner())
  console.log("Symbool:", await mars.symbol())
}

async function testMars2() {
  let addr = "0x22cabD17a710fa04383C7EcE5B33014d231630Dd"
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  const mars = MarsToken.attach(addr) as MarsERC20Token
  console.log("Owner:", await mars.owner())
  console.log("Symbool:", await mars.symbol())
  console.log("wqerty:", await mars.wqerty())
}

async function upgradeMarsToken() {
  let addr = "0x22cabD17a710fa04383C7EcE5B33014d231630Dd"
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  const mars = MarsToken.attach(addr) as MarsERC20Token

  const marsToken = await hre.upgrades.upgradeProxy(addr, MarsToken)

  await marsToken.deployed()
  console.log("marsToken:", marsToken.address)
  ADDR["marsToken"] = marsToken.address
}

async function deployDaiToken(wethAddress: string) {
  const DaiToken = await ethers.getContractFactory("ERC20")
  const daiToken = await DaiToken.deploy(1_000_000 * 10 ** 18, "Test daiToken", 18, "GTK")
  await daiToken.deployed()
  console.log("daiToken:", daiToken.address)
  ADDR["daiToken"] = daiToken.address
  return daiToken.address
}

async function deployGovernance(wethAddress: string) {
  const Governance = await ethers.getContractFactory("MarsGovernance")
  const governance = await Governance.deploy(ADDR["govToken"])
  await governance.deployed()
  console.log("governance:", governance.address)
  ADDR["governance"] = governance.address
  return governance.address
}

async function deploySettlement(wethAddress: string) {
  const Settlement = await ethers.getContractFactory("Settlement")
  //   const settlement = await Settlement.deploy(ADDR["marsToken"], ADDR["governance"])
  const settlement = await Settlement.deploy(ADDR["marsToken"], ADDR["marsToken"]) //first parameter is marstoken address, and second parameter is ignored
  await settlement.deployed()
  console.log("settlement:", settlement.address)
  ADDR["settlement"] = settlement.address
  return settlement.address
}

async function deployFactory(wethAddress: string) {
  const Factory = await ethers.getContractFactory("MarsPredictionMarketFactory")
  //   const predictionMarketFactory = await Factory.deploy(ADDR["govToken"])
  const predictionMarketFactory = await Factory.deploy(ADDR["marsToken"], ADDR["settlement"]) //first paramater is address resolver, second is settlement
  await predictionMarketFactory.deployed()
  console.log("predictionMarketFactory:", predictionMarketFactory.address)
  ADDR["predictionMarketFactory"] = predictionMarketFactory.address
  return predictionMarketFactory.address
}

async function createCategory(uuid: string, position: number, name: string, description: string) {
  const factory = await ethers.getContractFactory("MarsPredictionMarketFactory")
  const predictionMarketFactory = await factory.attach(ADDR["predictionMarketFactory"])

  const [me] = await ethers.getSigners()
  await (await predictionMarketFactory.connect(me).updateCategory(ethers.utils.arrayify(uuid), position, name, description)).wait()
}

async function createMilestone(uuid: string, categoryUuid: string, position: number, name: string, description: string) {
  const factory = await ethers.getContractFactory("MarsPredictionMarketFactory")
  const predictionMarketFactory = await factory.attach(ADDR["predictionMarketFactory"])

  const [me] = await ethers.getSigners()
  await (
    await predictionMarketFactory
      .connect(me)
      .updateMilestone(ethers.utils.arrayify(uuid), ethers.utils.arrayify(categoryUuid), position, name, description, 1)
  ).wait()
}

async function getPredictionMarketCreatedEvents(
  predictionMarketFactory: Contract,
  fromBlock: number | undefined
): Promise<LogDescription[]> {
  const eventFragment = predictionMarketFactory.interface.getEvent("PredictionMarketCreatedEvent")
  const topic = predictionMarketFactory.interface.getEventTopic(eventFragment)
  const filter = { topics: [topic], address: predictionMarketFactory.address, fromBlock }
  const swapLogs = await predictionMarketFactory.provider.getLogs(filter)
  return swapLogs.map((log) => predictionMarketFactory.interface.parseLog(log))
}

var options = { gasLimit: 7000000 }

async function createMarket(
  milestoneUuid: string,
  position: number,
  name: string,
  description: string,
  token: string,
  dueDate: number,
  outcomes: string[][]
) {
  const factory = await ethers.getContractFactory("MarsPredictionMarketFactory")
  const predictionMarketFactory = await factory.attach(ADDR["predictionMarketFactory"])

  const [me] = await ethers.getSigners()
  let tx = await predictionMarketFactory
    .connect(me)
    .createMarket(ethers.utils.arrayify(milestoneUuid), position, name, description, token, dueDate, options)

  tx = await tx.wait()

  const events = await getPredictionMarketCreatedEvents(predictionMarketFactory, tx.blockNumber)

  console.log(events)

  const marketAddress = events[0].args.contractAddress
  console.log("Created market " + marketAddress)

  for (var i = 0; i < outcomes.length; i++) {
    await (
      await predictionMarketFactory.connect(me).addOutcome(marketAddress, ethers.utils.arrayify(outcomes[i][0]), i + 1, outcomes[i][1])
    ).wait()
  }
}

async function addOutcomes(marketAddress: string, outcomes: string[][]) {
  const factory = await ethers.getContractFactory("MarsPredictionMarketFactory")
  const predictionMarketFactory = await factory.attach(ADDR["predictionMarketFactory"])

  const [me] = await ethers.getSigners()
  for (var i = 0; i < outcomes.length; i++) {
    await (
      await predictionMarketFactory.connect(me).addOutcome(marketAddress, ethers.utils.arrayify(outcomes[i][0]), i + 1, outcomes[i][1])
    ).wait()
  }
}

async function populateMarkets() {
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
    Array(
      "0x0f7f86d810024f96ad265b067ec6c348",
      "0x5ffabec44f7a4cd58bf8fae36fe99003",
      "1",
      "Crew for first Human Exploration Announced",
      ""
    ),
    Array("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814", "0xb00b5428da0349e48763781ed54d7579", "2", "First Orbital Flight of Starship", ""),
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
      "3",
      "First Operational Earth-Mars logistics trip",
      ""
    ),
    Array(
      "0x132d38ff1bbf43d2a21383cc639f27fc",
      "0xb00b5428da0349e48763781ed54d7579",
      "4",
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
    Array("0x95c6d5feed2f4e79a2d0aff3eba2a0e5", "0x64b11d8713b44ac2a32a55523c5a066d", "3", "Perseverance finds trace of life", ""),
    Array("0x9823b01faeed4b139ea387920c16551e", "0xb00b5428da0349e48763781ed54d7579", "1", "Succesful test flight for SN16", "")
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
    Array(
      "0xc9dceba8d2ef45a2a0c5ca5465d4a129",
      "1",
      "An unmanned spacecraft will deliver Mars regolith samples to Earth by 2026",
      "",
      "1798761599"
    ),
    Array(
      "0xa69b77f3bda54f38bac865785d81ea4e",
      "1",
      "A spacecraft will deliver the first elements of a habitat for crewed exploration by 2028",
      "",
      "1861919999"
    ),
    Array("0x132d38ff1bbf43d2a21383cc639f27fc", "1", "A Starship will return to Earth from a Mars trip by 2030", "", "1924991999"),
    Array(
      "0xc7c761629cfd40c0836604b7b547cbb9",
      "1",
      "The first rocket or other spacecraft with parts produced on Mars will be launched by 2040",
      "",
      "2240611199"
    ),
    Array(
      "0xc54d2a758cbd4e9ba66ca13930ef1d97",
      "1",
      "The first permanent habitat constructed on the Mars surface will begin hosting astronauts by 2035",
      "",
      "2082758399"
    ),
    Array(
      "0x7080980bc410420697265caf98eb149a",
      "1",
      "A utilization of Space Resources found on Mars will take place to service a permanent crewed habitat by 2040",
      "",
      "2240611199"
    ),
    Array(
      "0x95c6d5feed2f4e79a2d0aff3eba2a0e5",
      "1",
      "The Mars Rover Perseverance will find traces of organic life on Mars in this decade",
      "",
      "1893455999"
    ),
    Array("0x9823b01faeed4b139ea387920c16551e", "1", "SN16 Starship prototype flies by July 2021", "", "1627775999")
  )

  //const marketAddress = Array(
  //  "0x07B21a1de9eB34098820b45132bC831ae5887040",
  //  "0x9Fbb1106B708ea5e261aCc6FDB9CD85Fd3eC78ee",
  //  "0x9F35f71610a4F748203Fb20941cd881e83ac490b",
  //  "0xa012A8268612772db0e0f4c1d7883b895b1cfE64",
  //  "0x5E7634C4B5fd6E590F47Eb40ad4C5b8Dc4183066",
  //  "0x0A1C804EbB869D2D79D1eAE8E278Cd504840A423",
  //  "0xdaB367840415C7f666F5863B6f6CDD2e132912D1",
  //  "0xd3569a23A7dB630AA4C74160548F3A97E97a1160",
  //  "0x6F328A3a70828b984d88B7752B4211A2Ee1aCEeE",
  //  "0x5E0fe83ee18B3Bd7608028C31DE1a259767E4EC3",
  //  "0xBC92365e267966C290689f838caC69E889391cE1",
  //  "0x8be99FFC6C0e2fec81B3BbA199882Af3C737d568",
  //  "0x6D418e9792c99463d1d034CE57704ac04E2Dbdec",
  //  "0xA7B5A6fF97Ea26AcB1cfBfE1ffaEbF46C6ef072d"
  //)

  const outcomes = Array(
    Array(Array("0xc53ef995914f4b409b22e6128c2bcf17", "Yes"), Array("0xc2c2c6cb226b42c4b36bf4b4dcb6ba17", "No")),
    Array(Array("0x6f471a5b81d04c5c82336577df545a01", "Yes"), Array("0x67626b863c99496dbce796d7c83415d6", "No")),
    Array(Array("0x63cf388c13914c9ea34e3947344a3a91", "Yes"), Array("0xc15005a06937422780754f8d498fc25f", "No")),
    Array(Array("0xedf5058c59d34d5fa671b2035e4d9c1e", "Yes"), Array("0x8a6bc88956ec4cf2ab28dd6b9d9a21d0", "No")),
    Array(Array("0x25174325d51d4db6801a1630ab6f0f8d", "Yes"), Array("0x6ff4a1448cec42e1ba6acf2a10c83556", "No")),
    Array(Array("0xbf9cb9177ed84ee8b6b144f4a4c9c27d", "Yes"), Array("0x5b9a045d776d45e89f321543c1a9a889", "No")),
    Array(Array("0x9484bbcd57484d6d9d871dff09acd73d", "Yes"), Array("0x516e10a64c924de080054d0b252c3c31", "No")),
    Array(Array("0x8e67a039bcbb4805ace5d704336de274", "Yes"), Array("0x7bd685df601d47d38ecc135b7f1b0915", "No")),
    Array(Array("0x8ded5a1b185040c6a7e745a64b91d8ad", "Yes"), Array("0x6e91d0a8239e4e68bf3a82bb450d6898", "No")),
    Array(Array("0x86ac0df9c34d469fac158ce6d9696ad8", "Yes"), Array("0x5e6d846b3ae246fe8a5c09d4b13f00fc", "No")),
    Array(Array("0x65971f65796749e4be49a707038e7784", "Yes"), Array("0x13390113b9e34e96bd3b6443513e5786", "No")),
    Array(Array("0x10a6bd7101fd411b84e4d10b34148785", "Yes"), Array("0x662903e3f9cf4b79a2eed3a76b6e2b0e", "No"))
  )

  for (var i = 0; i < categories.length; i++) {
    console.log(i, categories.length)
    await createCategory(categories[i][0], parseInt(categories[i][1]), categories[i][2], categories[i][3])
  }
  console.log("CATEGORIES DONE")

  for (var i = 0; i < milestones.length; i++) {
    console.log(i, milestones.length)
    await createMilestone(milestones[i][0], milestones[i][1], parseInt(milestones[i][2]), milestones[i][3], milestones[i][4])
  }
  console.log("MILESTONES DONE")

  for (var i = 0; i < markets.length; i++) {
    console.log(i, markets.length)
    await createMarket(
      markets[i][0],
      parseInt(markets[i][1]),
      markets[i][2],
      markets[i][3],
      "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee",
      parseInt(markets[i][4]),
      outcomes[i]
    )
  }
  console.log("MARKETS DONE")

  // DEPRECATED
  // // for(var i = 0; i < marketAddress.length; i++) {
  // // 	console.log(i, marketAddress.length)
  // // 	await addOutcomes(marketAddress[i], outcomes[i])
  // // }
  // console.log("MARKETADDRESS DONE")
}

async function main() {
  //ADDR["govToken"] = '0x3bBBB30f880cDC6a611411c00df05024504c306d'
  //ADDR["governance"] = '0x027AF35e1617Be2eCEfB02057EB93Abc9467A615'
  //ADDR["daiToken"] = "0x8Cc71938F07dFa9549B70a545eEB8FE40c9FD258"
  //ADDR["marsToken"] = "0xb35B7e4C616C06A6f37c436D6e5231B6a34694c0"
  //ADDR["settlement"] = "0xF9691e47D0fC81dFBCbAca30ddADe46502e4E9b0"
  //ADDR["predictionMarketFactory"] = "0xCbE287517a229fa308960251aA30b55abA7E1fE3"

  // const governanceRouter = await deployGovernanceRouter(wethAddress[network.name]);
  //   await deployGovToken("")
  //   await deployGovernance("")

  //   await deployDaiToken("")
  // await deployMarsToken("")
  // await deploySettlement("")
  // await deployFactory("") //Factory.deploy(ADDR["marsToken"], ADDR["settlement"])

  await testMars()
  await upgradeMarsToken()
  await testMars2()

  //await governance.setSettlement(settlement.address)
  //await predictionMarket.connect(owner).setSettlement(settlement.address)
  //await governance.connect(owner).setFactory(predictionMarketFactory.address)

  // await populateMarkets()

  try {
    // fs.writeFileSync("contract-addresses.json", JSON.stringify(ADDR, null, "\t"))
  } catch {
    console.log("Failed to create addresses file")
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

async function deployMarsToken() {
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")

  const marsToken = await hre.upgrades.deployProxy(MarsToken, ["Decentralized Mars Token", "$DMT", 1684108800], {
    initializer: "initialize",
  })

  await marsToken.deployed()
  console.log("marsToken:", marsToken.address)
  return marsToken.address
}

async function upgradeMarsToken(addr: any) {
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  const mars = MarsToken.attach(addr) as MarsERC20Token

  const marsToken = await hre.upgrades.upgradeProxy(addr, MarsToken)

  await marsToken.deployed()
  console.log("marsToken:", marsToken.address)
}

async function testMars(addr: any) {
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  const mars = MarsToken.attach(addr) as MarsERC20Token
  console.log("Owner:", await mars.owner())
  console.log("Symbol:", await mars.symbol())
}

async function testMars2(addr: any) {
  const MarsToken = await ethers.getContractFactory("MarsERC20Token")
  const mars = MarsToken.attach(addr) as MarsERC20Token
  console.log("Owner:", await mars.owner())
  console.log("value:", await mars.getValue())
}
