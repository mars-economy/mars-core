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

	const events = await getPredictionMarketCreatedEvents(predictionMarketFactory, tx.blockNumber)
	const marketAddress = events[0].args.contractAddress
	console.log("Created market " + marketAddress) 
			
	for(var i = 0; i < outcomes.length; i++) {
		await (await predictionMarketFactory.connect(me).addOutcome(marketAddress, ethers.utils.arrayify(outcomes[i][0]), 
			i + 1, outcomes[i][1])).wait()
	}
}

async function main() {
	
  //ADDR["marsToken"] = '0x9a1Ab8dfa80A4f86BaCf829Dd28bc94CD60863Aa'	
  //ADDR["govToken"] = '0x3bBBB30f880cDC6a611411c00df05024504c306d'	
  //ADDR["governance"] = '0x027AF35e1617Be2eCEfB02057EB93Abc9467A615'	
  //ADDR["predictionMarketFactory"] = '0x7Cf1e5cDB2336EaDECB3e499D31a0a66Dd247fd7'	
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
  
  await createCategory('0xb00b5428da0349e48763781ed54d7579', 1, 'CROSSING THE FRONTIER', '')
  await createMilestone('0x13a12ea1f1cb4b6e96a3fbdfcf8c9814', '0xb00b5428da0349e48763781ed54d7579', 1, 'First succes of Spaceship Orbital Flight', '')
  
  const outcomes = Array(Array('0xc53ef995914f4b409b22e6128c2bcf17', 'Yes'), Array('0xc2c2c6cb226b42c4b36bf4b4dcb6ba17', 'No'))
  await createMarket(
	'0x13a12ea1f1cb4b6e96a3fbdfcf8c9814', 
	1, 
	'By 2022', 
	'',
	'0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee',
	1640984400,
	outcomes
	)

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
