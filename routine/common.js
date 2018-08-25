const fs = require('fs');
const Web3 = require("web3");
const Tx = require('ethereumjs-tx');

const readJson = (path) => {
    return new Promise((resolve, reject) => {
        fs.readFile(require.resolve(path), (err, data) => {
            if (err) {
                reject(err);
            } else {
                resolve(JSON.parse(data));
            }
        });
    })
};

const sendTransaction = (from, to, private, amount, data = undefined) => {
    web3.eth.getTransactionCount(from)
    .then(_nonce => {
        const nonce = web3.utils.toHex(_nonce);

        const params = {
            gasPrice: web3.utils.toHex(web3.utils.toWei('20', 'gwei')),
            gasLimit: web3.utils.toHex(4000000),
            nonce: nonce,
            from: from,
            to: to,
            value: amount
        };

        if (typeof data !== 'undefined') {
            params.data = data;
        }

        const tx = new Tx(params);
        tx.sign(private);

        const serialized = tx.serialize().toString('hex');

        web3.eth.sendSignedTransaction(`0x${serialized}`)
        .once('transactionHash', hash => console.log(hash));
    });
}

module.exports = {
    readJson,
    sendTransaction
};