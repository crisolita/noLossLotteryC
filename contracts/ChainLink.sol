// //SPDX-License-Identifier: Unlicense
// pragma solidity ^0.8.0;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";4
// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


// contract ChainLink is VRFConsumerBase {
//     mapping(address => address) internal chainLinkAddress;
//     bytes32 internal keyHash;
//     uint256 internal fee;
    
//     uint256 public randomResult;
//     constructor(address _daiToken, address _linkToken) {

//          VRFConsumerBase(
//             0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
//             0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
//         ) public
//     {
//         keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
//         fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
//     }

//     function getRandomNumber() public returns (bytes32 requestId) {
//         require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
//         return requestRandomness(keyHash, fee);
//     }

//     /**
//      * Callback function used by VRF Coordinator
//      */
//     function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
//         randomResult = randomness;
//     }

//     // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
// }


//         //daitoken
//         chainLinkAddress[
//             _daiToken
//         ] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
//         //linkToken
//         chainLinkAddress[
//             _linkToken
//         ] = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;
//         //eth
//         chainLinkAddress[
//             0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
//         ] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
//     }

//     function getLatestPrice(address _tokenAddress)
//         public
//         view
//         returns (int256)
//     {
//         AggregatorV3Interface priceFeed = AggregatorV3Interface(
//             chainLinkAddress[_tokenAddress]
//         );
//         (, int256 price, , , ) = priceFeed.latestRoundData();
//         return price;
//     }
// }
