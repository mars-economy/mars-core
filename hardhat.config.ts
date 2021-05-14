import { HardhatUserConfig } from "hardhat/types"
import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-waffle"
import "@openzeppelin/hardhat-upgrades"

import { privateKey, marsKey } from "./wallet"

import "solidity-coverage"

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.2",
        settings: {
          optimizer: { enabled: true, runs: 2000 },
        },
      }
    ]


  },
  networks: {
    bsctestnet: {
      // url: "http://mainnet.node.metal.liquifi.org:8575/",
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: [privateKey],
      chainId: 97,
      gasPrice: 20000000000,
    },
    bscmainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 5000000000,
    },
  },
  etherscan: {
    apiKey: marsKey,
  },
}

export default config
