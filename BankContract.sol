pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;
import 'BankAbstractContract.sol';

contract BankContract is BankAbstractContract {

    address private owner;
    mapping(uint8 => uint32) private interest_rates;
    
    struct RD {
        bytes32 id;
        address customer;
        uint8 duration;
        uint256 maturity;
        uint256 installment;
        uint256 amountPaidTillNow;
        uint32 interestRate;
        bool isComplete;
        uint8 countInstallment;
    }

    mapping(bytes32 => RD) private RDs;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized !!!");
        _;
    }
    
    fallback() external payable {
    }
    
    receive() external payable {
    }
    
    function getInterestRate(uint8 duration) override public view returns(uint32) {
        return interest_rates[duration];
    }
    
    function setInterestRate(uint8 duration, uint32 rate) onlyOwner public {
        interest_rates[duration] = rate;
    }
    
    function getBalance() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }
    
    function receiveTransaction(bytes32 id, uint8 duration, uint256 maturityAmount, uint256 value, uint32 interestRate,
    bool isComplete, uint8 countInstallment) override external payable virtual returns(bool) {
        if(RDs[id].id == id) {
            require(RDs[id].isComplete == false, "RD is already matured, no need to pay further installments!");
            RDs[id].countInstallment = RDs[id].countInstallment + 1;
            RDs[id].amountPaidTillNow = RDs[id].amountPaidTillNow + value;
            if(RDs[id].countInstallment == RDs[id].duration) {
                RDs[id].isComplete = true;
            }
        }
        else {
            RDs[id] = RD(id, msg.sender, duration, maturityAmount, value, value, interestRate, isComplete, countInstallment);
        }
        
        if(RDs[id].isComplete == true) {
            payable(RDs[id].customer).transfer(RDs[id].maturity);
        }
        return true;
    }
    
    function getRDDetails(bytes32 id) public view onlyOwner returns(RD memory) {
        require(RDs[id].id == id, "Invalid RD-id");
        return RDs[id];
    }
}
