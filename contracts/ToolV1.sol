//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ToolV1 is Initializable {
    using SafeMathUpgradeable for uint256;
    address private owner;
    IUniswapV2Router02 private uniRouter;

    function initialize(address _owner) public initializer {
        owner = _owner;
        uniRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }

    /**
      Swap ETH for DAI and USDT based on percentages array.
    */
    function swap(uint256[] memory percentages) public payable {
        require(
            percentages.length == 2 && percentages[0] + percentages[1] == 100,
            "exchange percentages should be of size 2 to and equals to 100"
        );

        uint256[] memory partsSplitted = splitETH(percentages);
        address[] memory DAIPath = getPathOfEthToToken(
            0x6B175474E89094C44Da98b954EedeAC495271d0F
        );
        address[] memory USDTPath = getPathOfEthToToken(
            0xdAC17F958D2ee523a2206206994597C13D831ec7
        );

        swapETHToToken(partsSplitted[0], DAIPath);
        swapETHToToken(partsSplitted[1], USDTPath);
        payable(owner).transfer(getFee() * (1 wei));
    }

    function getFee() private returns (uint256) {
        return msg.value.div(1000);
    }

    function splitETH(uint256[] memory parts)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory amountOfEtherForTokens = new uint256[](2);
        uint256 totalAmountOfEther = msg.value.sub(getFee());

        amountOfEtherForTokens[0] = totalAmountOfEther.mul(parts[0]).div(100);
        amountOfEtherForTokens[1] = totalAmountOfEther.mul(parts[1]).div(100);
        return amountOfEtherForTokens;
    }

    function getPathOfEthToToken(address tokenAddress)
        private
        view
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = uniRouter.WETH();
        path[1] = tokenAddress;
        return path;
    }

    function swapETHToToken(uint256 ETHAmount, address[] memory path)
        private
        returns (uint256[] memory amounts)
    {
        uint256 deadline = block.timestamp + 15;

        return
            uniRouter.swapExactETHForTokens{value: ETHAmount}(
                0,
                path,
                msg.sender,
                deadline
            );
    }
}
