import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

/*
In server.js register the oracles
In server.js handle the OracleRequest events that are emitted when the function fetchFlightStatusfunction is called
In server.js submit the oracle response calling the function submitOracleResponsefunction in the contracts
*/

const oracles = [];

//Oracle updates
const TEST_ORACLES_COUNT = 20;
  var config;

  // Watch contract events
  const STATUS_CODE_UNKNOWN = 0;
  const STATUS_CODE_ON_TIME = 10;
  const STATUS_CODE_LATE_AIRLINE = 20;
  const STATUS_CODE_LATE_WEATHER = 30;
  const STATUS_CODE_LATE_TECHNICAL = 40;
  const STATUS_CODE_LATE_OTHER = 50;

//Initialize Oracles
(async ()=>{
    // ARRANGE
    let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();

    // ACT
    for(let a=1; a<TEST_ORACLES_COUNT; a++) {      
      await flightSuretyApp.methods.registerOracle().send({ from: web3.eth.accounts[a], value: fee });
      let result = await config.flightSuretyApp.getMyIndexes.call({from: accounts[a]});
      console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
      //request
      
    }
})();

//Boilerplate
flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log("Error:",  error)
    console.log('oracle-request', event)
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


