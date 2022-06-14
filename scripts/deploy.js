const { ethers } = require('hardhat');

async function main() {
  const [ deployer ] = await ethers.getSigners();

/*  const WRLDNameServiceRegistryFactory = await ethers.getContractFactory('WRLD_Name_Service_Registry');
  const WRLDNameServiceRegistrarFactory = await ethers.getContractFactory('WRLD_Name_Service_Registrar');
  const WRLDNameServiceResolverFactory = await ethers.getContractFactory('WRLD_NameService_Resolver_V1');
  const WRLDTokenFactory = await ethers.getContractFactory('WRLD_Token_Ethereum');
  const WhitelistFactory = await ethers.getContractFactory('NFTW_Whitelist');*/
  const NameMetadataFactory = await ethers.getContractFactory('WRLD_Name_Service_Metadata');

/*  const wrldContract = await WRLDTokenFactory.connect(deployer).deploy();
  const whitelistContract = await WhitelistFactory.connect(deployer).deploy();
  const registryContract = await WRLDNameServiceRegistryFactory.connect(deployer).deploy();
  const registrarContract = await WRLDNameServiceRegistrarFactory.connect(deployer).deploy(registryContract.address, wrldContract.address, whitelistContract.address);
  const resolverContract = await WRLDNameServiceResolverFactory.connect(deployer).deploy(registryContract.address);*/
  const metadataContract = await NameMetadataFactory.deploy();

/*  console.log('wrld contract', wrldContract.address);
  console.log('whitelist contract', whitelistContract.address);
  console.log('registry contract', registryContract.address);
  console.log('registrar contract', registrarContract.address);
  console.log('resolver contract', resolverContract.address);*/
  console.log('metadata contract', metadataContract.address);

//  await registryContract.connect(deployer).setResolverContract(resolverContract.address);
//  await registryContract.connect(deployer).setApprovedRegistrar(registrarContract.address, true);
//  await registryContract.connect(deployer).setMetadataContract(metadataContract.address);
//  await whitelistContract.connect(deployer).grantRole('0x6a9720191e216fcceabcf977981e1960eca316ba25983a901c27600afc53f108', registrarContract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit();
  });


/*

deployer: 0x505cdA4e0911DB1e47218dCac21ba21d9324ed84

RINKEBY

wrld contract 0xb236cD0a85642F3A450331f7a4531C0f15AddEED
whitelist contract 0xDb77A3c6742A05EF66e137f5418aEdD5546e9c85
registry contract 0xf7F56B33EBc40BA7a11D40Ef7412c54767DC4DC6
registrar contract 0xF65df573AC8e7D5F9B5C058762be78809Cf9745c
resolver contract 0xBa49fAF92D59dC61762e96411455540569e71C03
metadata contract 0x8A4dee62F62Fa25a50a0E53F4618120d23cf9215

npx hardhat verify --network rinkeby
*/
