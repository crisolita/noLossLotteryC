//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract NFTMarket is Initializable {
    using SafeMathUpgradeable for uint256;
    address private admin;
    address private recipientAddress;
    uint256 private fee;
    IERC20Upgradeable public daiToken;
    IERC20Upgradeable public linkToken;
    IERC1155Upgradeable ierc1155;
    AggregatorV3Interface internal priceFeed;
    mapping(address => address) internal chainLinkAddress;

    struct Offer {
        address owner;
        address from;
        uint256 tokenID;
        uint256 amountOfTokens;
        uint256 priceUSD;
        uint256 deadline;
        bool isForSale;
    }
    mapping(uint256 => Offer) public offers;

    event OfferCreated(Offer offer);
    event OfferSold(Offer offer);
    event OfferCancelled(Offer offer);

    function initialize(
        address _admin,
        address _recipientAddress,
        uint256 _fee,
        address _IERC1155,
        address _daiToken,
        address _linkToken
    ) public initializer {
        admin = _admin;
        recipientAddress = _recipientAddress;
        fee = _fee;
        ierc1155 = IERC1155Upgradeable(_IERC1155);

        //daitoken
        daiToken = IERC20Upgradeable(_daiToken);
        chainLinkAddress[
            _daiToken
        ] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
        //linkToken
        linkToken = IERC20Upgradeable(_linkToken);
        chainLinkAddress[
            _linkToken
        ] = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;
        //eth
        chainLinkAddress[
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Access denied.");
        _;
    }

    // the functios to set the fee and the recipient address
    function setFee(uint256 _newFee) public onlyAdmin {
        fee = _newFee;
    }

    function setRecipient(address _newRecipient) public onlyAdmin {
        recipientAddress = _newRecipient;
    }

    function getRecipient() public view returns (address) {
        return recipientAddress;
    }

    function getFee() public view returns (uint256) {
        return fee;
    }

    function getLatestPrice(address _tokenAddress) public returns (int256) {
        priceFeed = AggregatorV3Interface(chainLinkAddress[_tokenAddress]);

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    // Seller will create the offer, passing the ERC1155 token address, token ID, amount of tokens, deadline and the price in USD for all the tokens sold
    function createOffer(
        address _collectionAddress,
        uint256 _id,
        uint256 _amountOfTokens,
        uint256 _price,
        uint256 _deadline
    ) public {
        require(
            _deadline >= block.timestamp,
            "deadline should be in the future."
        );

        require(
            ierc1155.balanceOf(_collectionAddress, _id) >= _amountOfTokens,
            "There are not enough tokens."
        );

        Offer memory offer = Offer(
            msg.sender,
            _collectionAddress,
            _id,
            _amountOfTokens,
            _price,
            _deadline,
            true
        );
        offers[_id] = offer;

        // ierc1155.setApprovalForAll(address(this), true);
        emit OfferCreated(offer);
    }

    function cancelOffer(uint256 _id) public {
        require(offers[_id].isForSale);
        require(msg.sender == offers[_id].owner);
        offers[_id].isForSale = false;

        // ierc1155.setApprovalForAll(address(this), false);
        emit OfferCancelled(offers[_id]);
    }

    function acceptOffer(uint256 _id, address _tokenAddress) public payable {
        Offer memory offer = offers[_id];
        require(msg.sender != offer.owner);
        require(offer.isForSale);
        require(block.timestamp <= offer.deadline);
        address tokenAddress = _tokenAddress;
        //this amount is the amount of the token
        uint256 amount = (10**24 * offer.priceUSD) /
            (uint256(getLatestPrice(tokenAddress)));

        //calculate the amountWithFee

        uint256 amountWithFee = amount.add(amount.div(getFee()));

        //select which one token will to pay

        if (tokenAddress == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value >= amountWithFee, "Insufficient fund");
            payable(offer.owner).transfer(amount);
            if (msg.value > amountWithFee) {
                payable(msg.sender).transfer(msg.value.sub(amountWithFee));
            }

            //send fee to recipient address
            payable(getRecipient()).transfer(amount.div(getFee()));
            //transfer erc1155 tokens
            ierc1155.safeTransferFrom(
                offer.from,
                msg.sender,
                _id,
                offer.amountOfTokens,
                ""
            );
            offer.isForSale = false;
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
            //transfer ERC20 tokens
            require(
                token.balanceOf(msg.sender) >= amountWithFee,
                "insufficient-balance"
            );
            token.transferFrom(msg.sender, offer.owner, amount);

            //send fee to recipient address

            token.transferFrom(
                msg.sender,
                getRecipient(),
                amount.div(getFee())
            );
            //transfer erc1155 tokens
            ierc1155.safeTransferFrom(
                offer.from,
                msg.sender,
                _id,
                offer.amountOfTokens,
                ""
            );
            offer.isForSale = false;
        }
        emit OfferSold(offer);
    }
}
