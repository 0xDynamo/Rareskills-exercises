import {console} from "forge-std/console.sol";

pragma solidity ^0.8.13;

contract Puzzle {
    function puzzle() external view returns (bool success) {
        require(msg.sender != tx.origin);
        require(msg.sender.code.length == 0);
        success = true;
    }
}

contract InteractWithPuzzle {
    Puzzle puzzle;

    constructor(address _puzzle) {
        puzzle = Puzzle(_puzzle);
        bool success = puzzle.puzzle();
        console.log("The output of success is: ", success);
    }

    function setTesting() public {
        puzzle.puzzle();
    }
}
