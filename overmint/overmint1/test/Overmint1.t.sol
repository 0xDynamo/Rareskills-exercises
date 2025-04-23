// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import {Overmint1, PwnOvermint1} from "../src/Overmint1.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "forge-std/console.sol";

contract Overmint1Test is Test {
    Overmint1 overmint;
    PwnOvermint1 pwnovermint;

    address DEPLOYER;
    address ATTACKER;

    function setUp() public {
        DEPLOYER = makeAddr("deployer");
        ATTACKER = makeAddr("attacker");

        vm.prank(DEPLOYER);
        overmint = new Overmint1();
        vm.prank(ATTACKER);
        pwnovermint = new PwnOvermint1(address(overmint));
    }

    function testSetUp() public {
        console.log(
            "Both the Overmint and the Attacker contract have successfully been set up!"
        );
        console.log("");
        console.log("The Overmint contract is at: ", address(overmint));
        console.log("The Attacker contract is at: ", address(pwnovermint));
    }

    function testAttack() public {
        uint256 initialBalance = overmint.balanceOf(address(pwnovermint));
        console.log(
            "Before the attack, the attacker address has a balance of %s NFT's",
            initialBalance
        );
        vm.prank(ATTACKER);
        pwnovermint.attack();
        uint256 newBalance = overmint.balanceOf(address(pwnovermint));
        console.log(
            "After the attack, the attacker address has a balance of %s NFT's",
            newBalance
        );
        bool balanceOfAttacker = overmint.success(address(pwnovermint));
        assertTrue(balanceOfAttacker);
    }
}
