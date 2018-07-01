# Decentralized-Lottery

This is an implementation of a decentralized lottery on the Ethereum blockchain. The unique with this application is that we did not rely on the hash of the previous block to generate randomness. Instead we generated randomness from the users using a generalized version of Blum Coin Flipping Protocol.

A commit-reveal scheme is introduced to enforce users to provide the contract with randomness. Users upon buying their first token will commit (using the keccak256 function) to a random number. User have 2 days to reveal their commitment. The time is reset every time a new user reveals its commit. If they fail to reveal their commitment the users become invalid and forfeit their stake in the lottery. This is achieved with a reveal function that takes as input the number that user provided number and check if it matches the commitment the user provided upon buying the tokens.

 A crucial observation towards this optimization is that while it ensures a true random seed it suffers from other disadvantages. Namely, in order to execute the lottery function it is required to iterate over the users twice instead of once. As a result the gas associated with executing this function doubles as well.
 
 You can see my article on randomness on Ethereum [here](https://www.vfahub.com/blockchain-obstacles-solutions/)
 
 ## Disclaimer ##
 
 This implementation tries to avoid obvious security leaks such as re-entrancy attacks and under/overflows. However, the contract has only been locally tested.
To use the contract you must acknowledge the risks entailed and respect the LICENCE. Feel free to comment and contribute to improve the contract.
