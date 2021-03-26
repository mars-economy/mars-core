import { BigNumber, utils } from "ethers"

export const bytes32 = (value: string) => utils.formatBytes32String(value)
export const tokens = (value: number, decimals = 18) => BigNumber.from(value).mul(BigNumber.from(10).pow(decimals))
export const timeout = (days: number) => Math.floor((new Date().getTime() + days * 24 * 60 * 60 * 1000) / 1000)

export const wait = async (ethers: any, seconds: number) => {
  await ethers.provider.send("evm_increaseTime", [seconds - 1])
  await ethers.provider.send("evm_mine", []) // mine the next block
}
