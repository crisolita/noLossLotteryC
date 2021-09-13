//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface CurveDefiSwap {
    function exchange(
        int128 from,
        int128 to,
        uint256 amount,
        uint256 minAmount
    ) external;

    function get_dy(
        int128 from,
        int128 to,
        uint256 amount
    ) external view returns (uint256);

    //info from pools
    function balances(int128 i) external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    // DAI=0
    //USDC=1
    //USDT=2
}

contract Lottery is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    mapping(uint256 => bool) isSold;
    mapping(address => address) internal chainLinkAddress;
    mapping(uint256 => address) internal ticketOwners;

    address internal ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address internal TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;

    uint256 internal ticketPriceUSD = 100;
    //interfaces
    AggregatorV3Interface internal priceFeed;
    IERC20Upgradeable erc20;
    CurveDefiSwap swapCurve;

    function initialize() public initializer {
        //Curve Swap
        swapCurve = CurveDefiSwap(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
        //daitoken
        chainLinkAddress[DAI] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

        //eth
        chainLinkAddress[ETH] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

        //usdt
        chainLinkAddress[USDT] = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
        //usdc
        chainLinkAddress[USDC] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
        //busd
        chainLinkAddress[BUSD] = 0x833D8Eb16D306ed1FbB5D7A2E019e106B960965A;
        //TUsd
    }

    function getLatestPrice(address _tokenAddress) public returns (int256) {
        priceFeed = AggregatorV3Interface(chainLinkAddress[_tokenAddress]);

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function swapToDAI(
        address tokenAddress,
        int128 from,
        uint256 amount
    ) public {
        address fromAddress = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
        erc20 = IERC20Upgradeable(tokenAddress);
        erc20.safeApprove(fromAddress, amount);
        swapCurve.exchange(from, 0, amount, 1);
    }

    function buyTicket(address tokenAddress, uint256 ticketNumber)
        public
        payable
    {
        require(!isSold[ticketNumber], "This number is already sold");
        require(ticketNumber <= 1000 && ticketNumber >= 1);

        uint256 amount = (10**24 * ticketPriceUSD) /
            (uint256(getLatestPrice(tokenAddress)));

        if (tokenAddress == ETH) {
            require(msg.value >= amount, "There are not enough funds.");

            isSold[ticketNumber] = true;
        } else {
            erc20 = IERC20Upgradeable(tokenAddress);
            require(
                erc20.balanceOf(msg.sender) >= ticketPriceUSD,
                "There are not enough tokens."
            );
            //erc20.transferFrom(msg.sender, address(this), amount);
        }
    }
}
