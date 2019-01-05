module.exports = {
  networks: {
    dev: {
      privateKey: '3d976ac3d0808beff1fe645c1488ef87266830aee8bad2a7c86654dd430d97cb',
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
      userFeePercentage: 30,
      fee_limit: 1000000000,
      originEnergyLimit: 1e7,
      fullNode: "https://api.trongrid.io",
      solidityNode: "https://api.trongrid.io",
      eventServer: "https://api.trongrid.io",
      network_id: "*"
    }
  }
};
