var TNSTag = artifacts.require("./TNSTag.sol");
var TNSOwnerReverse = artifacts.require("./TNSOwnerReverse.sol");
var TNS = artifacts.require("./TNS.sol");

async function syncDeploy(deployer){
    await deployer.deploy(TNSOwnerReverse);
    await deployer.deploy(TNSTag).then();
    await deployer.link(TNSTag, TNS);
    await deployer.deploy(TNS);
}

module.exports = function(deployer){
	deployer.then(async ()=>{
		await syncDeploy(deployer);
	});
}