# Mars Core
Mars contracts  

> NB! Please run `yarn format` before committing changes
> NB! Need to create an account on https://testnet-explorer.binance.org
and create wallet.ts file containing (for example):

export const privateKey = '0000000000000000000000000000000000000000000000000000000000000000'
export const marsKey = '0000000000000000000000000000000000'

## Prerequisites

``` sh
npm install --global yarn
```

## Insallation

``` sh
yarn install
```

## Building project

``` sh
yarn build
```

## Running tests

``` sh
yarn test
```

## Deploy contracts
``` sh
yarn deploy
```


## Verify each contract individually 

``` sh
npx hardhat verify --network bsctestnet DEPLOYED_CONTRACT_ADDRESS "Constructor argument 1" "Constructor argument 2" "Constructor argument 3"
```

