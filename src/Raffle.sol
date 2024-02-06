//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;
import {VRFCoordinatorV2Interface}  from  "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
/**
 * @title A Sample Raffle Contract
 * @author G Srinivas 
 * @notice This contract is for creating a sample raffle 
 * @dev Implements Chainlinks -VRFv2
 */
contract Raffle is VRFConsumerBaseV2{

    //Errors 
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance ,uint256 numPlayers,uint256 Raffle_State);
    enum RaffleState{
        OPEN,
        CALCULATING
    }

    //constants 
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS =1 ; 

    //Immutables 
    uint256 private  immutable  i_entranceFee;
    //@dev duration of the lottery in seconds 
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator ;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    //Storage Variables 
    address private s_recentWinner ;
    address payable[] private s_players;
    uint256 private  s_lastTimeStamp;
    RaffleState private s_raffleState;

    //Events 
    event EnteredRaffle(address indexed player );
    event PickedWinner(address indexed winner);
    event RequestedWinner(uint256 indexed reqId);
    
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane ,
        uint64 subscriptionId,
        uint32 callbackGasLimit
        )VRFConsumerBaseV2(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = interval ;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator=VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane=gasLane;
        i_subscriptionId=subscriptionId;
        i_callbackGasLimit=callbackGasLimit;
        s_raffleState=RaffleState.OPEN;

    }


    function enterRaffle() external  payable {
        if(s_raffleState == RaffleState.CALCULATING){
            revert Raffle__RaffleNotOpen();
        }
        // require(msg.value >=i_entranceFee,"Not Enough Eth Sent ");
        if(msg.value<i_entranceFee){
            revert Raffle__NotEnoughEthSent();           
        }
        s_players.push(payable(msg.sender));
        //makes migration easier 
        //Makes Front End Easier 
        emit EnteredRaffle(msg.sender);


    } 
    /**
     * @dev this function is called by chainlink automation nodes 
     * to see if time to perform  an upKeep
     * The following should be true for this to return true 
     * 1.The time interval has passed between raffle runs 
     * 2.The raffle is in OPEN State
     * 3.The contract has ETH
     * 4.(Implicit) Subscription is funded with LINK
     */
    //checkUpkeep-Used to check all the conditions specified to perform upKeep
    function checkUpkeep(bytes memory /*checkData*/) public view returns (bool upkeepNeeded,bytes memory /*performData*/) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance >0;
        bool hasPlayers = s_players.length>0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers );
        return (upkeepNeeded,"0x0");
    }

    //performUpkeep is  used call the vrf automatically after the conditions are true
    function performUpkeep(bytes calldata /* performData */) external  {
       (bool upkeepNeeded,) = checkUpkeep("");
       if(!upkeepNeeded){
        revert Raffle__UpkeepNotNeeded(
            address(this).balance,
            s_players.length,
            uint256(s_raffleState)
        );
       }
        //check whther enough time has passed 
        
        s_raffleState = RaffleState.CALCULATING;
        
        //chainLink VRF is a 2 transaction process 
        //1.request the RNG
        //2.Get a Random Number
          uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedWinner(requestId);


    }
    //1.Get a Random Number 
    //2.Use a Random Number to pick a player 
    //3.Be automatically called 
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory RandomWords
        ) internal override{
            //Checks 


            //Effects(Our own contract)
            uint256 indexOfWinner = RandomWords[0]%s_players.length;
            address payable winner = s_players[indexOfWinner];
            s_recentWinner = winner;
            s_raffleState = RaffleState.OPEN;
            s_players = new address payable[](0);
            s_lastTimeStamp = block.timestamp;

            //Interactions(Other Contracts)
            emit PickedWinner(winner);
            (bool success,) = winner.call{value:address(this).balance}("");
            if(!success){
                revert Raffle__TransferFailed();
            }

    }


    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }
    function getRaffleState() public view returns(RaffleState) {
        return s_raffleState;
    }
    function getPlayer(uint256 indexOfPlayer) external view returns(address) {
        return s_players[indexOfPlayer];

    }
    function getRecentWinner() external view returns(address) {
        return s_recentWinner;

    }
    function getLengthOfPlayers() external view returns(uint256) {
        return s_players.length;

    }
    function getRecentTimeStamp() external view returns(uint256){
        return s_lastTimeStamp;

    }

}
