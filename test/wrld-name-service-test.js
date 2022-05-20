const { expect } = require('chai');
const { ethers, waffle } = require('hardhat');

const ANNUAL_WRLD_PRICE = 500;

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
      }
    });

    it('Fails to regiter an existing, unexpired name', async () => {
      const registererOne = otherAddresses[0];
      const registererTwo = otherAddresses[1];

      await mintWRLDToAddressAndAllow(registererOne, 50000);
      await mintWRLDToAddressAndAllow(registererTwo, 50000);

      await wnsContract.connect(registererOne).register([ 'arkdev' ], [ 2 ]);
      await wnsContract.connect(registererTwo).register([ 'arkdev' ], [ 3 ]);
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
