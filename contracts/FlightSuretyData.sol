pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    uint public airlinesCount = 0;
    uint public flightCount = 0;
    uint public insuranceCount = 0;

    mapping(address => bool) public authorizedCallers;

    //Airlines
    struct Airline {
        uint id;
        bool isVoter;
    }
    mapping(address => Airline) public airlines;

    /* enum FlightState{AvailableForinsurance, NotAvailableForInsurance}
    struct Flight {
        uint id;
        string flight;
        bytes32 key;
        address airlineAddress;
        FlightState state;
        uint departureTimestamp;
        uint8 departureStatusCode;
        uint updatedTimestamp;
    }
    mapping(uint => Flight) public flights; */

    enum InsuranceState {Active, Expired, Credited}
    struct Insurance {
        uint id;
        uint flightId;
        InsuranceState state;
        uint insuredAmount;
        address insuree;
    }

    mapping(uint => Insurance) public insurances;
    mapping(address => uint[]) private passengerInsurances;
    mapping(uint => uint[]) private flightInsurances;

    mapping(address => uint) public insuranceCredits;


    uint256 public airlineRegistrationFee = 10 ether;
    uint256 public insuranceCap = 1 ether;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AddedFunds(address contractAddress, uint amount);
    event UpdatedCallerIsAuthorized(address contractAddress, bool isAuthorized);

    event RegisteredAirline(address airlineAddres);
    event UpdatedAirlineIsVoter(address airlineAddress, bool isVoter);
    event UpdatedAirlineVotes(address airlineAddress, bool vote);

    event AddedFlightForInsurance(uint flightId);
    event RemovedFlightForInsurance(uint flightId);
    event UpdatedFlightDepartureStatus(uint flightId, uint8 statusCode);

    event ActivatedInsurance(uint insuranceId);
    event CreditedInsurance(uint insuranceId);
    event ExpiredInsurance(uint insuranceId);
    event WitdrawnInsurance(uint insuranceId);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                )
                                public
                                payable
    {
        contractOwner = msg.sender;
        authorizedCallers[address(this)] = true;
        authorizedCallers[contractOwner] = true;

        airlinesCount = airlinesCount.add(1);
        airlines[contractOwner] = Airline({id: airlinesCount, isVoter: true});
        address(this).transfer(msg.value);
    }

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
        require(operational, "Contract is currently not operational");
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
    * @dev Modifier that requires the caller to be a contract administrator
    */
    modifier requireAdmin()
    {
        require(authorizedCallers[msg.sender] == true, "Caller is not an admin");
        _;
    }

    /**
    * @dev Modifier that requires the caller to be the same as sender
    */
    modifier requireAuthorizedCaller(address caller)
    {
        require(msg.sender == caller, "Current caller cannot call this operation");
        _;
    }

    /**
    * @dev Modifier that requires the airline to be registered
    */
    modifier requireAirlineIsRegistered(address airline) //APP
    {
        require(airlines[airline].id > 0, "Airline is not registered");
        _;
    }

    /**
    * @dev Modifier that requires the airline to not be registered
    */
    modifier requireAirlineNotRegistered(address airline)
    {
        require(airlines[airline].id == 0, "The airline is already registered");
        _;
    }

    /**
    * @dev Modifier that requires the airline to fulfill a minimun funding
    */
    modifier requireMinimumFunding(uint funding){
        require(funding >= airlineRegistrationFee, "Funding requirement not met");
        _;
    }

    //APP
    /**
    * @dev Modifier that requires the airline to be a voter
    */
    modifier requireAirlineIsVoter(address airline)
    {
        require(airlines[airline].isVoter == true, "Airline is not allowed to vote");
        _;
    }

    /**
    * @dev Modifier that requires the flight to be active
    */
    /* modifier requireActiveFlight(uint flightId)
    {
        require(uint(flights[flightId].state) == 0, "Flight is not available for insurance");
        _;
    } */

    /**
    * @dev Modifier that requires the Insurance to be valid
    */
    modifier requireValidInsurance(uint insuranceId)
    {
        require(insurances[insuranceId].id > 0, "Insurance is invalid");
        _;
    }

    /**
    * @dev Modifier that requires the insurance to be active
    */
    modifier requireActiveInsurance(uint insuranceId)
    {
        require(uint(insurances[insuranceId].state) == 0, "Insurance is not active");
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

    modifier requireContractHasEnoughFunds(address insuree)
    {
        require(address(this).balance > insuranceCredits[insuree], "Contract does not have enough funds");
        _;
    }

    modifier requireCreditedInsurance(address insuree)
    {
        require(insuranceCredits[insuree] > 0, "Insuree does not have any credits");
        _;
    }

    /* modifier disallowReinsurance(uint insuranceId)
    {
        insurances[msg.sender].
    } */

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational()
                            public
                            view
                            returns(bool)
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus
                            (
                                bool mode
                            )
                            external
                            requireContractOwner
    {
        operational = mode;
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
                            //requireConsensus //Require for airlines to have consensus on changing funding
    {
        airlineRegistrationFee = fee;
    }

    function setInsuranceCap(uint256 cap)
                            external
                            requireIsOperational
                            requireContractOwner
                            //requireConsensus //Require for airlines to have consensus on changing funding
    {
        insuranceCap = cap;
    }

    function authorizeCaller(address user)
                            external
                            requireIsOperational
                            requireContractOwner
                            //requireConsensus //Require for airlines to have consensus on changing funding
    {
        authorizedCallers[user] = true;
    }

    function isAirline(address airline)
                            external
                            view
                            returns(bool)
    {
        bool _isAirline = (airlines[airline].id > 0);
        return _isAirline;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline
                            (
                                address airline
                            )
                            external
                            payable
                            requireIsOperational
                            requireAuthorizedCaller(msg.sender)
                            //requireAirlineIsRegistered(msg.sender)
                            requireAirlineNotRegistered(airline)
    {
        airlinesCount = airlinesCount.add(1);
        airlines[airline] = Airline({id: airlinesCount, isVoter: false});
        //Emit RegisteredAirline
    }


   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy
                            (
                                uint flightId,
                                address insuree
                            )
                            external
                            payable
                            requireIsOperational
                            //requireActiveFlight(flightId)
    {
        insuranceCount = insuranceCount.add(1);

        uint amountPaid;
        if (msg.value >= insuranceCap) {
            amountPaid = insuranceCap;
        } else {
            amountPaid = msg.value;
        }

        insurances[insuranceCount] = Insurance(
            {
                id: insuranceCount,
                flightId: flightId,
                state: InsuranceState.Active,
                insuredAmount: amountPaid,
                insuree: insuree
            });

        flightInsurances[flightId].push(insuranceCount);
        passengerInsurances[insuree].push(insuranceCount);
        //emit BoughtInsurance(insurancesById[insuranceCount].id);

        uint amountToReturn = msg.value.sub(amountPaid);
        address(this).transfer(amountPaid);
        address(msg.sender).transfer(amountToReturn);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    uint insuranceId
                                )
                                external
                                requireIsOperational
                                requireAuthorizedCaller(msg.sender)
                                requireValidInsurance(insuranceId)
                                requireActiveInsurance(insuranceId)
                                //requireDelayedFlight(insuranceId)
    {
        Insurance memory _insurance = insurances[insuranceId];
        uint credit = _insurance.insuredAmount.mul(15).div(10);
        insurances[insuranceId].state = InsuranceState.Credited;
        insuranceCredits[_insurance.insuree] = insuranceCredits[_insurance.insuree].add(credit);
        //Emit Credited
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            requireAuthorizedCaller(msg.sender)
                            requireCreditedInsurance(msg.sender)
                            requireContractHasEnoughFunds(msg.sender)
    {
        uint credit = insuranceCredits[msg.sender];
        insuranceCredits[msg.sender] = 0;
        msg.sender.transfer(credit);
        //emit Payed
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund
                            (
                            )
                            public
                            payable
                            //requireAirlineIsRegistered(msg.sender)
                            requireMinimumFunding(msg.value)
    {
        address(this).transfer(msg.value);
        //emit AddedFunds(address(this), msg.value);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        internal
                        pure
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function()
                            external
                            payable
    {
        fund();
    }


}

