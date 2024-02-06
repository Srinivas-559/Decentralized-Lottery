
# Decentralized Lottery Contract


🕹️Lottery Contract :


->This is a decentralized lottery ,offering us more Transparency , Fairness and Security to our funds ...!


->In this contract chainlink VRF and Automation is used to get a Random Number and Automating the Lottery contract for picking the winners.


✅Chainlink VRF(VERIFIABLE RANDOM FUNCTION):
Chainlink VRF allows smart contracts to access a secure source of randomness on the blockchain. This is crucial for applications such as gaming, gambling, and various decentralized finance (DeFi) protocols that require unpredictable and unbiased random numbers.


✅Chainlink Automation :
Chianlink Automation is used to automate the execution of functions based on the triggers like Time Based Trigger , Log Based Trigger and Custom Logic Trigger.


✅Info about the VRF and Automation will be at chainlink Docs.
->Testing and DeployScript is written Using Foundry.


## Deployment



To deploy this project 



1.Set Up Environment Variables




2.Deploy

```solidity
make deploy ARGS="--network sepolia"

```

2.Deploy

```solidity
make deploy ARGS="--network sepolia"

```

3.Register a chainlink AutoMation UpKeep

visit chainlink automation page for subscription


Scripts

```solidity
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value 0.1ether --private-key <PRIVATE_KEY> --rpc-url $SEPOLIA_RPC_URL

```

Create a chain link Subscription :

```solidty
make createSubscription ARGS="--network sepolia"
```






## Environment Variables

To run this project, you will need to add the following environment variables to your .env file

`RPC_URL`

`ETHERSCAN_API_KEY`

`PRIVATE_KEY`


## Thank U
