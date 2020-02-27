pragma solidity ^0.6.3;

abstract contract BankAbstractContract {
    
    function getInterestRate(uint8 duration) external virtual view returns(uint32);
    
    function receiveTransaction(bytes32 id, uint8 duration, uint256 maturityAmount, uint256 value, uint32 interestRate,
    bool isComplete, uint8 countInstallment) external payable virtual returns(bool);
    
}
