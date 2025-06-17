// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

//1.deploy mocks when we are on a local anvil chain
//2.keep track of contract address acroos different chains
//3.Sepolia ETH/USD
//4.Mainnet ETH/USD

contract HelperConfig is Script {

    NetworkConfg public activeNetworkConfig;

    uint8 public constant DECIMALS=8;
    int256 public constant INITIAL_PRICE=2000e8;

    //if we are on a local anvil, we deploy mocks
    //otherwise, grab the existing address from the live network
    struct NetworkConfg{
        address priceFeed;  //ETH/USD price feed address
        
    }

    constructor(){
        if(block.chainid ==11155111){
            activeNetworkConfig=getSepoliaEthConfig();
        }else {
            activeNetworkConfig=getOrCreateAnvilEthConfig();
        }
    
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfg memory){
        NetworkConfg memory sepoliaConfig= NetworkConfg({priceFeed:0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfg memory){

        if (activeNetworkConfig.priceFeed != address(0)){
            return activeNetworkConfig;
            
        }

        //1. deploy the mocks 
        //2.return the mock address
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed= new MockV3Aggregator(DECIMALS,INITIAL_PRICE);

        vm.stopBroadcast();

        NetworkConfg memory anvilConfig= NetworkConfg({priceFeed:address(mockPriceFeed)});

        return anvilConfig;
    }
    
}