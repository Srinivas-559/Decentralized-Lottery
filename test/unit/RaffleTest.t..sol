//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";


contract RaffleTest is Test { 
  /*Events*/
  event EnteredRaffle(address indexed player);



    Raffle raffle;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
   
    HelperConfig helperConfig;
    
    address public PLAYER = makeAddr("player");//making a dummy address named PLAYER with stream 
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link,
            
            


        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER,STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);//getting the enum value
    }
    //eenter Raffle 
    function testRaffleRevertsWhenYouDontPayEnough() public {
      vm.prank(PLAYER);
      vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
      raffle.enterRaffle();
    }
    function testRaffleRecordsPlayersWhenTheyEnter() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value:entranceFee}();
       address playerRecorded = raffle.getPlayer(0);
       assert(PLAYER == playerRecorded);
    }
    
    
      function testEmitsEventOnEntrance() public  {
      vm.prank(PLAYER);//pretending to be the person who transact 
      vm.expectEmit(true,false,false,false,address(raffle));//this is the expected event from doing the below transaction 
      //In this the first Three parameters are topic or Indexed parameters and 4th is checkdata or Unindexed parameters 
      //and 5th is the address of the emitter (In this the emitter is the raffle contract )
      emit EnteredRaffle(PLAYER);

      //events are not like enumsor variables hence we have to redefine them in our test 
      raffle.enterRaffle{value:entranceFee}();

    }

    //Checking Whether the Raffle is closed when calculating winner
    function testCantEnterWhenRaffleIsCalculating() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value:entranceFee}();
      vm.warp(block.timestamp + interval +1);
      vm.roll(block.number +1 );
      raffle.performUpkeep("");



      vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
      vm.prank(PLAYER);
      raffle.enterRaffle{value:entranceFee}();
    }

    //test for checkUpkeep
    function checkUpkeepReturnsFalseIfIthasNoBalance() public {

      vm.warp(block.timestamp + interval +1);
      vm.roll(block.number +1);
      (bool upkeepNeeded ,) =raffle.checkUpkeep("");
      assert(!upkeepNeeded);
    }
    function testCheckUpkeepReturnFalseIfRaffleNotOpen() public {

      vm.prank(PLAYER);
      raffle.enterRaffle{value:entranceFee}();
      vm.warp(block.timestamp+interval +1);
      vm.roll(block.number +1 );
      raffle.performUpkeep("");
      (bool upkeepNeeded,) = raffle.checkUpkeep("");
      assert(upkeepNeeded == false );


    }
    function testcheckUpkeepReturnsFalseIfEnoughTimeHasNotPassed() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value:entranceFee}();
      vm.warp(block.timestamp+1);
      vm.roll(block.number+1);
      (bool upkeepNeeded,)= raffle.checkUpkeep("");
      assert(upkeepNeeded==false);
    }
    function testcheckUpkeepReturnsTrueIfAllParameterAreGood() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value:entranceFee}();
      vm.warp(block.timestamp+interval+1);
      vm.roll(block.number+1);
      (bool upkeepNeeded,)= raffle.checkUpkeep("");
      assert(upkeepNeeded==true);
    }
    //-----------------------------------------------------------------------------//
    //Testing performUpkeep 

    function testUpkeepRunsOnlyIfCheckUpkeepReturnsTrue() public {
      vm.prank(PLAYER);
      raffle.enterRaffle{value :entranceFee}();
      vm.warp(block.timestamp+interval+1);
      vm.roll(block.number+1);
      raffle.performUpkeep("");

    }
    function testUpkeepRevertsIfCheckUpkeepFails() public {
      uint256 currentBalance = 0;
      uint256 numberOfPlayers =0;
      uint256 s_raffleState = 0;
      vm.expectRevert(
        abi.encodeWithSelector(
          Raffle.Raffle__UpkeepNotNeeded.selector,
          currentBalance,numberOfPlayers,
          s_raffleState)
      );
      raffle.performUpkeep("");
    }

    modifier raffleEnteredAndTimePassed()  {
      vm.prank(PLAYER);
      raffle.enterRaffle{value:entranceFee}();
      vm.warp(block.timestamp+interval+1);
      vm.roll(block.number+1);
      _;  
    }

    function testPerformUpkeepUpdatesRaffleAndEmitsRequestId() public raffleEnteredAndTimePassed {
      vm.recordLogs();
      raffle.performUpkeep("");
      Vm.Log[] memory entries = vm.getRecordedLogs();
      bytes32 requestId = entries[1].topics[1];

      Raffle.RaffleState rState = raffle.getRaffleState();


      assert(uint256(requestId) >0);
      assert(uint256(rState)==1);
    }

    //------------------------------------------------------------------------------------------//
    // Testing Fullfill RandomWords 
    modifier skipFork() {
      if(block.chainid !=31337){
        return ;

      }
      _;
    }


    function testFullfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId

    ) public raffleEnteredAndTimePassed skipFork {
      vm.expectRevert("nonexistent request");
      VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(randomRequestId,address(raffle));
    }


    function testFullfillRandomWordsPicksAWinnerResetsAndSendsMoney () public raffleEnteredAndTimePassed  skipFork{
      uint256 additionalEntrants =5;
      uint256 startingIndex = 1;
      
      for(uint256 i=startingIndex;i<startingIndex+additionalEntrants;i++){

        address player = address(uint160(i));//this will be turned into an address 
        hoax(player,STARTING_USER_BALANCE);
        console.log("player balance ",player.balance);// equivalent to prank + deal functioncalls
        raffle.enterRaffle{value :entranceFee}();
        
    }
    
    
    uint256 prize = entranceFee* (additionalEntrants + 1 );

    vm.recordLogs();
      raffle.performUpkeep("");
      Vm.Log[] memory entries = vm.getRecordedLogs();
      bytes32 requestId = entries[1].topics[1];
    uint256 previousTimeStamp = raffle.getRecentTimeStamp();



    //pretend to be the chainlink vrf 
    VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId),address(raffle));

    //Assert

    assert(uint256(raffle.getRaffleState())==0);
    assert(raffle.getRecentWinner() != address(0) );
    assert(raffle.getLengthOfPlayers()==0);
    // //previousTime Stamp will be taken before performUPKeep And raffle.getRecentTimeStamp is the recorded timestamp after performUpkeep
    assert(previousTimeStamp <raffle.getRecentTimeStamp());
    assert(raffle.getRecentWinner().balance==STARTING_USER_BALANCE+prize-entranceFee);






     
}
}
