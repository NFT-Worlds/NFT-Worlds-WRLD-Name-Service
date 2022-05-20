const { expect } = require('chai');
const { ethers, waffle } = require('hardhat');

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
});
