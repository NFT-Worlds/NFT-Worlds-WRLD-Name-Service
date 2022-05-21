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
