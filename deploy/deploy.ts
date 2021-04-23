import { ethers, network } from "hardhat"
import { wethAddress } from "./weth"
import { BigNumber, Contract } from "ethers"
import { LogDescription } from "ethers/lib/utils";
import fs from "fs"

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

async function deployMarsToken(wethAddress: string) {
  const MarsToken = await ethers.getContractFactory("ERC20")
  const marsToken = await MarsToken.deploy(1_000_000, "Test marsToken", 18, "DMT")
  await marsToken.deployed()
  console.log("marsToken:", marsToken.address)
  ADDR["marsToken"] = marsToken.address
  return marsToken.address
}

async function deployDaiToken(wethAddress: string) {
  const DaiToken = await ethers.getContractFactory("ERC20")
  const daiToken = await DaiToken.deploy(1_000_000, "Test daiToken", 18, "GTK")
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
  const settlement = await Settlement.deploy(ADDR["marsToken"], ADDR["governance"])
  await settlement.deployed()
  console.log("settlement:", settlement.address)
  ADDR["settlement"] = settlement.address
  return settlement.address
}

async function deployFactory(wethAddress: string) {
  const Factory = await ethers.getContractFactory("MarsPredictionMarketFactory")
  const predictionMarketFactory = await Factory.deploy(ADDR["govToken"])
  await predictionMarketFactory.deployed()
  console.log("predictionMarketFactory:", predictionMarketFactory.address)
  ADDR["predictionMarketFactory"] = predictionMarketFactory.address
  return predictionMarketFactory.address
}

async function createCategory(uuid: string, position: number, name: string, description: string) {
    const factory = await ethers.getContractFactory("MarsPredictionMarketFactory");
	const predictionMarketFactory = await factory.attach(ADDR["predictionMarketFactory"]);
	
	const [me] = await ethers.getSigners();
	await (await predictionMarketFactory.connect(me).updateCategory(ethers.utils.arrayify(uuid), position, name, description)).wait()
}

async function createMilestone(uuid: string, categoryUuid: string, position: number, name: string, description: string) {
    const factory = await ethers.getContractFactory("MarsPredictionMarketFactory");
	const predictionMarketFactory = await factory.attach(ADDR["predictionMarketFactory"]);
	
	const [me] = await ethers.getSigners();
	await (await predictionMarketFactory.connect(me).updateMilestone(ethers.utils.arrayify(uuid), 
			ethers.utils.arrayify(categoryUuid), position, name, description, 1)).wait()
}

async function getPredictionMarketCreatedEvents(predictionMarketFactory: Contract, fromBlock: number|undefined): Promise<LogDescription[]> {
    const eventFragment = predictionMarketFactory.interface.getEvent('PredictionMarketCreatedEvent');
    const topic = predictionMarketFactory.interface.getEventTopic(eventFragment);
    const filter = { topics: [topic], address: predictionMarketFactory.address, fromBlock };
    const swapLogs = await predictionMarketFactory.provider.getLogs(filter);
    return swapLogs.map(log => predictionMarketFactory.interface.parseLog(log));
}

async function createMarket(
	milestoneUuid: string, 
	position: number, 
	name: string, 
	description: string,
	token: string,
	dueDate: number,
	outcomes: string[][]
	) {

    const factory = await ethers.getContractFactory("MarsPredictionMarketFactory");
	const predictionMarketFactory = await factory.attach(ADDR["predictionMarketFactory"]);
	
	const [me] = await ethers.getSigners();
	const tx = await predictionMarketFactory.connect(me).createMarket(ethers.utils.arrayify(milestoneUuid), 
			position, name, description, token, dueDate)
	await tx.wait()

	/*const events = await getPredictionMarketCreatedEvents(predictionMarketFactory, tx.blockNumber)
	const marketAddress = events[0].args.contractAddress
	console.log("Created market " + marketAddress) 
			
	for(var i = 0; i < outcomes.length; i++) {
		await (await predictionMarketFactory.connect(me).addOutcome(marketAddress, ethers.utils.arrayify(outcomes[i][0]), 
			i + 1, outcomes[i][1])).wait()
	}*/
}

async function addOutcomes(
	marketAddress: string, 
	outcomes: string[][]
	) {

    const factory = await ethers.getContractFactory("MarsPredictionMarketFactory");
	const predictionMarketFactory = await factory.attach(ADDR["predictionMarketFactory"]);
	
	const [me] = await ethers.getSigners();
	for(var i = 0; i < outcomes.length; i++) {
		await (await predictionMarketFactory.connect(me).addOutcome(marketAddress, ethers.utils.arrayify(outcomes[i][0]), 
			i + 1, outcomes[i][1])).wait()
	}
}

async function populateMarkets() {
	
	const categories = Array(
			Array("0x5ffabec44f7a4cd58bf8fae36fe99003", "1", "PREPARING FOR MARS", ""),
			Array("0xb00b5428da0349e48763781ed54d7579", "2", "CROSSING THE FRONTIER", ""),
			Array("0x64b11d8713b44ac2a32a55523c5a066d", "3", "DISCOVERING THE RED PLANET", ""),
			Array("0x8bd19e518f4f46dcae86a19480696416", "4", "A NEW HOME", ""))

	const milestones = Array(
			Array("0x0f7f86d810024f96ad265b067ec6c348", "0x5ffabec44f7a4cd58bf8fae36fe99003", "1", "Crew for first Human Exploration Announced", ""),
			Array("0x9823b01faeed4b139ea387920c16551e", "0xb00b5428da0349e48763781ed54d7579", "1", "Succesful test flight for SNX (constant updates)", ""),
			Array("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814", "0xb00b5428da0349e48763781ed54d7579", "2", "First success of Spaceship Orbital Flight", ""),
			Array("0xa69b77f3bda54f38bac865785d81ea4e", "0xb00b5428da0349e48763781ed54d7579", "3", "First Operational Earth-Mars logistics trip", ""),
			Array("0x132d38ff1bbf43d2a21383cc639f27fc", "0xb00b5428da0349e48763781ed54d7579", "4", "First Operational Starship Earth return trip", ""),
			Array("0xc9dceba8d2ef45a2a0c5ca5465d4a129", "0x64b11d8713b44ac2a32a55523c5a066d", "1", "Bringing Mars to Earth: Return Mars sample to Earth", ""),
			Array("0x521a30e96c1b40b08b3e98294e70a2f3", "0x64b11d8713b44ac2a32a55523c5a066d", "2", "First Human on Mars", ""),
			Array("0x95c6d5feed2f4e79a2d0aff3eba2a0e5", "0x64b11d8713b44ac2a32a55523c5a066d", "3", "Perseverance finds trace of life", ""),
			Array("0xc7c761629cfd40c0836604b7b547cbb9", "0x8bd19e518f4f46dcae86a19480696416", "1", "First Rocket 3D printed on Mars is launched", ""),
			Array("0xc54d2a758cbd4e9ba66ca13930ef1d97", "0x8bd19e518f4f46dcae86a19480696416", "2", "First permanent habitat is operational", ""),
			Array("0x7080980bc410420697265caf98eb149a", "0x8bd19e518f4f46dcae86a19480696416", "3", "First utilization of Space Resources to supply habitat", ""),
			Array("0xb938ddb63e9c495c824913ed85b48471", "0x8bd19e518f4f46dcae86a19480696416", "4", "Colony established with 10000 inhabitants", ""))

	const markets = Array(
			Array("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814", "1", "By 2022", "", "1640995200"),
			Array("0x0f7f86d810024f96ad265b067ec6c348", "1", "By 2025", "", "1735689600"),
			Array("0x0f7f86d810024f96ad265b067ec6c348", "2", "Which Agency?", "", "1735689600"),
			Array("0x9823b01faeed4b139ea387920c16551e", "1", "By June, 1 2021", "", "1622505600"),
			Array("0xa69b77f3bda54f38bac865785d81ea4e", "1", "By 2035", "", "2051222400"),
			Array("0xa69b77f3bda54f38bac865785d81ea4e", "2", "Starship vs SLS", "", "2051222400"),
			Array("0x132d38ff1bbf43d2a21383cc639f27fc", "1", "By 2026", "", "1767225600"),
			Array("0xc9dceba8d2ef45a2a0c5ca5465d4a129", "1", "By 2026", "", "1767225600"),
			Array("0x521a30e96c1b40b08b3e98294e70a2f3", "1", "By 2032", "", "1956528000"),
			Array("0x95c6d5feed2f4e79a2d0aff3eba2a0e5", "1", "By 2026", "", "1767225600"),
			Array("0xc7c761629cfd40c0836604b7b547cbb9", "1", "By 2040", "", "2208988800"),
			Array("0xc54d2a758cbd4e9ba66ca13930ef1d97", "1", "By 2026", "", "1767225600"),
			Array("0x7080980bc410420697265caf98eb149a", "1", "By 2030", "", "1893456000"),
			Array("0xb938ddb63e9c495c824913ed85b48471", "1", "By 2040", "", "2208988800"))
			
	const marketAddress = Array(
		"0x07B21a1de9eB34098820b45132bC831ae5887040",
		"0x9Fbb1106B708ea5e261aCc6FDB9CD85Fd3eC78ee",
		"0x9F35f71610a4F748203Fb20941cd881e83ac490b",
		"0xa012A8268612772db0e0f4c1d7883b895b1cfE64",
		"0x5E7634C4B5fd6E590F47Eb40ad4C5b8Dc4183066",
		"0x0A1C804EbB869D2D79D1eAE8E278Cd504840A423",
		"0xdaB367840415C7f666F5863B6f6CDD2e132912D1",
		"0xd3569a23A7dB630AA4C74160548F3A97E97a1160",
		"0x6F328A3a70828b984d88B7752B4211A2Ee1aCEeE",
		"0x5E0fe83ee18B3Bd7608028C31DE1a259767E4EC3",
		"0xBC92365e267966C290689f838caC69E889391cE1",
		"0x8be99FFC6C0e2fec81B3BbA199882Af3C737d568",
		"0x6D418e9792c99463d1d034CE57704ac04E2Dbdec",
		"0xA7B5A6fF97Ea26AcB1cfBfE1ffaEbF46C6ef072d"
	)

	const outcomes = Array(
				Array(
					Array("0xc53ef995914f4b409b22e6128c2bcf17", "Yes"),
					Array("0xc2c2c6cb226b42c4b36bf4b4dcb6ba17", "No")),
				Array(
					Array("0x6f471a5b81d04c5c82336577df545a01", "Yes"),
					Array("0x67626b863c99496dbce796d7c83415d6", "No")),
				Array(
					Array("0x6f2c59ae3ef74e48a11e6906e960fa9e", "NASA"),
					Array("0x3f28d8be756f4bd7814b55a3ff89d5ce", "ESA"),
					Array("0x338e8e790e2e4d509c7adc17e60c16f7", "JAXA"),
					Array("0xdd67a01d84bd402aa415b48bd249eddc", "RUS"),
					Array("0xdd8f8f23f73c4c08a8a1fbe88e33f17a", "PRC"),
					Array("0xe005197444bf4a79a6b34eb75f973954", "Others")
					),
				Array(
					Array("0x63cf388c13914c9ea34e3947344a3a91", "Yes"),
					Array("0xc15005a06937422780754f8d498fc25f", "No")),
				Array(
					Array("0xedf5058c59d34d5fa671b2035e4d9c1e", "Yes"),
					Array("0x8a6bc88956ec4cf2ab28dd6b9d9a21d0", "No")),
				Array(
					Array("0x278c55433d184d499d8fdaca9737df4e", "Starship"),
					Array("0x48e8732aca854301b78f5cd285bcab6b", "SLS")
					),
				Array(
					Array("0x25174325d51d4db6801a1630ab6f0f8d", "Yes"),
					Array("0x6ff4a1448cec42e1ba6acf2a10c83556", "No")),
				Array(
					Array("0xbf9cb9177ed84ee8b6b144f4a4c9c27d", "Yes"),
					Array("0x5b9a045d776d45e89f321543c1a9a889", "No")),
				Array(
					Array("0x9484bbcd57484d6d9d871dff09acd73d", "Yes"),
					Array("0x516e10a64c924de080054d0b252c3c31", "No")),
				Array(
					Array("0x8e67a039bcbb4805ace5d704336de274", "Yes"),
					Array("0x7bd685df601d47d38ecc135b7f1b0915", "No")),
				Array(
					Array("0x8ded5a1b185040c6a7e745a64b91d8ad", "Yes"),
					Array("0x6e91d0a8239e4e68bf3a82bb450d6898", "No")),
				Array(
					Array("0x86ac0df9c34d469fac158ce6d9696ad8", "Yes"),
					Array("0x5e6d846b3ae246fe8a5c09d4b13f00fc", "No")),
				Array(
					Array("0x65971f65796749e4be49a707038e7784", "Yes"),
					Array("0x13390113b9e34e96bd3b6443513e5786", "No")),
				Array(
					Array("0x10a6bd7101fd411b84e4d10b34148785", "Yes"),
					Array("0x662903e3f9cf4b79a2eed3a76b6e2b0e", "No")))

					
	for(var i = 0; i < categories.length; i++) {
		await createCategory(categories[i][0], parseInt(categories[i][1]), categories[i][2], categories[i][3])	
	}

	for(var i = 0; i < milestones.length; i++) {
		await createMilestone(milestones[i][0], milestones[i][1], parseInt(milestones[i][2]), milestones[i][3], milestones[i][4])	
	}

	for(var i = 0; i < markets.length; i++) {
		await createMarket(markets[i][0], parseInt(markets[i][1]), markets[i][2], markets[i][3], "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee", 
			parseInt(markets[i][4]), outcomes[i])	
	}

	for(var i = 0; i < marketAddress.length; i++) {
		await addOutcomes(marketAddress[i], outcomes[i])
	}
					
}

async function main() {
	
  //ADDR["marsToken"] = '0x9a1Ab8dfa80A4f86BaCf829Dd28bc94CD60863Aa'	
  //ADDR["govToken"] = '0x3bBBB30f880cDC6a611411c00df05024504c306d'	
  //ADDR["governance"] = '0x027AF35e1617Be2eCEfB02057EB93Abc9467A615'	
  //ADDR["predictionMarketFactory"] = '0x436aE9860aBC1cE5168837B18160Bc22C976Ea5E'	
  //ADDR["settlement"] = '0x360F74d8001987c643a6b66a44a28e25b92Bc0a6'	
	
  // const governanceRouter = await deployGovernanceRouter(wethAddress[network.name]);
  //await deployDaiToken("")
  await deployMarsToken("")
  await deployGovToken("")
  await deployGovernance("")
  await deployFactory("")
  await deploySettlement("")

  //await governance.setSettlement(settlement.address)
  //await predictionMarket.connect(owner).setSettlement(settlement.address)
  //await governance.connect(owner).setFactory(predictionMarketFactory.address)
  
  await populateMarkets()

  try {
    fs.writeFileSync("contract-addresses.json", JSON.stringify(ADDR, null, "\t"))
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
