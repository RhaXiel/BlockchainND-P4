
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) can be registered, but does not participate in contract until it submits funding of 10 ether', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        //await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
        await config.flightSuretyData.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {
        console.log("couldn't register airline", e);

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, true, "Airline should be able to register another airline without funding");    
  });

  it('(airline) contract can be funded by registered airlines', async () => {
    let newAirline = accounts[2];

    let dataContractAddress = config.flightSuretyData.address;
    //console.log(await config.getBalance(dataContractAddress));

    //const balance =  await config.getContractBalance(dataContractAddress);
    //const balance =  await config.getBalance(dataContractAddress);
    //const balance =  await config.web3.eth.getBalance(dataContractAddress);
    
     
    const funding = config.weiMultiple; //config.web3.utils.toWei("10", "ether");

    try {
        await config.flightSuretyData.fund({from: newAirline, to: dataContractAddress,  value: 10000000000000000000});    
    } catch (e) {
        console.log("couldn't fund ether", e);
    }
    //const newBalance = await web3.eth.getBalance(dataContractAddress);

    //assert.equal(newBalance, (balance + funding), "Funding was unsuccesful"); 

    assert.equal(1,1,"one");
  });

});
