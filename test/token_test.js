const Token = artifacts.require("./Token.sol");

contract('Token', function(accounts) {
  let token = null;
  
  beforeEach('deploy', async function() {
    token = await Token.deployed();
  });

  describe('Token info', function() {
    it('Symbol', async function() {
      const symbol = await token.symbol.call();
  
      assert.equal(symbol, 'MIMIC');
    });

    it('Name', async function() {
      const name = await token.name.call();

      assert.equal(name, 'MIMIC');
    });

    it('Decimals', async function() {
      const decimals = await token.decimals.call();

      assert.equal(decimals, 18);
    });

    it('Total supply', async function() {
      const supply = await token.totalSupply.call();
      const expected = web3.toWei('900000000', 'ether');

      assert.equal(supply.toString(10), expected);
    });

    it('Owner Balance', async function() {
      const owner = await token.owner.call();
      const balance = await token.balanceOf.call(owner);

      const expected = web3.toWei('900000000', 'ether');

      assert.equal(balance.toString(10), expected);
    });
  });
});
