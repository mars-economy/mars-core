import { ethers } from "hardhat"
import { Contract, Signer } from "ethers"
import { MarsAddressResolver, MarsPredictionMarketFactory, MarsToken } from "../../typechain"
import { bytes32 } from "./utils"

type Ethers = typeof ethers

export interface Mars {
  addressResolver: MarsAddressResolver
  marsToken: MarsToken
  predictionMarketFactory: MarsPredictionMarketFactory
}

export const deployMars = async (ethers: Ethers, owner: Signer): Promise<Mars> => {
  const ownerAddress = await owner.getAddress()

  const addressResolver = (await (await ethers.getContractFactory("MarsAddressResolver"))
    .connect(owner)
    .deploy(ownerAddress)) as MarsAddressResolver

  const marsToken = (await (await ethers.getContractFactory("MarsToken")).connect(owner).deploy()) as MarsToken

  const predictionMarketFactory = (await (await ethers.getContractFactory("MarsPredictionMarketFactory"))
    .connect(owner)
    .deploy(addressResolver.address)) as MarsPredictionMarketFactory

  await registerAddresses(addressResolver, {
    $MARS: marsToken,
  })

  return {
    addressResolver,
    marsToken,
    predictionMarketFactory,
  }
}

const registerAddresses = async (addressResolver: MarsAddressResolver, contracts: Record<string, Contract>): Promise<void> => {
  for (const name in contracts) {
    await addressResolver.registerAddress(bytes32(name), contracts[name].address)
  }
}
