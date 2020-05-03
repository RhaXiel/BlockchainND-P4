import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);


const oracles = [];

//Initialize oracle
/* const init = async() =>{
  let accounts = await web3.eth.getAccounts();

  const statusCode = process.env.STATUS_CODE;
  const registrationFee = web3.utils.toWei('1', 'ether');
  config.appAddress
  // register 20 oracles
  accounts.slice(10, 30).forEach((account) => {
      const oracle = new Oracle(account, statusCode);
      oracle.startListening(flightSuretyApp, registrationFee);
      oracles.push(oracle);
  });
};
init(); */

//Oracle updates

//Boilerplate
flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log("Error:",  error)
    console.log('oracle-requiest', event)
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

//Functioning oracle
app.get('/', (req,res) =>{
  const oracleListening = oracles.filter(oracle => oracle.isListening);
  res.send(`${oracles.length} oracles are instantiating, and ${oracleListening.length} oracles are running`);
})

export default app;


