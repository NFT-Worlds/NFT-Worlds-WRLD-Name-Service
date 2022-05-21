const { expect } = require('chai');
const { ethers, waffle } = require('hardhat');

const ANNUAL_WRLD_PRICE = 500;
const YEAR_SECONDS = 31536000;

describe('World Name Service Contract', () => {
  let owner;
  let otherAddresses;
  let wnsContract;
  let wrldContract;

  beforeEach(async () => {
    [ owner, ...otherAddresses ] = await ethers.getSigners();

    const WRLDNameServiceFactory = await ethers.getContractFactory('WRLD_Name_Service');
    const WRLDTokenFactory = await ethers.getContractFactory('WRLD_Token_Ethereum');

    wrldContract = await WRLDTokenFactory.deploy();
    wnsContract = await WRLDNameServiceFactory.deploy(wrldContract.address);
  });

  describe('Deployment', () => {
    it('properly initializes contract', async () => {
      await wrldContract.deployed();
      await wnsContract.deployed();

      expect(await wrldContract.owner()).to.equal(owner.address);
      expect(await wnsContract.owner()).to.equal(owner.address);
    });
  });

  describe('Registration', () => {
    it('Registers a WRLD name', async () => {
      const registerer = otherAddresses[0];

      await mintWRLDToAddressAndAllow(registerer, 5000);

      await wnsContract.connect(registerer).register([ 'arkdev' ], [ 1 ]);

      const name = await wnsContract.getName('arkdev');

      expect(name.name).to.equal('arkdev');
      expect(name.controller).to.equal(registerer.address);
    });

    it('Registers multiple WRLD names', async () => {
      const registerer = otherAddresses[0];

      await mintWRLDToAddressAndAllow(registerer, 500000);

      const names = [ 'arktech', 'ark', 'wrld', 'dev', 'yolo' ];
      const years = [ 10, 10, 10, 15, 10 ];

      await wnsContract.connect(registerer).register(names, years);

      for (let i = 0; i < names.length; i++) {
        const wrldName = await wnsContract.getName(names[i]);
        expect(wrldName.name).to.equal(names[i]);
        expect(await wnsContract.getNameExpiration(wrldName.name)).to.equal(wrldName.expiresAt);
        expect(await wnsContract.getTokenName(i + 1)).to.equal(wrldName.name);
        expect(await wnsContract.nameTokenId(wrldName.name)).to.equal(i + 1);
      }
    });

    it('Registers WRLD name and extends registration', async () => {
      const registerer = otherAddresses[0];

      await mintWRLDToAddressAndAllow(registerer, 5000);

      await wnsContract.connect(registerer).register([ 'arkdev' ], [ 1 ]);
      const initialExpiration = await wnsContract.getNameExpiration('arkdev');
      await wnsContract.connect(registerer).extendRegistration([ 'arkdev' ], [ 5 ]);
      expect((await wnsContract.getNameExpiration('arkdev') * 1)).to.equal((initialExpiration * 1) + (YEAR_SECONDS * 5));
    });

    it('Registers WRLD name and allows a new registrant if expiration time has passed', async () => {
      const registererOne = otherAddresses[0];
      const registererTwo = otherAddresses[1];

      await mintWRLDToAddressAndAllow(registererOne, 50000);
      await mintWRLDToAddressAndAllow(registererTwo, 50000);

      await wnsContract.connect(registererOne).register([ 'arkdev' ], [ 2 ]);
      await expect(wnsContract.connect(registererTwo).register([ 'arkdev' ], [ 3 ])).to.be.reverted;

      const tokenId = await wnsContract.nameTokenId('arkdev') * 1;

      await ethers.provider.send('evm_mine', [ Date.now() / 1000 + (YEAR_SECONDS * 2) + 600 ]);

      await wnsContract.connect(registererTwo).register([ 'arkdev', 'newark' ], [ 3, 1 ]);
      await expect(wnsContract.connect(registererOne).register([ 'arkdev', 'testing' ], [ 3 ])).to.be.reverted;

      expect(await wnsContract.nameTokenId('arkdev') * 1).to.equal(tokenId);
    });

    it('Registers WRLD name using emojis', async () => {
      const registerer = otherAddresses[0];

      await mintWRLDToAddressAndAllow(registerer, 5000);

      await wnsContract.connect(registerer).register([ '🔥🚀🌕' ], [ 1 ]);

      const name = await wnsContract.getName('🔥🚀🌕');

      expect(name.name).to.equal('🔥🚀🌕');
      expect(name.controller).to.equal(registerer.address);
    });

    it('Fails to register an existing, unexpired name', async () => {
      const registererOne = otherAddresses[0];
      const registererTwo = otherAddresses[1];

      await mintWRLDToAddressAndAllow(registererOne, 50000);
      await mintWRLDToAddressAndAllow(registererTwo, 50000);

      await wnsContract.connect(registererOne).register([ 'arkdev' ], [ 2 ]);
      await expect(wnsContract.connect(registererTwo).register([ 'arkdev' ], [ 3 ])).to.be.reverted;
    });
  });

  describe('Name Management', () => {
    it('Creates wrld name, sets and retrieves record types', async () => {
      const registerer = otherAddresses[0];
      const controller = otherAddresses[1];
      const otherAddress = otherAddresses[2];

      await mintWRLDToAddressAndAllow(registerer, 5000);
      await wnsContract.connect(registerer).register([ 'arkdev' ], [ 10 ]);

      expect(await wnsContract.getNameOwner('arkdev')).to.equal(registerer.address);

      await wnsContract.connect(registerer).setController('arkdev', controller.address);
      expect(await wnsContract.getNameController('arkdev')).to.equal(controller.address);

      await wnsContract.connect(controller).setAddressRecord('arkdev', 'test', otherAddress.address, 3600);
      const addressRecord = await wnsContract.getNameAddressRecord('arkdev', 'test');
      const defaultAddressRecord = await wnsContract.getNameAddressRecord('arkdev', 'evm_default');
      const addressRecords = await wnsContract.getNameAddressRecordsList('arkdev');
      expect(addressRecord.value).to.equal(otherAddress.address);
      expect(addressRecord.ttl).to.equal(3600);
      expect(defaultAddressRecord.value).to.equal(registerer.address);
      expect(addressRecords[0]).to.equal('evm_default');
      expect(addressRecords[1]).to.equal('test');

      await wnsContract.connect(registerer).setStringRecord('arkdev', 'test1', 'something', 'A', 3600);
      const stringRecord = await wnsContract.getNameStringRecord('arkdev', 'test1');
      const stringRecords = await wnsContract.getNameStringRecordsList('arkdev');
      expect(stringRecord.value).to.equal('something');
      expect(stringRecord.typeOf).to.equal('A');
      expect(stringRecord.ttl).to.equal(3600);
      expect(stringRecords[0]).to.equal('test1');

      await wnsContract.connect(controller).setUintRecord('arkdev', 'test2', 1234, 3600);
      const uintRecord = await wnsContract.getNameUintRecord('arkdev', 'test2');
      const uintRecords = await wnsContract.getNameUintRecordsList('arkdev');
      expect(uintRecord.value).to.equal(1234);
      expect(uintRecord.ttl).to.equal(3600);
      expect(uintRecords[0]).to.equal('test2');

      await wnsContract.connect(controller).setIntRecord('arkdev', 'test3', -1234, 3600);
      const intRecord = await wnsContract.getNameIntRecord('arkdev', 'test3');
      const intRecords = await wnsContract.getNameIntRecordsList('arkdev');
      expect(intRecord.value).to.equal(-1234);
      expect(intRecord.ttl).to.equal(3600);
      expect(intRecords[0]).to.equal('test3');

      await expect(wnsContract.connect(otherAddress).setAddressRecord('arkdev', 'test', otherAddress.address, 3600)).to.be.reverted;
      await expect(wnsContract.connect(otherAddress).setStringRecord('arkdev', 'test1', 'new', 'A', 3600)).to.be.reverted;
      await expect(wnsContract.connect(otherAddress).setUintRecord('arkdev', 'test2', 4567, 3600)).to.be.reverted;
      await expect(wnsContract.connect(otherAddress).setIntRecord('arkdev', 'test3', -4567, 3600)).to.be.reverted;
    });
  });

  describe('Alternate Resolver', () => {

  });

  /**
   * Helpers
   */

  async function mintWRLDToAddressAndAllow(toWallet, amount) {
    const bigNumberAmount = ethers.BigNumber.from(amount).mul(BigInt(1e18));

    await wrldContract.mint(toWallet.address, bigNumberAmount);
    await wrldContract.connect(toWallet).approve(wnsContract.address, bigNumberAmount);
  }
});
