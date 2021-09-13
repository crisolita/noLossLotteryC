const { expect } = require("chai");
const { time, expectRevert, expectEvent } = require("@openzeppelin/test-helpers");
const balance = require("@openzeppelin/test-helpers/src/balance");
const { SupportedAlgorithm } = require("ethers/lib/utils");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const ETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

const ABI = [
  {
    constant: true,
    inputs: [
      {
        name: "_owner",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        name: "balance",
        type: "uint256",
      },
    ],
    payable: false,
    type: "function",
  },
];

const DAI_CONTRACT = new ethers.Contract(
  "0x6B175474E89094C44Da98b954EedeAC495271d0F",
  ABI,
  ethers.provider
);
const USDT_CONTRACT = new ethers.Contract(
  "0xdAC17F958D2ee523a2206206994597C13D831ec7",
  ABI,
  ethers.provider
);


describe("Lotery", function () {
  let lottery,toolV1;

  before(async function () {
    const [admin,buyer] = await ethers.getSigners();

    const Lottery = await ethers.getContractFactory("Lottery");
    lottery = await Lottery.deploy();
    await lottery.deployed();

    const ToolV1 = await ethers.getContractFactory("ToolV1");
    toolV1 = await ToolV1.deploy();
    await toolV1.deployed();
  

    lottery.initialize();

    toolV1.initialize(admin.address);

  });
  
  it("An user cannot buy a ticket that is already purchased ", async function () {
    const [admin] = await ethers.getSigners();
    await lottery.buyTicket(ETH,10,{value: ethers.utils.parseEther("1")});
    await expectRevert(lottery.buyTicket(ETH,10,{value: ethers.utils.parseEther("1")}),"This number is already sold");
  });

  it("if an user pay with USDT swap USDT to DAI", async function () {
    const [admin, buyer] = await ethers.getSigners();
    await toolV1.connect(buyer).swap([10,90],{value: ethers.utils.parseEther("2")});
//6744598640 en usdt 
    await lottery.connect(buyer).swapToDAI(USDT,1,100*10**6);
    // const balance = await USDT_CONTRACT.balanceOf(buyer.address);
    // console.log(balance.toString());
  });
  
});