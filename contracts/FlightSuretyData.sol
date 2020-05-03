pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    uint private airlinesCount = 0;

    uint private flightCount = 0;
    
    uint private insuranceCount = 0;

    mapping(address => bool) private authorizedCallers;

    //Airlines
    struct Airline {
        uint id;
        bool isVoter;
        bool approved;
        uint minVotes;
    }

    mapping(address => Airline) private airlines;

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

    mapping(address => uint) votes;

    mapping(address => address[]) approvals;

    /* struct Votes{
        uint voteNumber;
        address airline;
        address voter;
    }

    address[] voters */

    uint maxAutoAprovedAirlines = 4;

    mapping(uint => Insurance) private insurances;
    mapping(address => uint[]) private passengerInsurances;
    mapping(uint => uint[]) private flightInsurances;

    mapping(address => uint) private insuranceCredits;

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
                                    address firstAirline
                                )
                                public
                                payable
    {
        contractOwner = msg.sender;
        authorizedCallers[address(this)] = true;
        authorizedCallers[contractOwner] = true;

        airlinesCount = airlinesCount.add(1);
        airlines[firstAirline] = Airline({id: airlinesCount, isVoter: true, approved: true, minVotes: 0});
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
    * @dev Modifier that requires the caller to be authorized
    */
    modifier requireAuthorizedCaller()
    {
        require(authorizedCallers[msg.sender] == true, "Caller is not authorized");
        _;
    }

    //APP
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

    function authorizeCaller(address _contract)
                            external
                            requireIsOperational
                            requireContractOwner
    {
        authorizedCallers[_contract] = true;
    }

    function deAuthorizeCaller(address _contract)
                                external
                                requireIsOperational
                                requireContractOwner
    {
        delete authorizedCallers[_contract];
    }

    function isAirlineIsExist(address airline)
                            external
                            view
                            returns(bool)
    {
        bool _isAirline = (airlines[airline].id > 0);
        return _isAirline;
    }

    function isAirlineIsVoter(address airline)
                            external
                            view
                            returns(bool)
    {
        return airlines[airline].isVoter;
    }

    function isAirlineIsApproved(address airline)
                            external
                            view
                            returns(bool)
    {
        return airlines[airline].approved;
    }

    function getAirlineMinVotes(address airline)
                            external
                            view
                            returns(uint)
    {
        return airlines[airline].minVotes;
    }

    function getAirlineVotes(address airline)
                            external
                            view
                            returns(uint)
    {
        return votes[airline];
    }

    function getMaxAutoAprovedAirlines()
                            external
                            view
                            returns(uint)
    {
        return maxAutoAprovedAirlines;
    }

    function setMaxAutoAprovedAirlines(uint maxAutoAprovedAirlinesValue)
                                external
                                requireIsOperational
                                requireContractOwner
    {
        maxAutoAprovedAirlines = maxAutoAprovedAirlinesValue;
    }

    function getAirlinesCount() external view returns(uint)
    {
        return airlinesCount;
    }

    function getFlightCount() external view returns(uint)
    {
        return flightCount;
    }

    function getInsuranceCount() external view returns(uint)
    {
        return insuranceCount;
    }

    function getApprovals(address airline) external view returns(address[] memory)
    {
        return approvals[airline];
    }

    function getInsuracesFlight(uint flightId) external view returns(uint[] memory)
    {
        return flightInsurances[flightId];
    }

    function getInsureeCredits(address insuree) external view returns(uint)
    {
        return insuranceCredits[insuree];
    }

    /*
    function getInsurances 
    mapping(uint => Insurance) private insurances;
    mapping(address => uint[]) private passengerInsurances;
    mapping(uint => uint[]) private flightInsurances;

    mapping(address => uint) private insuranceCredits; */

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
                                address airline,
                                address registeringAirline
                            )
                            external
                            requireIsOperational
                            requireAuthorizedCaller
    {
        airlinesCount = airlinesCount.add(1);
        airlines[airline] = Airline({
            id: airlinesCount,
            isVoter: false,
            approved: airlinesCount <= maxAutoAprovedAirlines,
            minVotes: airlinesCount.add(1).div(2)
            });
        votes[airline] = votes[airline].add(1);
        approvals[airline].push(registeringAirline);
        //Emit RegisteredAirline
    }

    function registerVote(
                            address airline,
                            address registeringAirline
                         )
                         external
                         requireIsOperational
                         requireAuthorizedCaller
    {
        votes[airline] = votes[airline].add(1);
        approvals[airline].push(registeringAirline);
        //Emit registeredvote
    }

    function setFunded(address airline, bool isVoter) external
                                    requireIsOperational
                                    requireAuthorizedCaller
    {
        airlines[airline].isVoter = isVoter;
    }

    function setApproved(address airline, bool approved) external
                                    requireIsOperational
                                    requireAuthorizedCaller
    {
        airlines[airline].approved = approved;
    }


   /**
    * @dev Buy insurance for a flight
    *
    */
    function buy
                            (
                                uint flightId,
                                address insuree,
                                uint amountPaid
                            )
                            external
                            payable
                            requireIsOperational
                            requireAuthorizedCaller
    {
        insuranceCount = insuranceCount.add(1);

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

        //address(this).transfer(amountPaid);
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
                                requireAuthorizedCaller
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
                                address insuree
                            )
                            external
                            payable
                            requireIsOperational
                            requireAuthorizedCaller
                            requireCreditedInsurance(insuree)
                            requireContractHasEnoughFunds(insuree)
    {
        uint credit = insuranceCredits[insuree];
        insuranceCredits[insuree] = 0;
        insuree.transfer(credit);
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
                            requireIsOperational
                            //requireAirlineIsRegistered(airline)
    {
        /* airlines[msg.sender].isVoter = true;
        address(this).transfer(msg.value); */
        //emit AddedFunds(airline, fundAmount);
        emit AddedFunds(address(this), 1);
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
        //fund();
        emit AddedFunds(address(this), 1);
    }


}

