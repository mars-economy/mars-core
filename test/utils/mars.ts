import { ethers } from "hardhat"
import { Contract, Signer } from "ethers"
import { MarsPredictionMarketFactory, TestERC20, MarsPredictionMarket__factory, MarsPredictionMarket } from "../../typechain"
import { bytes32, timeoutAppended, tokens } from "./utils"

type Ethers = typeof ethers

export interface Mars {
  marsToken: TestERC20
  predictionMarketFactory: MarsPredictionMarketFactory
  predictionMarket: MarsPredictionMarket
}

export const deployMars = async (ethers: Ethers, owner: Signer): Promise<Mars> => {
  const ownerAddress = await owner.getAddress()
  let timeEnd: number
  const YES = ethers.utils.arrayify("0xc53ef995914f4b409b22e6128c2bcf17")
  const NO = ethers.utils.arrayify("0xc2c2c6cb226b42c4b36bf4b4dcb6ba17")
  const MILESTONE = ethers.utils.arrayify("0x13a12ea1f1cb4b6e96a3fbdfcf8c9814")

  const marsToken = (await (await ethers.getContractFactory("TestERC20"))
    .connect(owner)
    .deploy(tokens(1000000), "Test Token", 18, "TST")) as TestERC20
  timeEnd = await timeoutAppended(ethers.provider, 60 * 60 * 24 * 2)

  const predictionMarketFactory = (await (await ethers.getContractFactory("MarsPredictionMarketFactory"))
    .connect(owner)
    .deploy()) as MarsPredictionMarketFactory

  predictionMarketFactory.connect(owner).initialize(await owner.getAddress(), await owner.getAddress())

  let tx = await predictionMarketFactory
    .connect(owner)
    .createMarket(
      MILESTONE,
      1,
      "Example",
      "Example",
      marsToken.address,
      timeEnd,
      timeEnd,
      [{ uuid: YES, name: "YES", position: 1 }],
      tokens(1),
      tokens(10)
    )

  let rx = await tx.wait()
  let _newMarket = rx.events![3].args!.contractAddress

  const predictionMarket = MarsPredictionMarket__factory.connect(_newMarket, owner)

  //not needed for now
  // await registerAddresses(addressResolver, {
  //   $MARS: marsToken,
  // })

  return {
    marsToken,
    predictionMarketFactory,
    predictionMarket,
  }
}
