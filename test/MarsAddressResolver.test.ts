import { ethers } from "hardhat"
import { expect } from "chai"
import { Signer } from "ethers"
import { deployMars, Mars } from "./utils/mars"
import { bytes32 } from "./utils/utils"

describe("Address Resolver", async () => {
  let owner: Signer
  let user: Signer
  let mars: Mars

  before(async () => {
    ;[owner, user] = await ethers.getSigners()
  })

  beforeEach(async () => {
    mars = await deployMars(ethers, owner)
  })

  specify("Test environment", async () => {
    expect(mars.addressResolver.address).to.be.properAddress
  })

  it("Should throw error resolving unknown address", async () => {
    const name = bytes32("AddressResolver")
    const errorMessage = `${name} is undefined`

    await expect(mars.addressResolver.requireAddress(name, errorMessage)).to.be.revertedWith(errorMessage)
  })

  it("Should register contract", async () => {
    const name = bytes32("AddressResolver")
    const address = await owner.getAddress()

    const tx = mars.addressResolver.registerAddress(name, address)
    await expect(tx).to.emit(mars.addressResolver, "ContractRegistered").withArgs(name, address)
    expect(await mars.addressResolver.getAddress(name)).to.be.equal(address)
  })

  it("Should revert contract registration for non-owner", async () => {
    const name = bytes32("AddressResolver")
    const address = await owner.getAddress()

    const tx = mars.addressResolver.connect(user).registerAddress(name, address)
    await expect(tx).to.be.revertedWith("MARS: Only the contract owner may perform this action")
  })

  it("Should reassign contract owner", async () => {
    const ownerAddress = await owner.getAddress()
    const newOwnerAddress = await user.getAddress()

    expect(await mars.addressResolver.owner()).to.equal(ownerAddress)
    const nominateTx = mars.addressResolver.nominateNewOwner(newOwnerAddress)
    await expect(nominateTx).to.emit(mars.addressResolver, "OwnerNominated").withArgs(newOwnerAddress)

    const acceptTx = mars.addressResolver.connect(user).acceptOwnership()
    await expect(acceptTx).to.emit(mars.addressResolver, "OwnerChanged").withArgs(ownerAddress, newOwnerAddress)
    expect(await mars.addressResolver.owner()).to.equal(newOwnerAddress)
  })
})
