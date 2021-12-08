// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This example was taken from the code examples on:
// https://ethereum.org/en/

/**
NOTE: THIS WILL NOT BE AUTOMATICALLY COMPILED.
If you want it to compile, either import it into contract.sol or copy and paste the contract directly into there!
**/
contract KRAUSE is ERC20 {
    constructor() ERC20("$KRAUSE", "KRAUSE") {
        _mint(msg.sender, 100);
    }
}