//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Puzzle, InteractWithPuzzle} from "../src/detectSmartContract.sol";

contract testPuzzle is Test {
    Puzzle puzzle;
    InteractWithPuzzle interactWithPuzzle;
    address DEPLOYER;

    function setUp() public {
        puzzle = new Puzzle();
    }

    function testSolve() public {
        new InteractWithPuzzle(address(puzzle));
    }

    function testTrueAndFalse() public {
        // Deploy the InteractWithPuzzle contract
        interactWithPuzzle = new InteractWithPuzzle(address(puzzle));

        vm.expectRevert();
        interactWithPuzzle.setTesting();
    }
}
