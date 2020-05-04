
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {
    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            let airline = DOM.elid('submit-oracles-airline').value;
            let timestamp = DOM.elid('submit-oracles-timestamp').value;
            
            // Write transaction
            contract.fetchFlightStatus(flight, airline, timestamp, (error, result) => {
                console.log(result);
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })

        
        // Submit airline to register
        DOM.elid('submit-register-airline').addEventListener('click', () => {
            let airline = DOM.elid('register-airline-address').value;
            // Write transaction
            contract.registerAirline(airline, (error, airline, result) => {
                alert((error) ? `An error ocurred ${error}` : `Airline ${airline} registered`)  
                //display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })

        // Submit airline to register
        DOM.elid('check-airline-status').addEventListener('click', () => {
            let airline = DOM.elid('check-airline-address').value;
            contract.isAirlineIsExist(airline, (error, result) => {
                let registeredCheck = DOM.elid('is-registered-check');
                if(error){
                    displayError('Check Airline', error, 'register-airline-errors');
                    registeredCheck.innerText = '';
                    return;
                }
                if(result){
                    registeredCheck.className = "text-success";
                    registeredCheck.innerText = "Registered";
                }else
                {
                    registeredCheck.className = "text-danger";
                    registeredCheck.innerText = "Not registered";
                }
            });
            contract.isAirlineIsVoter(airline, (error, result) => {
                let voterCheck = DOM.elid('is-voter-check');
                if(error){
                    displayError('Check Airline', error, 'register-airline-errors');
                    voterCheck.innerText = '';
                    return;
                }
                if(result){
                    voterCheck.className = "text-success";
                    voterCheck.innerText = "Voter";
                }else
                {
                    voterCheck.className = "text-danger";
                    voterCheck.innerText = "Not Voter";
                }
            });
            contract.isAirlineIsApproved(airline, (error, result) => {
                let approvedCheck = DOM.elid('is-approved-check');
                if(error){
                    displayError('Check Airline', error, 'register-airline-errors');
                    approvedCheck.innerText = '';
                    return;
                }
                if(result){
                    approvedCheck.className = "text-success";
                    approvedCheck.innerText = "Approved";
                }else
                {
                    approvedCheck.className = "text-danger";
                    approvedCheck.innerText = "Not Approved";
                }
            });
        });

        //fund airline
        DOM.elid('fund-airline').addEventListener('click', () => {
            let airline = DOM.elid('fund-airline-address').value;
            let fund = DOM.elid('airline-fund').value;
            contract.fundAirline(airline, fund, (error, result) => {
                alert((error) ? `An error ocurred ${error}` : 'Airline funded')  
            })
        });

        //Register flight
        DOM.elid('register-flight').addEventListener('click', () => {
            let airline = DOM.elid('register-flight-airline').value;
            let flight = DOM.elid('register-flight-reference').value;
            let status = DOM.elid('register-flight-status').value;
            let timestamp = DOM.elid('register-flight-timestamp').value;
            contract.registerFlight(status, flight, timestamp, airline, (error, result) => {
                alert((error) ? `An error ocurred ${error}` : `Flight ${flight} is registered`)  
            })
        })

        //Buy insurance
        DOM.elid('purchase-insurance').addEventListener('click', () => {
            let flight = DOM.elid('insurance-flight-reference').value;            
            let passenger = DOM.elid('insuree-insurance-address').value;
            let insuranceAmount = DOM.elid('insurance-amount').value;
            contract.buyInsurance(flight, passenger, insuranceAmount, (error, result) => {
                alert((error) ? `An error ocurred ${error}` : `Insurance purchased for flight ${flight} for passenger ${passenger}`)  
            })
        })

        //Claim insurance
        DOM.elid('claim-insurance').addEventListener('click', () => {
            let insuree = DOM.elid('insuree-claim-address').value;            
            contract.witdrawCredits(insuree, (error, result) => {
                alert((error) ? `An error ocurred ${error}` : `Insurance credits have been claimed for insuree ${insuree}`)  
            })
        })

        //Check for credits
        DOM.elid('check-credits').addEventListener('click', () => {
            let passenger = DOM.elid('insuree-address').value;
            contract.getInsureeCredits(passenger, (error, result) => {
                (error) &&  alert( `An error ocurred ${error}`);
                DOM.elid('insuree-credits').innerText = `${result} ETH`;
            })
        })

        //Operating change --Delete
        DOM.elid('operation-change').addEventListener('click', () => {
            contract.operatingChange((error, result) => {
                alert((error) ? `An error ocurred ${error}` : `Operation status changed to ${result}`)  
            })
        })

        //get current timestamp
        DOM.elid('register-flight-current-timestamp').addEventListener('click', () => {
            ///Utility
            let timestamp = Math.floor(Date.now() / 1000);
            DOM.elid('register-flight-timestamp').value = timestamp.toString();
        });

        //get current timestamp
        DOM.elid('submit-oracles-current-timestamp').addEventListener('click', () => {
            ///Utility
            let timestamp = Math.floor(Date.now() / 1000);

            DOM.elid('submit-oracles-timestamp').value = timestamp.toString();
        });        

        /* ///Get flight status
        DOM.elid("get-flight").addEventListener("click", async ()=>{
            let request = {
                flight: DOM.elid("get-flight-flight-id").value
            };

            let err, result, label;
            try {
                result = await contract.getFlight(request);
                label = "Success";
            } catch (e) {
                err = e;
                console.log(e);
                label = "Failure";
            } finally {
                display('Get Flight',
                    'Get flight from the system',
                    [
                        { label: "Airline Address", error: err, value: result.airlineAddress },
                        { label: "Code", error: err, value: result.flight },
                        { label: "Status", error: err, value: result.state },
                        { label: "Departure Status", error: err, value: result.departureStatusCode },
                        { label: "Departure", error: err, value: new Date(result.departureTimestamp.toNumber() * 1000) },
                        { label: "Updated", error: err, value: new Date(result.updated.toNumber() * 1000) },
                    ]
                );
            }
        }); */

    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}

function displayError(title, error, wrapper){
    let div = DOM.elid(wrapper);
    if(error)
    {
        div.innerHTML = `${title} - ${error}`;
    }else{
        div.innerHTML = '';
    }
    
}

function feedToast(title, message){
    let toastDiv = DOM.elid("myToast");
    let toastContent = DOM.div({className:'toast', role:'alert', dataAutohide:false, ariaLive:'assertive', ariaAomic: true});
    let toastBody = DOM.div(message, {className:'body'});
    let closeButton = DOM.button({type: 'button', className:'ml-2 mb-1 close', dataDismiss:"toast", ariaLabel: "Close"});
    closeButton.appendChild(DOM.span("&times;", {ariaHidden: true}));
    let toastTitle = DOM.strong(title, {className: 'mr-auto'});
    let toastHeader = DOM.div({className: "toast-header"});
    toastHeader.appendChild(toastTitle);
    toastHeader.appendChild(closeButton);
    toastContent.appendChild(toastHeader);
    toastContent.appendChild(toastBody);
    toastDiv.appendChild(toastContent);
}