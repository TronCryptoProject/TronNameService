module.exports = {
  networks: {
    dev: {
      privateKey: 'eab993c043dd38594804a9e060188e6e4391117198f1cdebb66bea6fbd5ad2d2',
      userFeePercentage: 100,
      feeLimit: 1e9,
      originEnergyLimit: 1e5,
      fullNode: "http://127.0.0.1:8090",
      solidityNode: "http://127.0.0.1:8091",
      eventServer: "http://127.0.0.1:8092",
      network_id: "*" // Match any network id
    },
    shasta: {
      privateKey: 'c77858d9ca71e3921baf4e5d10689dadef1d8a2c00ce7f8e4487a104408a8094',
      userFeePercentage: 100,
      originEnergyLimit: 1e7,
      feeLimit: 1e9,
      callValue: 0,
      fullNode: "https://api.shasta.trongrid.io",
      solidityNode: "https://api.shasta.trongrid.io",
      eventServer: "https://api.shasta.trongrid.io",
      network_id: "*" // Match any network id
    },
    mainnet: {
      privateKey: process.env.PK,
      userFeePercentage: 100,
      feeFimit: 1e9,
      originEnergyLimit: 1e7,
      fullNode: "https://api.trongrid.io",
      solidityNode: "https://api.trongrid.io",
      eventServer: "https://api.trongrid.io",
      network_id: "*"
    }
  }
};
