const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    'ThunderCore': {
      provider() {
        return new HDWalletProvider(process.env.MNEMONIC, 'https://mainnet-rpc.thundercore.com')
      },
      network_id: '108',
    },
  },
  compilers: {
    solc: {
      version: "0.5.17",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: "byzantium",
      },
    },
  },
};

