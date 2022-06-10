/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('dotenv').config();
require('@nomiclabs/hardhat-waffle');
require('hardhat-gas-reporter');
require('hardhat-abi-exporter');
require('hardhat-contract-sizer');
require('@nomiclabs/hardhat-etherscan');

module.exports = {
  solidity: {
    version: '0.8.4',
    settings: {
      optimizer: {
        enabled: true,
        runs: 1500,
      },
    },
  },
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {},
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 50, // GWEI
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: false,
    pretty: false,
  },
  etherscan: {
    apiKey: '',
  },
  mocha: {
    timeout: 60 * 60 * 1000,
  },
};
