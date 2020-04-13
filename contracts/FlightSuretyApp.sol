pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    FlightSuretyData dataContract;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    bool private operationalContract = true;

    bool private operational = true;

    address[] voters = new address[](0);

    //Events


    address private contractOwner;          // Account used to deploy contract
    mapping (address => bool) authorizedCallers;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }

    mapping(bytes32 => Flight) private flights;


    uint256 public airlineRegistrationFee = 10 ether;
    uint256 public insuranceCap = 1 ether;

    address _dataContractAddress;

 
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
         // Modify to call data contract's status
        require(operationalContract, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the airline to fulfill a minimun funding
    */
    modifier requireMinimumFunding(){
        require(msg.value >= airlineRegistrationFee, "Funding requirement not met");
        _;
    }

    /**
    * @dev Modifier that requires the airline to be a voter
    */
    modifier requireMinimunInsurance()
    {
        require(msg.value > 0, "Insurance value cannot be 0");
        _;
    }

    /**
    * @dev Modifier that requires the airline to be registered
    */
    modifier requireAirlineIsApproved(address airline) //APP
    {
        require(dataContract.isAirlineIsApproved(airline) == true, "Airline is not registered");
        _;
    }

    /**
    * @dev Modifier that requires the airline to not be registered
    */
    modifier requireAirlineNotApproved(address airline)
    {
        require(dataContract.isAirlineIsApproved(airline) == false, "The airline is already registered");
        _;
    }

    /**
    * @dev Modifier that requires the airline to not be registered
    */
    modifier requireAirlineNotFunded(address airline)
    {
        require(dataContract.isAirlineIsVoter(airline) == false, "The airline is already funded");
        _;
    }

    /**
    * @dev Modifier that requires the airline to be a voter
    */
    modifier requireAirlineIsVoter(address airline)
    {
        require(dataContract.isAirlineIsVoter(airline) == true, "Airline is not allowed to vote");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address dataContractAddress
                                )
                                public
                                payable
    {
        contractOwner = msg.sender;
        authorizedCallers[address(this)] = true;
        authorizedCallers[contractOwner] = true;

        dataContract = FlightSuretyData(dataContractAddress);
        _dataContractAddress = dataContractAddress;
        //dataContract.registerAirline.value(msg.value)(firstAirline);

        /* airlinescount = airlinesCount.add(1);
        arilines[msg.sender] = Airline({id: airlinesCount, isVoter: true}); */
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational()
                            public
                            returns(bool)
    {
        return operationalContract;  // Modify to call data contract's status
    }

    function getInsuranceCap()
                            public
                            returns(uint256)
    {
        return insuranceCap;
    }

    function setInsuranceCap(uint256 cap)
                            external
                            requireIsOperational
                            requireContractOwner
    {
        insuranceCap = cap;
    }

    function getAirlineRegistrationFee()
                                        public
                                        view
                                        returns(uint256)
    {
        return airlineRegistrationFee;
    }

    function setAirlineRegistrationFee(uint256 fee)
                            external
                            requireIsOperational
                            requireContractOwner
    {
        airlineRegistrationFee = fee;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


   /**
    * @dev Add an airline to the registration queue
    *
    */
    function registerAirline
                            (
                                address airline
                            )
                            external
                            requireIsOperational
                            requireAirlineIsApproved(msg.sender)
                            requireAirlineIsVoter(msg.sender)
                            requireAirlineNotApproved(airline)
                            //returns(bool success, uint256 votes)
    {
        uint maxAutoApprovedAirlines = dataContract.getMaxAutoAprovedAirlines();
        uint minVotes = dataContract.getAirlineMinVotes(airline);
        uint votes = dataContract.getAirlineVotes(airline);

        uint airlinesCount = dataContract.getAirlinesCount();
        //uint flightCount = dataContract.getFlightCount();
        //uint insuranceCount = dataContract.getInsuranceCount();

        if(airlinesCount <= maxAutoApprovedAirlines){ //Consensus not required
            dataContract.registerAirline(airline, msg.sender);
            //Emit approved
        } else { //Requires consensus
            if(votes >= minVotes) { //approved
                dataContract.setApproved(airline, true);
                //emit Votes Registered(_address);
            } else { //Not approved
            address[] memory approvals = dataContract.getApprovals(airline);
                for(uint i = 0; i < approvals.length; i++) {
                    require(approvals[i] != msg.sender, "Airline already voted for approval");
                }
                dataContract.registerVote(airline, msg.sender);
                votes = dataContract.getAirlineVotes(airline);
                if (votes >= minVotes){
                    dataContract.setApproved(airline, true);
                    //emit AirlineRegistered(_address);
                }
            }
        }
        //return (success, 0);
    }


   /**
    * @dev Register a future flight for insuring.
    *
    */
    function registerFlight
                                (
                                )
                                external
                                pure
    {

    }

   /**
    * @dev Called after oracle has updated flight status
    *
    */
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                pure
    {
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    function creditInsurance(uint insuranceId) external requireIsOperational
    {
        dataContract.creditInsurees(insuranceId);
    }

    function buyInsurance(uint flightId, address insuree) external requireIsOperational requireMinimunInsurance payable
    {
        uint amountPaid;
        if (msg.value >= insuranceCap) {
            amountPaid = insuranceCap;
        } else {
            amountPaid = msg.value;
        }

        uint amountToReturn = msg.value.sub(amountPaid);

        dataContract.buy(flightId, insuree, amountPaid);
        address(msg.sender).transfer(amountToReturn);
    }

    function fundAirline()  external
                            payable
                            requireIsOperational
                            requireMinimumFunding
                            requireAirlineNotFunded(msg.sender)
    {
        address(dataContract).transfer(msg.value);
        dataContract.setFunded(msg.sender, true);
        //emit RegistrationFeePaid(msg.sender, registrationFee);
    }



// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (
                                address account
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}


contract FlightSuretyData {
    //Utility functions
    function isOperational() public view returns(bool);

    function isAirlineIsExist(address airline) public view returns(bool);
    function isAirlineIsVoter(address airline) public view returns(bool);
    function isAirlineIsApproved(address airline) public view returns(bool);
    function getAirlineMinVotes(address airline) public view returns(uint);

    function getAirlineVotes(address airline) public view returns(uint);
    function getAirlinesCount() public view returns(uint);
    function getFlightCount() public view returns(uint);
    function getInsuranceCount() public view returns(uint);

    function getMaxAutoAprovedAirlines() public view returns(uint);

    //Contract functions
    function registerAirline(address airline, address registeredAirline) public payable;
    function registerVote(address airline, address registeringAirline) public;
    function getApprovals(address airline) public returns(address[]);
    function setApproved(address airline, bool approved) public;

    function setFunded(address airline, bool isVoter) public;
    function creditInsurees(uint insuranceId) public;
    function buy(uint flightId, address insuree, uint amountPaid) public payable;
    function fund() public payable;
    function () external payable;
}



/*
function setIsAuthorizedCaller(address _address, bool isAuthorized) public;
    function createAirline(address airlineAddress, bool isVoter) public;
    function addFunds(uint _funds) public;
    function getAirlinesCount() public view returns (uint);
    function createInsurance(uint _flightId, uint _amountPaid, address _owner) public;
    function getInsurance(uint _id) public view returns (uint id, uint flightId, string memory state, uint amountPaid, address owner);
    function createFlight(string _code, uint _departureTimestamp, address _airlineAddress) public;
    function getFlight(uint _id) public view returns (uint id, string flight, bytes32 key, address airlineAddress, string memory state, uint departureTimestamp, uint8 departureStatusCode, uint updated);
    function getInsurancesByFlight(uint _flightId) public view returns (uint[]);
    function creditInsurance(uint _id, uint _amountToCredit) public;
    function getAirline(address _address) public view returns (address, uint, bool);
    function setAirlineIsVoter(address _address, bool isVoter) public;
    function setDepartureStatusCode(uint _flightId, uint8 _statusCode) public;
    function setUnavailableForInsurance(uint flightId) public;
    function getFlightIdByKey(bytes32 key) public view returns (uint);
    function createFlightKey(address _airlineAddress, string memory flightCode, uint timestamp) public returns (bytes32);
    function withdrawCreditedAmount(uint _amountToWithdraw, address _address) public payable;
    function getCreditedAmount(address _address) public view returns (uint);
    */