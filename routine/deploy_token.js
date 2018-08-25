const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.HttpProvider("https://ropsten.infura.io/JJmpaoaxFzcPwQACB0AV"));

const common = require('./common');
const addresses = require('./addresses');

const readJson = common.readJson;
const sendTransaction = common.sendTransaction;

readJson('../build/contracts/Token.json')
.then(data => {
    const token_abi = data.abi;
    
    const token_contract = new web3.eth.Contract(token_abi, addresses.TC);

    // transfer tokens to addresses

    // 36 000 000 to PH
    const transfer_amount = web3.utils.toWei('36000000', 'ether');
    const transfer_data = token_contract.methods.transfer(addresses.PH, transfer_amount).encodeABI();
    sendTransaction(addresses.CO, addresses.TC, addresses.CO_private, '0x0', transfer_data);

    // TODO: do others

    
})
.catch(err => console.log(err));