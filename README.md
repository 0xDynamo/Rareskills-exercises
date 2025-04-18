# Smart Contract Detection Puzzles

This repository contains my attempt at solving the RareSkills exercises related to detecting if an address is a smart contract in Solidity.

## Puzzle 1: Constructor Call Detection

Can you get the following contract to return `true` when `puzzle()` is called without causing a revert?

```solidity
contract Puzzle {        
    function puzzle()
        external
        view
        returns (bool success) {                
            require(msg.sender != tx.origin);                
            require(msg.sender.code.length == 0);                
            success = true;        
    }
}
```

### Challenge
- The function requires that `msg.sender` is not equal to `tx.origin` (meaning the caller must be a contract)
- However, it also requires that the calling contract has no code (`code.length == 0`)
- This seems contradictory! How can the caller be a contract but have no code?

### Hint
Think about when a contract's code is not yet deployed but it can still make external calls...

## Puzzle 2: tx.origin Code Examination

What should `tx.origin.code.length` return? Does it always return the same value?

### Challenge
- Understand what `tx.origin` represents in the EVM
- Determine whether `tx.origin` can ever be a contract address
- Explore the implications of this for contract security

## Background Knowledge

This exercise explores three methods for detecting if an address is a smart contract:
1. Comparing `msg.sender` and `tx.origin`
2. Checking `code.length` of an address
3. Examining `codehash` of an address

Each method has different trade-offs and edge cases that are important to understand for secure smart contract development.

## My Approach

This repository documents my personal attempt at solving these RareSkills challenges. I'm working through these exercises to improve my understanding of smart contract security and Solidity edge cases.

## Getting Started

1. Clone this repository
2. Use a development environment like Remix or Hardhat to experiment with the solutions
3. Write tests to verify the behavior

## Learning Resources

I'm working through these puzzles as part of my learning journey with RareSkills content. For anyone interested in similar challenges:
- [RareSkills Solidity Course](https://www.rareskills.io/solidity-course)
- [RareSkills Solidity Bootcamp](https://www.rareskills.io/solidity-bootcamp)

## Acknowledgements

These puzzles are from RareSkills' article "Three ways to detect if an address is a smart contract".
