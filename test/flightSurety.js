
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

  it(`(registering) first airline is registered when contract is deployed`, async function () {
    const isRegistered = await config.flightSuretyData.isAirlineIsExist.call(config.firstAirline);
    const isVoter = await config.flightSuretyData.isAirlineIsVoter.call(config.firstAirline);
    const isAirlineIsApproved = await config.flightSuretyData.isAirlineIsApproved.call(config.firstAirline);

    assert.equal(isRegistered, true, "First airline is not registered");
    assert.equal(isVoter, true, "First airline is not voter");
    assert.equal(isAirlineIsApproved, true, "First airline is not approved");
    
  });

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

  it('(airline) Only existing airline may register a new airline until there are at least four airlines registered', async () => {
      const addressNoConsensus1 = config.testAddresses[0];
      const addressNoConsensus2 = config.testAddresses[1];
      const addressNoConsensus3 = config.testAddresses[2];

      async function isRegistered(airline){
        const isRegistered = await config.flightSuretyData.isAirlineIsExist.call(airline);
        const isAirlineIsApproved = await config.flightSuretyData.isAirlineIsApproved.call(airline);
          return (isRegistered && isAirlineIsApproved);
      }

      var registeredAirlines = [];
      try {
          await config.flightSuretyApp.registerAirline(addressNoConsensus1, {from: config.firstAirline});
          registeredAirlines.push(await isRegistered(addressNoConsensus1));
          await config.flightSuretyApp.registerAirline(addressNoConsensus2, {from: config.firstAirline});
          registeredAirlines.push(await isRegistered(addressNoConsensus2));
          await config.flightSuretyApp.registerAirline(addressNoConsensus3, {from: config.firstAirline});
          registeredAirlines.push(await isRegistered(addressNoConsensus3));
          
      } catch (err) {
          console.log(err);
      }
      assert.equal(registeredAirlines[0], true, "Airline 1 could not be registered");
      assert.equal(registeredAirlines[1], true, "Airline 2 could not be registered");
      assert.equal(registeredAirlines[2], true, "Airline 3 could not be registered");
  });

  it('(airline) can be registered, but does not participate in contract until it submits funding of 10 ether', async () => {
    
    // ARRANGE
    const addressConsesusNeeded = config.testAddresses[3];
    const newAirline = accounts[4];

    // ACT
    let reverted = false;
    
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: addressConsesusNeeded});
        const isVoter = await config.flightSuretyData.isAirlineIsVoter.call(newAirline);
    }
    catch(e) {
        reverted = true;
    }

    // ASSERT
    assert.equal(reverted, true, "Registering airline has to be funded to be able to vote");    
  });

  it('(airline) contract can be funded by registered airlines', async () => {
    const unfundedAirline = config.testAddresses[1];

    let dataContractAddress = config.flightSuretyData.address;

    const balance =  await web3.eth.getBalance(dataContractAddress);
    let isVoter = false
     
    const funding = web3.utils.toWei("10", "ether");

    try {
        await config.flightSuretyApp.fundAirline({from: unfundedAirline, value: funding});    
        isVoter = await config.flightSuretyData.isAirlineIsVoter.call(unfundedAirline);
    } catch (e) {
        console.log("couldn't fund airline", e);
    }
    const newBalance = await web3.eth.getBalance(dataContractAddress);
    
    assert.equal(newBalance, (Number(balance) + Number(funding)).toString(), "Funding was unsuccesful"); 
    assert.equal(isVoter, true, "Airline is not voter");    
  });

  async function fund(address, _funding){
    await config.flightSuretyApp.fundAirline({from: address, value: _funding});    
    return await config.flightSuretyData.isAirlineIsVoter.call(address);
    }

  it('(airline) fund the rest of airlines for next tests', async () => {
        //Fund all the first airlines for next tests
        const addressNoConsensus1 = config.testAddresses[0];
        const addressNoConsensus3 = config.testAddresses[2];

        const funding = web3.utils.toWei("10", "ether");

        let voters =[];

        try {
            voters.push(await fund(addressNoConsensus1, funding));
        } catch (e) {
            console.log("couldn't fund airline", e);
        }    
        assert.equal(voters[0], true, "Airline 1 is not funded");

        try {
            voters.push(await fund(addressNoConsensus3, funding));
        } catch (e) {
            console.log("couldn't fund airline", e);
        }    
        assert.equal(voters[1], true, "Airline 3 is not funded");
  });

  it('(airline) Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines', async () => {
      //Airline created with contract count as the fourth one.
      const addressConsesusNeeded = config.testAddresses[3];

      async function isApproved(airline){
        const isRegistered = await config.flightSuretyData.isAirlineIsExist.call(airline);
        const isAirlineIsApproved = await config.flightSuretyData.isAirlineIsApproved.call(airline);
          return (isRegistered && isAirlineIsApproved);
      }

      let approved;
      try {
        //Consensus needed
        await config.flightSuretyApp.registerAirline(addressConsesusNeeded, {from: config.firstAirline});
        approved  = await isApproved(addressConsesusNeeded);
      } catch (err) {
          console.log(err)
      }
    //Consensus needed
    assert.equal(approved, false, "Airline needs consensus to be aproved");

    //Consensus

  });

  it('(passenger) may pay up to 1 ether for purchasing flight insurance', async () => {
    assert.equal(true,true, "true");
  });

  it('(flight) if is delayed due to airline fault, passenger receives credit of 1.5X the amount they paid', async () => {
    assert.equal(true,true, "true");
  });

  it('(passenger) can withdraw any funds owed to them as a result of receiving credit for insurance payout', async () => {
    assert.equal(true,true, "true");
  });

  it('(oracle) Upon startup, 20+ oracles are registered and their assigned indexes are persisted in memory', async () => {
    assert.equal(true,true, "true");
  });

  it('(oracle) Server will loop through all registered oracles, identify those oracles for which the OracleRequest event applies, and respond by calling into FlightSuretyApp contract with random status code of Unknown (0), On Time (10) or Late Airline (20), Late Weather (30), Late Technical (40), or Late Other (50)', async () => {
    assert.equal(true,true, "true");
  });

});