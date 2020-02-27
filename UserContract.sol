pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;

import 'BankAbstractContract.sol';

contract UserContract {
    
    address private owner;
    
    struct RD {
        bytes32 id;
        uint8 duration;
        uint256 maturity;
        uint256 installment;
        uint256 amountPaidTillNow;
        uint32 interestRate;
        bool isComplete;
        uint8 countInstallment;
        address bank;
    }
    
    mapping(bytes32 => RD) private myRDs;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized !!!");
        _;
    }
    
    modifier nonZeroAmount(uint256 value) {
        require(value > 0, "Amount specified is invalid !!!");
        _;
    }
    
    modifier checkBalance(uint256 value) {
        require(address(this).balance > 0 && address(this).balance >= value, "Please add some money first !!!");
        _;
    }
    
    receive() external payable {
    }
    
    fallback() external payable {
    }
    
    function getBalance() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }
    
    function getInterestRate(address bank, uint8 duration) public view returns(uint32) {
        BankAbstractContract bac = BankAbstractContract(bank);
        return bac.getInterestRate(duration);
    }
    
    function createRD(address bank, uint8 duration, uint256 value) 
    public payable onlyOwner nonZeroAmount(value) checkBalance(value) returns(bytes32) {
        uint32 interestRate = getInterestRate(bank, duration);
        uint256 maturityAmount = value*duration + (value * duration * interestRate) / 100;
        bytes32 id = keccak256(abi.encodePacked(msg.sender, value, now, duration));
        
        RD memory rd = RD(id, duration, maturityAmount, value, value, interestRate, false, 1, bank);
        myRDs[id] = rd;
        payable(bank).transfer(value);
        BankAbstractContract bac = BankAbstractContract(bank);
        bool result = bac.receiveTransaction(id, duration, maturityAmount, value, interestRate, false,1);
        assert(result == true);
        return id;
    }
    
    function payInstallment(bytes32 id, uint value) 
    public payable onlyOwner nonZeroAmount(value) checkBalance(value) returns(bool) {
        RD memory rd = myRDs[id];
        require(rd.id == id, "RD doesn't exist!");
        require(rd.installment == value, "Amount doesn't match installment!");
        require(rd.isComplete == false, "RD is already matured, no need to pay further installments!");
        
        rd.amountPaidTillNow = rd.amountPaidTillNow + value;
        rd.countInstallment = rd.countInstallment + 1;
        
        if(rd.countInstallment == rd.duration) {
            rd.isComplete = true;
        }
        
        myRDs[id] = rd;
        payable(rd.bank).transfer(value);
        BankAbstractContract bac = BankAbstractContract(rd.bank);
        bool result = bac.receiveTransaction(id, rd.duration, rd.maturity, rd.amountPaidTillNow,
                        rd.interestRate, rd.isComplete, rd.countInstallment);
        
        assert(result == true);
        return true;
    }
    
    function getRDDetails(bytes32 id) public view onlyOwner returns(RD memory) {
        require(myRDs[id].id == id, "Invalid RD-id");
        return myRDs[id];
    }
    
}