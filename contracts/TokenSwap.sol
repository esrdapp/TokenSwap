// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SQUIRT.sol";
import "./SQUIRTSWAP.sol";

// this contract should be deployed after the deployment of the two contracts TokenABC and TokenXYZ
// as instrcuted in the 2_deploy_contracts file
contract TokenSwap {
    address payable admin;
    //ratioAX is the percentage of how much TokenA is worth of TokenX
    uint256 ratioAX;
    bool AcheaperthenX;
    uint256 fees;
    TokenABC public squirt;
    TokenXYZ public squirtswap;

    constructor(address _squirt, address _squirtswap) {
        admin = payable(msg.sender);
        tokenABC = Squirt(_squirt);
        tokenXYZ = Squirtswap(_squirtswap);
        //due to openzeppelin implementation, transferFrom function implementation expects _msgSender() to be the beneficiary from the caller
        // but in this use cae we are using this contract to transfer so its always checking the allowance of SELF
        squirt.approve(address(this), squirt.totalSupply());
        squirtswap.approve(address(this), squirtswap.totalSupply());
    }

    modifier onlyAdmin() {
        payable(msg.sender) == admin;
        _;
    }

    function setRatio(uint256 _ratio) public onlyAdmin {
        ratioAX = _ratio;
    }

    function getRatio() public view onlyAdmin returns (uint256) {
        return ratioAX;
    }

    function setFees(uint256 _Fees) public onlyAdmin {
        fees = _Fees;
    }

    function getFees() public view onlyAdmin returns (uint256) {
        return fees;
    }

    // accepts amount of Squirt and exchenge it for SquirtSwap, vice versa with function swapTKX
    // transfer squirt from sender to smart contract after the user has approved the smart contract to
    // withdraw amount TKA from his account, this is a better solution since it is more open and gives the
    // control to the user over what calls are transfered instead of inspecting the smart contract
    // approve the caller to transfer one time from the smart contract address to his address
    // transfer the exchanged squirtswap to the sender
    function swapTKA(uint256 amountTKA) public returns (uint256) {
        //check if amount given is not 0
        // check if current contract has the necessary amout of Tokens to exchange
        require(amountTKA > 0, "amountTKA must be greater then zero");
        require(
            squirt.balanceOf(msg.sender) >= amountTKA,
            "sender doesn't have enough Tokens"
        );

        uint256 exchangeA = uint256(mul(amountTKA, ratioAX));
        uint256 exchangeAmount = exchangeA -
            uint256((mul(exchangeA, fees)) / 100);
        require(
            exchangeAmount > 0,
            "exchange Amount must be greater then zero"
        );

        require(
            squirtswap.balanceOf(address(this)) > exchangeAmount,
            "currently the exchange doesnt have enough Squirtswap Tokens, please retry later :=("
        );

        squirt.transferFrom(msg.sender, address(this), amountTKA);
        squirtswap.approve(address(msg.sender), exchangeAmount);
        squirtswap.transferFrom(
            address(this),
            address(msg.sender),
            exchangeAmount
        );
        return exchangeAmount;
    }

    function swapTKX(uint256 amountTKX) public returns (uint256) {
        //check if amount given is not 0
        // check if current contract has the necessary amout of Tokens to exchange and the sender
        require(amountTKX >= ratioAX, "amountTKX must be greater then ratio");
        require(
            tsquirtswap.balanceOf(msg.sender) >= amountTKX,
            "sender doesn't have enough Tokens"
        );

        uint256 exchangeA = amountTKX / ratioAX;
        uint256 exchangeAmount = exchangeA - ((exchangeA * fees) / 100);

        require(
            exchangeAmount > 0,
            "exchange Amount must be greater then zero"
        );

        require(
            squirt.balanceOf(address(this)) > exchangeAmount,
            "currently the exchange doesnt have enough SquirtSwap Tokens, please retry later :=("
        );
        squirtswap.transferFrom(msg.sender, address(this), amountTKX);
        squirt.approve(address(msg.sender), exchangeAmount);
        squirt.transferFrom(
            address(this),
            address(msg.sender),
            exchangeAmount
        );
        return exchangeAmount;
    }

    //leting the Admin of the TokenSwap to buyTokens manually is preferable and better then letting the contract
    // buy automatically tokens since contracts are immutable and in case the value of some tokens beomes
    // worthless its better to not to do any exchange at all
    function buyTokensABC(uint256 amount) public payable onlyAdmin {
        squirt.buyTokens{value: msg.value}(amount);
    }

    function buyTokensXYZ(uint256 amount) public payable onlyAdmin {
        squirtswap.buyTokens{value: msg.value}(amount);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}
