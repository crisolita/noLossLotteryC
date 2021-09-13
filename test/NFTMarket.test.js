const { expect } = require("chai");
const { time, expectRevert, expectEvent } = require("@openzeppelin/test-helpers");
const balance = require("@openzeppelin/test-helpers/src/balance");
const { SupportedAlgorithm } = require("ethers/lib/utils");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const ETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

describe("NFTMarket", function () {
  let market, mockERC1155;

  beforeEach(async function () {
    const [admin,,buyer] = await ethers.getSigners();

    const MockERC1155 = await ethers.getContractFactory("MockERC1155");
    mockERC1155 = await MockERC1155.deploy("uri");
    await mockERC1155.deployed();

    const DaiToken = await ethers.getContractFactory("DaiToken");
    daiToken = await DaiToken.deploy();
    await daiToken.deployed();

    const LinkToken = await ethers.getContractFactory("LinkToken");
    linkToken = await LinkToken.deploy();
    await linkToken.deployed();

    const ChainLink= await ethers.getContractFactory("ChainLink");
    chainLink = await ChainLink.deploy(daiToken.address,linkToken.address);
    await chainLink.deployed()

    const NFTMarket = await ethers.getContractFactory("NFTMarket");
    market = await NFTMarket.deploy();
    await market.deployed();
    market.initialize(admin.address, admin.address, 100, mockERC1155.address, daiToken.address, linkToken.address);


  });
  
  it("recipient can be updated", async function () {
    const [admin, newRecipient] = await ethers.getSigners();
    expect(await market.getRecipient()).to.equals(admin.address);

    await market.setRecipient(newRecipient.address);
    expect(await market.getRecipient()).to.equals(newRecipient.address);
  });

  it("fee can be updated", async function () {
    expect((await market.getFee()).toString()).to.equals("100");

    await market.setFee(200);
    expect((await market.getFee()).toString()).to.equals("200");
  });

  it("only admin can update fee", async function () {
    const [, nonAdmin] = await ethers.getSigners();
    
     await expectRevert(market.connect(nonAdmin).setFee(200),"Access denied.");
  });

  it("only admin can update recipient", async function () {
    const [, nonAdmin] = await ethers.getSigners();

    await expectRevert(
      market.connect(nonAdmin).setRecipient(nonAdmin.address),
      "Access denied."
    );
  });

  it("offers deadline should be in the future", async function () {
    const deadline = (await time.latest()).toNumber();
    const collectionAddress = '0xd07dc4262bcdbf85190c01c996b4c06a461d2430';
    const tokenID = '65678';
    await expectRevert(
      market.createOffer(collectionAddress,tokenID,10, 1000, deadline),
      "deadline should be in the future."
    );
  });

  it("tokens balance should be greater or equals than tokens offered", async function () {
    const [, seller] = await ethers.getSigners();
    const deadline = (await time.latest()).toNumber()+100;
    const tokenID = 2580;
    const sellerBalance = await mockERC1155.balanceOf(seller.address,tokenID)

     expect(sellerBalance.toString()).to.equals("0");
     await expectRevert(
       market.createOffer(seller.address,tokenID,10,100,deadline), "There are not enough tokens."
      );
  })
  it("An offer can be created", async function () {
    const [, seller] = await ethers.getSigners();
    const deadline = (await time.latest()).toNumber()+100;
    const tokenID = 2580;
    const amountOfTokens = 25;

    await mockERC1155.mint(seller.address,tokenID,amountOfTokens,00000000000000000000000000000000000);
    expect(
      (await mockERC1155.balanceOf(seller.address,tokenID)).toString()
    ).to.equals("25");

    await mockERC1155.connect(seller).setApprovalForAll(market.address, true);
    const tx = await market.connect(seller).createOffer(seller.address,tokenID,amountOfTokens,100,deadline);
    const receipt = await tx.wait();

    // NOTE: expectEvent is not working by the time of this writing.
    expect(receipt.events[0].event).to.equals("OfferCreated");

    const [owner,collectionAddress,id,amount,price,_deadline,isSelling] = await market.offers(tokenID);
    expect(owner).to.equals(seller.address);
    expect(collectionAddress).to.equals(seller.address);
    expect(id.toString()).to.equals(tokenID.toString());
    expect(amount.toString()).to.equals(amountOfTokens.toString());
    expect(price.toString()).to.equals("100");
    expect(_deadline.toString()).to.equals(deadline.toString());
    expect(isSelling).to.equals(true);

   
  })
  it("a seller can cancel an offer anytime", async function () {
    const [, seller] = await ethers.getSigners();
    const deadline = (await time.latest()).toNumber()+100;
    const tokenID = 2580;
    const amountOfTokens = 25;
    //mint the tokens
    await mockERC1155.mint(seller.address,tokenID,amountOfTokens,00000000000000000000000000000000000);
    await mockERC1155.connect(seller).setApprovalForAll(market.address, true);

    //create the offer
    await market.createOffer(seller.address,tokenID,25,100,deadline);

    //cancel the offer
    const tx = await market.cancelOffer(tokenID);
    const [owner,collectionAddress,id,amount,price,_deadline,isSelling] = await market.offers(tokenID);

    const receipt = await tx.wait();

    // NOTE: expectEvent is not working by the time of this writing.
    expect(receipt.events[0].event).to.equals("OfferCancelled");
    expect(isSelling).to.equals(false);

  })
  it("the buyer need to accept all the offer, payment with eth", async function () {
    const [, seller, buyer] = await ethers.getSigners();
    const deadline = (await time.latest()).toNumber()+100;
    const tokenID = 2580;
    const amountOfTokens = 25;
    const tokenAddress = ETH;
    const priceforAll = 2000000;
    //mint the tokens
    
    await mockERC1155.mint(seller.address,tokenID,amountOfTokens,00000000000000000000000000000000000);
    await mockERC1155.connect(seller).setApprovalForAll(market.address, true);

    // create the offer
    await market.connect(seller).createOffer(seller.address,tokenID,amountOfTokens,priceforAll,deadline);
    //accept an offer with eth 
    await expectRevert(
      market.connect(buyer).acceptOffer(tokenID,tokenAddress,{value: ethers.utils.parseEther("1")}), "Insufficient fund"
     );

  })
  it("the payment are sent to the seller and the ERC1155 tokens are sent to the buyer, payment with eth", async function () {
    const [, seller, buyer] = await ethers.getSigners();
    const deadline = (await time.latest()).toNumber()+100;
    const tokenID = 2580;
    const amountOfTokens = 25;
    const tokenAddress = ETH;
    const priceforAll = 200;
    //mint the tokens
    
    await mockERC1155.mint(seller.address,tokenID,amountOfTokens,00000000000000000000000000000000000);
    await mockERC1155.connect(seller).setApprovalForAll(market.address, true);

    //verify nfts in both accounts
    const balanceOfNftSellerBefore = await mockERC1155.balanceOf(seller.address,tokenID);
    const balanceOfNftBuyerBefore = await mockERC1155.balanceOf(buyer.address,tokenID);

    expect(balanceOfNftBuyerBefore.toString()).to.equal('0');
    expect(balanceOfNftSellerBefore.toString()).to.equal(amountOfTokens.toString());

    // create the offer
    await market.connect(seller).createOffer(seller.address,tokenID,amountOfTokens,priceforAll,deadline);
   

    const tx = await market.connect(buyer).acceptOffer(tokenID,tokenAddress,{value: ethers.utils.parseEther("1")});
    const receipt = await tx.wait();
    expect(receipt.events[1].event).to.equals("OfferSold");

     //Verify nft balance in both accounts 
     const balanceOfNftBuyer = await mockERC1155.balanceOf(buyer.address,tokenID);
     const balanceOfNftSeller = await mockERC1155.balanceOf(seller.address,tokenID);
 
     expect(balanceOfNftBuyer.toString()).to.equal(amountOfTokens.toString());
     expect(balanceOfNftSeller.toString()).to.equal('0');

  })
  it("the payment have to be sent to the seller and the ERC1155 tokens are sent to the buyer, payment with DAI", async function () {
    const [admin,seller, buyer] = await ethers.getSigners();
    const deadline = (await time.latest()).toNumber()+100;
    const tokenID = 2580;
    const amountOfTokens = 25;
    const tokenAddress = daiToken.address;
    const priceForAll = 1;
    
    //mint the tokens
    
    await mockERC1155.mint(seller.address,tokenID,amountOfTokens,00000000000000000000000000000000000);
    await mockERC1155.connect(seller).setApprovalForAll(market.address, true);

    //verify nfts in both accounts
    const balanceOfNftSellerBefore = await mockERC1155.balanceOf(seller.address,tokenID);
    const balanceOfNftBuyerBefore = await mockERC1155.balanceOf(buyer.address,tokenID);

    expect(balanceOfNftBuyerBefore.toString()).to.equal('0');
    expect(balanceOfNftSellerBefore.toString()).to.equal(amountOfTokens.toString());

    // create the offer
    await market.connect(seller).createOffer(seller.address,tokenID,amountOfTokens,priceForAll,deadline);

    //token to usd
     const usdDai = await chainLink.getLatestPrice(daiToken.address);
     const amount = ethers.BigNumber.from("1").mul(ethers.BigNumber.from("10").pow(ethers.BigNumber.from("24"))).div(ethers.BigNumber.from(usdDai));
     const fee = await market.getFee();
    const amountWithFee= amount.add(amount.div(fee));

    daiToken.transfer(buyer.address,'1000000000000000000000000');
    const balanceBefore = await daiToken.balanceOf(seller.address);
    expect(await balanceBefore.toString()).to.equals('0');
    //approve the tokens
    await daiToken.connect(buyer).approve(market.address,amountWithFee);
    
    
    //accept the offer
    const tx = await market.connect(buyer).acceptOffer(tokenID,tokenAddress);
    const receipt = await tx.wait();
    expect(receipt.events[3].event).to.equals("OfferSold");
    const balanceAfter = await daiToken.balanceOf(seller.address);

    expect(await balanceAfter.toString()).to.equals(amount.toString());
    

     //Verify nft balance in both accounts 
     const balanceOfNftBuyer = await mockERC1155.balanceOf(buyer.address,tokenID);
     const balanceOfNftSeller = await mockERC1155.balanceOf(seller.address,tokenID);
 
     expect(balanceOfNftBuyer.toString()).to.equal(amountOfTokens.toString());
     expect(balanceOfNftSeller.toString()).to.equal('0');

     //verify that the fee was send to recipient address
     const recipient = await market.getRecipient();
     const balanceOfRecipient = await daiToken.balanceOf(recipient);
     
     expect(balanceOfRecipient).to.equal(amount.div(fee));

  })
  it("the payment have to be sent to the seller and the ERC1155 tokens are sent to the buyer, payment with LINK", async function () {
    const [admin, seller, buyer] = await ethers.getSigners();
    const deadline = (await time.latest()).toNumber()+100;
    const tokenID = 2580;
    const amountOfTokens = 25;
    const tokenAddress = linkToken.address;
    const priceForAll = 1;
    
    //mint the tokens
    
    await mockERC1155.connect(admin).mint(seller.address,tokenID,amountOfTokens,0000000000000000000);
    await mockERC1155.connect(seller).setApprovalForAll(market.address, true);
  //verify nfts in both accounts
    const balanceOfNftSellerBefore = await mockERC1155.balanceOf(seller.address,tokenID);
    const balanceOfNftBuyerBefore = await mockERC1155.balanceOf(buyer.address,tokenID);

    expect(balanceOfNftBuyerBefore.toString()).to.equal('0');
    expect(balanceOfNftSellerBefore.toString()).to.equal(amountOfTokens.toString());

    // create the offer
    await market.connect(seller).createOffer(seller.address,tokenID,amountOfTokens,priceForAll,deadline);

    //token to usd
     const usdDai = await chainLink.getLatestPrice(linkToken.address);
     const amount = ethers.BigNumber.from(priceForAll).mul(ethers.BigNumber.from("10").pow(ethers.BigNumber.from("24"))).div(ethers.BigNumber.from(usdDai));
     const fee = await market.getFee();
    const amountWithFee= amount.add(amount.div(fee));
    // transfer tokens
    linkToken.transfer(buyer.address,'1000000000000000000000000');
    const balanceBefore = await linkToken.balanceOf(seller.address);
    expect(await balanceBefore.toString()).to.equals('0');

    //approve the tokens
    await linkToken.connect(buyer).approve(market.address,(amountWithFee).toString());
    
    
    //accept the offer
    const tx = await market.connect(buyer).acceptOffer(tokenID,tokenAddress);
    const receipt = await tx.wait();
    expect(receipt.events[3].event).to.equals("OfferSold");
    
    const balanceAfter = await linkToken.balanceOf(seller.address);
    expect(await balanceAfter.toString()).to.equals(amount.toString());
    
    //Verify nft balance in both accounts 
    const balanceOfNftBuyer = await mockERC1155.balanceOf(buyer.address,tokenID);
    const balanceOfNftSeller = await mockERC1155.balanceOf(seller.address,tokenID);

    expect(balanceOfNftBuyer.toString()).to.equal(amountOfTokens.toString());
    expect(balanceOfNftSeller.toString()).to.equal('0');

    //verify that the fee was send to recipient address
    const recipient = await market.getRecipient();
    const balanceOfRecipient = await linkToken.balanceOf(recipient);
    
    expect(balanceOfRecipient).to.equal(amount.div(fee));


  })
});