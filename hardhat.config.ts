import { HardhatUserConfig } from "hardhat/types"
import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-waffle"
import { privateKey, marsKey } from "./wallet"

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.2",
    settings: {
      optimizer: { enabled: true, runs: 2000 },
    },
  },
  networks: {
    bsctestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: [privateKey],
      chainId: 97,
      gasPrice: 20000000000,
    },
    bscmainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
    },
  },
  etherscan: {
    apiKey: marsKey,
  },
}

export default config
