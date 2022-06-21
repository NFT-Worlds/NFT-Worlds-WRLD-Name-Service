const { expect } = require('chai');
const { ethers } = require('hardhat');

const YEAR_SECONDS = 31557600; // 365.25

describe('World Name Service Contract', () => {
  let owner;
  let otherAddresses;
  let registryContract;
  let registrarContract;
  let resolverContract;
  let wrldContract;
  let wnsPassesContract;
  let mockBridgeContract;

  beforeEach(async () => {
    [ owner, ...otherAddresses ] = await ethers.getSigners();

    const WRLDNameServiceRegistryFactory = await ethers.getContractFactory('WRLD_Name_Service_Registry');
    const WRLDNameServiceRegistrarFactory = await ethers.getContractFactory('WRLD_Name_Service_Registrar');
    const WRLDNameServiceResolverFactory = await ethers.getContractFactory('WRLD_NameService_Resolver_V1');
    const WRLDTokenFactory = await ethers.getContractFactory('WRLD_Token_Ethereum');
    const WNSPassesFactory = await ethers.getContractFactory('WNS_Passes');
    const MockBridgeFactory = await ethers.getContractFactory('Mock_Bridge');

    wrldContract = await WRLDTokenFactory.deploy();
    wnsPassesContract = await WNSPassesFactory.deploy();
    registryContract = await WRLDNameServiceRegistryFactory.deploy();
    registrarContract = await WRLDNameServiceRegistrarFactory.deploy(registryContract.address, wrldContract.address, wnsPassesContract.address);
    resolverContract = await WRLDNameServiceResolverFactory.deploy(registryContract.address);
    mockBridgeContract = await MockBridgeFactory.deploy();

    await registryContract.setResolverContract(resolverContract.address);
    await registryContract.setApprovedRegistrar(registrarContract.address, true);
    await registryContract.setBridgeContract(mockBridgeContract.address);
    await wnsPassesContract.grantRole('0x6a9720191e216fcceabcf977981e1960eca316ba25983a901c27600afc53f108', registrarContract.address);
  });

  describe('Deployment', () => {
    it('properly initializes contract', async () => {
      await wrldContract.deployed();
      await registryContract.deployed();
      await registrarContract.deployed();

      expect(await wrldContract.owner()).to.equal(owner.address);
      expect(await registryContract.owner()).to.equal(owner.address);
      expect(await registrarContract.owner()).to.equal(owner.address);
    });
  });

  describe('Registration', () => {
    it('Registers a WRLD name', async () => {
      const registerer = otherAddresses[0];

      await registrarContract.enableRegistration();

      await mintWRLDToAddressAndAllow(registerer, 5000);

      await registrarContract.connect(registerer).register([ 'arkdev' ], [ 1 ]);

      const name = await registryContract.getName('arKdev');

      expect(name.name).to.equal('arkdev');
      expect(name.controller).to.equal(registerer.address);
    });

    it('Registers WRLD names for free using pass or as owner', async () => {
      await wnsPassesContract.mint(2, 5);

      // register as owner, allowing 2 char name
      await registrarContract.registerWithPass([ 'tv' ]);

      // register with pass
      const registerer = otherAddresses[0];
      await expect(registrarContract.connect(registerer).registerWithPass([ 'eth1' ], [ 1 ])).to.be.reverted;

      await wnsPassesContract.safeTransferFrom(owner.address, registerer.address, 2, 2, 0);
      await expect(registrarContract.connect(registerer).registerWithPass([ 't' ])).to.be.reverted; // should not allow 1 or 2 char
      await registrarContract.connect(registerer).registerWithPass([ 'eth1', 'testtt' ]);
    });

    it('Registers multiple WRLD names', async () => {
      const registerer = otherAddresses[0];

      await registrarContract.enableRegistration();

      await mintWRLDToAddressAndAllow(registerer, 500000);

      const names = [ 'aRktech', 'arktechS', 'wrldMind', 'devtest', 'Yoloman' ];
      const years = [ 10, 10, 10, 15, 10 ];

      await registrarContract.connect(registerer).register(names, years);

      for (let i = 0; i < names.length; i++) {
        const wrldName = await registryContract.getName(names[i]);
        const nameTokenId = await registryContract.getNameTokenId(names[i]);
        expect(wrldName.name).to.equal(names[i].toLowerCase());
        expect(await registryContract.getNameExpiration(wrldName.name)).to.equal(wrldName.expiresAt);
        expect(await registryContract.getTokenName(nameTokenId)).to.equal(wrldName.name);
      }
    });

    it('Registers WRLD name and extends registration', async () => {
      const registerer = otherAddresses[0];

      await registrarContract.enableRegistration();

      await mintWRLDToAddressAndAllow(registerer, 5000);

      await registrarContract.connect(registerer).register([ 'arkdev' ], [ 1 ]);
      const initialExpiration = await registryContract.getNameExpiration('arkdev');
      await registrarContract.connect(registerer).extendRegistration([ 'arkdev' ], [ 5 ]);
      expect((await registryContract.getNameExpiration('arkdeV') * 1)).to.equal((initialExpiration * 1) + (YEAR_SECONDS * 5));
    });

    it('Registers WRLD name and checks case sensitivities', async () => {
      const registerer = otherAddresses[0];

      await registrarContract.enableRegistration();

      await mintWRLDToAddressAndAllow(registerer, 5000);

      await registrarContract.connect(registerer).register([ 'arkdev' ], [ 1 ]);
      await expect(registrarContract.connect(registerer).register([ 'ArkDev' ], [ 1 ])).to.be.reverted;
      await expect(registrarContract.connect(registerer).register([ 'arkDEV' ], [ 1 ])).to.be.reverted;
    });

    it('Registers WRLD name and allows a new registrant if expiration time has passed', async () => {
      const registererOne = otherAddresses[0];
      const registererTwo = otherAddresses[1];

      await registrarContract.enableRegistration();

      await mintWRLDToAddressAndAllow(registererOne, 50000);
      await mintWRLDToAddressAndAllow(registererTwo, 50000);

      await registrarContract.connect(registererOne).register([ 'Arkdev' ], [ 2 ]);
      await expect(registrarContract.connect(registererTwo).register([ 'arKdev' ], [ 3 ])).to.be.reverted;

      const tokenId = await registryContract.getNameTokenId('arkdEv') * 1;

      await ethers.provider.send('evm_mine', [ Date.now() / 1000 + (YEAR_SECONDS * 2) + 600 ]);

      await registrarContract.connect(registererTwo).register([ 'arkdeV', 'neWark' ], [ 3, 1 ]);
      await expect(registrarContract.connect(registererOne).register([ 'arkdev', 'testing' ], [ 3 ])).to.be.reverted;

      expect(await registryContract.getNameTokenId('arkdev') * 1).to.equal(tokenId);

      console.log(await registryContract.getName('arkdev'));
    });

    it('Registers WRLD name using emojis', async () => {
      const registerer = otherAddresses[0];

      await registrarContract.enableRegistration();

      await mintWRLDToAddressAndAllow(registerer, 5000);

      await registrarContract.connect(registerer).register([ '🔥🚀🌕🌕' ], [ 2 ]);

      const name = await registryContract.getName('🔥🚀🌕🌕');

      expect(name.name).to.equal('🔥🚀🌕🌕');
      expect(name.controller).to.equal(registerer.address);
    });

    it('Fails to register with pass when no passes owned', async () => {
      const registerer = otherAddresses[0];

      await expect(registrarContract.connect(registerer).registerWithPass([ 'testing' ])).to.be.reverted;
    });

    it('Fails to register when registration is not enabled', async () => {
      await mintWRLDToAddressAndAllow(owner, 5000);

      await expect(registrarContract.register([ 'arkdev' ], [ 1 ])).to.be.reverted;
    });

    it('Fails to register 1 or 2 character name if now enabled', async () => {
      const registerer = otherAddresses[0];

      await registrarContract.enableRegistration();
      await mintWRLDToAddressAndAllow(registerer, 50000);

      await expect(registrarContract.connect(registerer).register([ 'a' ], [ 1 ])).to.be.reverted;
      await expect(registrarContract.connect(registerer).register([ 'aa' ], [ 1 ])).to.be.reverted;
      await registrarContract.connect(registerer).register([ 'aaa' ], [ 1 ]);
    });


    it('Fails to register an existing, unexpired name', async () => {
      const registererOne = otherAddresses[0];
      const registererTwo = otherAddresses[1];

      await registrarContract.enableRegistration();

      await mintWRLDToAddressAndAllow(registererOne, 50000);
      await mintWRLDToAddressAndAllow(registererTwo, 50000);

      await registrarContract.connect(registererOne).register([ 'arkdev' ], [ 2 ]);
      await expect(registrarContract.connect(registererTwo).register([ 'arkdev' ], [ 3 ])).to.be.reverted;
    });

    it('Fails to register directly through the registry', async () => {
      await expect(registryContract.register(owner.address, [ 'testing' ], [ 123 ])).to.be.reverted;
    });

    it('Fails to extend registration directly through the registry', async () => {
      const registerer = otherAddresses[0];

      await registrarContract.enableRegistration();
      await mintWRLDToAddressAndAllow(registerer, 50000);

      await registrarContract.connect(registerer).register([ 'aaa' ], [ 1 ]);

      await expect(registryContract.extendRegistration([ 'aaa' ], [ 2 ])).to.be.reverted;
    });
  });

  describe('Name Management', () => {
    it('Creates wrld name, sets and retrieves record types', async () => {
      const registerer = otherAddresses[0];
      const controller = otherAddresses[1];
      const otherAddress = otherAddresses[2];

      await registrarContract.enableRegistration();

      await mintWRLDToAddressAndAllow(registerer, 5000);
      await registrarContract.connect(registerer).register([ 'arkdev' ], [ 10 ]);

      expect(await registryContract.getNameOwner('arkdev')).to.equal(registerer.address);

      await registryContract.connect(registerer).setController('arkdev', controller.address);
      expect(await registryContract.getNameController('arkdev')).to.equal(controller.address);

      await registryContract.connect(controller).setAddressRecord('arkDev', 'test', otherAddress.address, 3600);
      const addressRecord = await registryContract.getNameAddressRecord('aRkdev', 'test');
      const defaultAddressRecord = await registryContract.getNameAddressRecord('arkdeV', 'evm_default');
      const addressRecords = await registryContract.getNameAddressRecordsList('arkdEv');

      expect(addressRecord.value).to.equal(otherAddress.address);
      expect(addressRecord.ttl).to.equal(3600);
      expect(defaultAddressRecord.value).to.equal(registerer.address);
      expect(addressRecords[0]).to.equal('evm_default');
      expect(addressRecords[1]).to.equal('test');

      await registryContract.connect(registerer).setStringRecord('aRkdev', 'test1', 'something', 'A', 3600);
      const stringRecord = await registryContract.getNameStringRecord('arkdeV', 'test1');
      const stringRecords = await registryContract.getNameStringRecordsList('Arkdev');
      expect(stringRecord.value).to.equal('something');
      expect(stringRecord.typeOf).to.equal('A');
      expect(stringRecord.ttl).to.equal(3600);
      expect(stringRecords[0]).to.equal('test1');

      await registryContract.connect(controller).setUintRecord('arKdev', 'test2', 1234, 3600);
      const uintRecord = await registryContract.getNameUintRecord('arkdEv', 'test2');
      const uintRecords = await registryContract.getNameUintRecordsList('Arkdev');
      expect(uintRecord.value).to.equal(1234);
      expect(uintRecord.ttl).to.equal(3600);
      expect(uintRecords[0]).to.equal('test2');

      await registryContract.connect(controller).setIntRecord('arkdeV', 'test3', -1234, 3600);
      const intRecord = await registryContract.getNameIntRecord('aRKdev', 'test3');
      const intRecords = await registryContract.getNameIntRecordsList('ARkdev');
      expect(intRecord.value).to.equal(-1234);
      expect(intRecord.ttl).to.equal(3600);
      expect(intRecords[0]).to.equal('test3');

      await expect(registryContract.connect(otherAddress).setAddressRecord('arkdEV', 'test', otherAddress.address, 3600)).to.be.reverted;
      await expect(registryContract.connect(otherAddress).setStringRecord('arKDev', 'test1', 'new', 'A', 3600)).to.be.reverted;
      await expect(registryContract.connect(otherAddress).setUintRecord('aRKdev', 'test2', 4567, 3600)).to.be.reverted;
      await expect(registryContract.connect(otherAddress).setIntRecord('ARkdev', 'test3', -4567, 3600)).to.be.reverted;
    });

    it('Migrates name using bridge', async () => {
      const registerer = otherAddresses[0];

      await registrarContract.enableRegistration();

      await mintWRLDToAddressAndAllow(registerer, 5000);

      await registrarContract.connect(registerer).register([ 'arkdev' ], [ 1 ]);
      await registryContract.connect(registerer).migrate('arkdev', 0);
    });
  });

  describe('Name entries', () => {
    it('Sets and retrieves name entries', async () => {
      const registerer = otherAddresses[0];
      const entrySetter = otherAddresses[1];

      await registrarContract.enableRegistration();

      await mintWRLDToAddressAndAllow(registerer, 5000);
      await registrarContract.connect(registerer).register([ 'arkdev' ], [ 10 ]);

      await registryContract.connect(entrySetter).setStringEntry('arKDev', 'class', 'dwarf');
      expect(await registryContract.getStringEntry(entrySetter.address, 'Arkdev', 'class')).to.equal('dwarf');
      expect(await registryContract.getStringEntry(entrySetter.address, 'random', 'class')).to.equal(''); // never set

      await registryContract.connect(entrySetter).setAddressEntry('arkdeV', 'manager', otherAddresses[3].address);
      expect(await registryContract.getAddressEntry(entrySetter.address, 'aRkdev', 'manager')).to.equal(otherAddresses[3].address);
      expect(await registryContract.getAddressEntry(entrySetter.address, 'random', 'manager')).to.equal('0x0000000000000000000000000000000000000000'); // never set

      await registryContract.connect(entrySetter).setUintEntry('arkdEV', 'level', 124);
      expect(await registryContract.getUintEntry(entrySetter.address, 'ARkdev', 'level')).to.equal(124);
      expect(await registryContract.getUintEntry(entrySetter.address, 'random', 'level')).to.equal(0); // never set

      await registryContract.connect(entrySetter).setIntEntry('arkdev', 'damage', -100);
      expect(await registryContract.getIntEntry(entrySetter.address, 'arKDev', 'damage')).to.equal(-100);
      expect(await registryContract.getIntEntry(entrySetter.address, 'random', 'damage')).to.equal(0); // never set
    });
  });

  describe('Owner Functions', () => {
    it('Set the annual registration wrld price', async () => {
      const newPrice = ethers.BigNumber.from(BigInt(10 * 1e18));
      const newPrices = [
        newPrice, // 1 char
        newPrice, // 2 char
        newPrice, // 3 char
        newPrice, // 4 char
        newPrice, // 5+ char
      ];

      await registrarContract.setAnnualWrldPrices(newPrices);

      for (let i = 0; i < newPrices.length; i++) {
        expect(await registrarContract.annualWrldPrices(i)).to.equal(newPrices[i]);
      }
    });
  });

  describe('Withdraw', () => {
    it('Allows owner to withdraw', async () => {
      const registerer = otherAddresses[0];

      await registrarContract.enableRegistration();
      await mintWRLDToAddressAndAllow(registerer, 5000);
      await registrarContract.connect(registerer).register([ 'arkdev' ], [ 8 ]);

      expect(await wrldContract.balanceOf(owner.address) * 1).to.equal(0);
      await registrarContract.withdrawWrld(owner.address);
      expect(await wrldContract.balanceOf(owner.address) / 1e18).to.equal(4000);
    });

    it('Allows approved withdrawer to withdraw', async () => {
      const registerer = otherAddresses[0];
      const withdrawer = otherAddresses[1];

      await registrarContract.enableRegistration();
      await mintWRLDToAddressAndAllow(registerer, 5000);
      await registrarContract.connect(registerer).register([ 'arkdev' ], [ 8 ]);

      await expect(registrarContract.connect(withdrawer).withdrawWrld(withdrawer.address)).to.be.reverted;
      await registrarContract.setApprovedWithdrawer(withdrawer.address);

      expect(await wrldContract.balanceOf(owner.address) * 1).to.equal(0);
      await registrarContract.connect(withdrawer).withdrawWrld(withdrawer.address);
      expect(await wrldContract.balanceOf(withdrawer.address) / 1e18).to.equal(4000);
    });

    it('Fails to withdraw if not owner or approved', async () => {
      const withdrawer = otherAddresses[0];

      await expect(registrarContract.connect(withdrawer).withdrawWrld(withdrawer.address)).to.be.reverted;
    });
  });

  describe('Metadata', () => {
    it('Sets metadata contract and returns expected data', async () => {
      const registerer = otherAddresses[0];

      const NameMetadataFactory = await ethers.getContractFactory('WRLD_Name_Service_Metadata');
      const metadata = await NameMetadataFactory.deploy();

      await registrarContract.enableRegistration();
      await mintWRLDToAddressAndAllow(registerer, 5000);
      await registrarContract.connect(registerer).register([ 'arkdev' ], [ 8 ]);
      await registryContract.setMetadataContract(metadata.address);
      const tokenId = await registryContract.getNameTokenId('arkDev');
      expect((await registryContract.tokenURI(tokenId)).includes('base64')).to.equal(true);
    });
  });

  /**
   * Helpers
   */

  async function mintWRLDToAddressAndAllow(toWallet, amount) {
    const bigNumberAmount = ethers.BigNumber.from(amount).mul(BigInt(1e18));

    await wrldContract.mint(toWallet.address, bigNumberAmount);
    await wrldContract.connect(toWallet).approve(registrarContract.address, bigNumberAmount);
  }
});
