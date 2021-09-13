//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainLink {
    mapping(address => address) internal chainLinkAddress;

    constructor(address _daiToken, address _linkToken) {
        //daitoken
        chainLinkAddress[
            _daiToken
        ] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
        //linkToken
        chainLinkAddress[
            _linkToken
        ] = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;
        //eth
        chainLinkAddress[
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    }

    function getLatestPrice(address _tokenAddress)
        public
        view
        returns (int256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            chainLinkAddress[_tokenAddress]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}
