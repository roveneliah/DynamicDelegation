// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This example was taken from the code examples on:
// https://ethereum.org/en/

/**
NOTE: THIS WILL NOT BE AUTOMATICALLY COMPILED.
If you want it to compile, either import it into contract.sol or copy and paste the contract directly into there!
**/

contract Delegation is ERC20 {
    // An address is comparable to an email address - it's used to identify an account on Ethereum.
    address public owner;
    uint public minStake;
    ERC20 krause;

    // Store the block delegate deposited to check cooldown.
    uint cooldownBlocks = 2100000; // ~365 days
    struct Delegate {
      address addr;
      uint stake;
      uint depositBlock;
    }

    // A mapping is essentially a hash table data structure.
    // This mapping assigns an unsigned integer (the token balance) to an address (the token holder).
    mapping (address => uint) delegateIndex; // index of addr in delegates
    Delegate[] delegates;
    
    // When 'SimpleToken' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the token balance of the owner to the total token supply
    constructor(address token) ERC20("KH Dynamic Delegated Votes", "VOTE") {
        owner = msg.sender;
        krause = ERC20(token);
        minStake = 10;
        _mint(owner, 100);
    }

    function getDelegate(uint i) public view returns (address, uint, uint) {
        return (delegates[i].addr, delegates[i].stake, delegates[i].depositBlock);
    }

    function delegateInd(address addr) public view returns (uint) {
        return delegateIndex[addr];
    }

    // Stake $KRAUSE to get whitelisted
    function stake(uint _stake) public {
        // check minimum stake!
        require(_stake >= minStake, "Stake too low.");
        require(krause.balanceOf(msg.sender) >= _stake, "Balance < attempted stake.");

        // send $KRAUSE to contract
        krause.transferFrom(msg.sender, address(this), _stake);

        if (delegateIndex[msg.sender] == 0) {
          // add delegate
          delegates.push(Delegate({
            stake: _stake,
            addr: msg.sender,
            depositBlock: block.number
          }));
          delegateIndex[msg.sender] = delegates.length;
        } else {
          // already a delegate
          delegates[delegateIndex[msg.sender]-1].stake += _stake;
        }
    }

    function withdraw() public onlyDelegates /*pastCooldown*/ {
      // send $KRAUSE back to delegate
      uint staked = delegates[delegateIndex[msg.sender]-1].stake;
      krause.transfer(msg.sender, staked);
      
      // delete their existing balance of VOTE
      _burn(msg.sender, super.balanceOf(msg.sender));

      // remove delegate
      delete delegates[delegateIndex[msg.sender]-1]; // might break iteration?
      delete delegateIndex[msg.sender];
    }


    /////////////////////////////////
    // ADMIN ONLY ///////////////////
    /////////////////////////////////
    function updateBalances(address[] memory recipients, uint256[] memory amounts) public onlyOwner returns (bool) {
      for (uint i = 0; i < recipients.length; i++) {
        require(delegateIndex[recipients[i]] > 0, "All recipients must be a delegate.");

        // mint if need more, burn if need less
        if (amounts[i] > super.balanceOf(recipients[i]))
          _mint(recipients[i], amounts[i] - super.balanceOf(recipients[i]));
        else if (amounts[i] < super.balanceOf(recipients[i]))
          _burn(recipients[i], super.balanceOf(recipients[i]) - amounts[i]);
      }
    }

    function ownerTransfer(address recipient, uint256 amount) public onlyOwner returns (bool) {
      require(delegateIndex[recipient] > 0, "Recipient must be a delegate");
      _transfer(msg.sender, recipient, amount);
      return true;
    }


    function clearBalances() public onlyOwner {
      for (uint i = 0; i < delegates.length; i++) { // ERROR: need to wipe ALL token balances...., not just delegates...
        // might need null check
        // send back to this contract
        _transfer(delegates[i].addr, owner, balanceOf(delegates[i].addr)); // reset balances
      }
    }

    // return all KRAUSE to stakers
    function returnFunds() public onlyOwner {               
      for (uint i = 0; i < delegates.length; i++) {
        krause.transfer(delegates[i].addr, delegates[i].stake);

        // SELF DESTRUCT
      }
    }


    ///////////////////////////////
    /// OVERRIDE ERC20 TRANSFERS //
    ///////////////////////////////
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(false, "Cannot transfer delegation.");
        return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(false, "Cannot transfer delegation.");
        return false;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    ////////////////////////////
    // Modifiers ///////////////
    ////////////////////////////
    modifier onlyOwner {
      require(msg.sender == owner, "ONLY OWNER");
      _;
    }

    modifier onlyDelegates {
      // how to check for delegate?
      require(delegateIndex[msg.sender] > 0, "ONLY DELEGATES"); // THIS DOESN'T WORK FOR 0TH INDEX
      _;
    }  

    modifier pastCooldown {
      require(block.number >= delegates[delegateIndex[msg.sender]].depositBlock + cooldownBlocks, "MUST WAIT TILL COOLDOWN");
      _;
    }
}