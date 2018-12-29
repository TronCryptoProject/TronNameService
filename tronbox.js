module.exports = {
  networks: {
    dev: {
      privateKey: '62500bea266e935f8521ca0dee5f2650332957b29454553ee7bb15c254ac3904',
      userFeePercentage: 30,
      feeLimit: 1000000000,
      originEnergyLimit: 1e5,
      callValue: 0,
      fullNode: "http://127.0.0.1:8090",
      solidityNode: "http://127.0.0.1:8091",
      eventServer: "http://127.0.0.1:8092",
      network_id: "*" // Match any network id
    },
    shasta: {
      privateKey: 'da146374a75310b9666e834ee4ad0866d6f4035967bfc76217c5a495fff9f0d0',
      userFeePercentage: 30,
      feeLimit: 1000000000,
      fullNode: "https://api.shasta.trongrid.io",
      solidityNode: "https://api.shasta.trongrid.io",
      eventServer: "https://api.shasta.trongrid.io",
      network_id: "*" // Match any network id
    },
    mainnet: {
      privateKey: process.env.PK,
      consume_user_resource_percent: 30,
      fee_limit: 1000000000,
      fullNode: "https://api.trongrid.io",
      solidityNode: "https://api.trongrid.io",
      eventServer: "https://api.trongrid.io",
      network_id: "*"
    }
  }
};
