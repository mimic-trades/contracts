const Token = artifacts.require("./Token.sol");

const expectedRevert = async (func) => {
  const PREFIX = 'VM Exception while processing transaction: '; 

  try {
    await func;
    throw null;
  } catch (error) {
    assert(error, "Expected an error but did not get one");
    assert(error.message.startsWith(PREFIX + 'revert'), "Expected an error starting with '" + PREFIX + 'revert' + "' but got '" + error.message + "' instead");
  }
};

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

  describe('Lock dates are unset', function() {
    it('Start lock date is 0', async function() {
      const date = await token.lockStartDate.call();

      assert.equal(date, 0);
    });

    it('End lock date is 0', async function() {
      const date = await token.lockEndDate.call();

      assert.equal(date, 0);
    });

    it('Absolute date difference is 0', async function() {
      const date = await token.lockAbsoluteDifference.call();

      assert.equal(date, 0);
    });
  });

  describe('Transfers', function() {
    const addr = accounts[1];

    it('Owner to account', async function() {
      const owner = await token.owner.call();

      const beforeOwnerBalance = await token.balanceOf.call(owner);
      const beforeAccountBalance = await token.balanceOf.call(addr);

      const amount = 1000;
      const amountStr = web3.toWei(amount, 'ether');

      await token.transfer.sendTransaction(addr, amountStr);

      const ownerBalance = await token.balanceOf.call(owner);
      const accountBalance = await token.balanceOf.call(addr);

      const expectedOwner = beforeOwnerBalance.sub(amountStr);
      const expectedAccount = beforeAccountBalance.add(amountStr);

      assert.equal(ownerBalance.toString(10), expectedOwner.toString(10));
      assert.equal(accountBalance.toString(10), expectedAccount.toString(10));
    });

    it('Account to owner', async function() {
      const owner = await token.owner.call();

      const amount = 1000;
      const amountStr = web3.toWei(amount, 'ether');

      await expectedRevert(token.transfer.sendTransaction(owner, amountStr, { from: addr }));
    });
  });

  describe('Locked tokens', function() {
    const addr = accounts[accounts.length - 1];

    it('No locked tokens', async function() {
      const amount = await token.getLockedAmount.call(addr);
      
      assert.equal(amount.toString(10), '0');
    });

    it('Set locked tokens', async function() {
      const lockAmount = web3.toWei('100', 'ether');
      
      await token.freeTokens.sendTransaction();
      await token.setLockedAmount.sendTransaction(addr, lockAmount);

      const amount = await token.getLockedAmount.call(addr);

      assert.equal(amount.toString(10), lockAmount.toString(10));
    });

    it('Update locked tokens', async function() {
      const lockAmount = web3.toWei('100', 'ether');
      const expected = web3.toWei('200', 'ether');
      
      await token.updateLockedAmount.sendTransaction(addr, lockAmount);

      const amount = await token.getLockedAmount.call(addr);

      assert.equal(amount.toString(10), expected.toString(10));
    });
  });
});
