// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PaymentRegister {
    struct Person {
        string name;
        string surname;
        address walletAddress;
    }

    struct Payment {
        address sender;
        address receiver;
        uint amount;
        uint timestamp;
    }

    Person[] people;
    Payment[] paymentHistory;

    AggregatorV3Interface internal priceFeed;

    constructor() {
        // ETH/USD (Kovan Testnet)
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    function GetLatestPriceEthUsd() private view returns (uint256, uint8) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return (uint256(price), decimals);
    }

    function GetMyBalanceInUsd() public view returns(uint256, uint8){

        //1 ETH = 10^9 Gwei
        //uint256 price = 160010000000;
        //uint8 decimals = 8;

        (uint256 price, uint8 decimals) = GetLatestPriceEthUsd();

        uint256 priceInCents = price / (10**(decimals-2));

        uint256 onlyEthBalance = msg.sender.balance / 1 ether;
        uint256 leftBalanceInCents = priceInCents * onlyEthBalance;


        uint256 leftBalanceInGwei = onlyEthBalance * (10**9);
        uint256 balanceInGwei = msg.sender.balance / 1 gwei;

        uint256 rightBalanceInGwei = balanceInGwei - leftBalanceInGwei;
        uint256 rightBalanceInCents = (priceInCents * rightBalanceInGwei) / (10**9);

        uint256 balanceInCents = leftBalanceInCents + rightBalanceInCents;

        return (balanceInCents, 2);
    }

    function GetPeople() public view returns (Person[] memory) { return people; }

    function GetPaymentHistory() public view returns (Payment[] memory) { return paymentHistory; }

    function SearchPersonBySurname(string memory surname) public view returns (address) {
        uint256 numberOfPeople = people.length;
        address _address;

        for(uint i=0; i < numberOfPeople; i++)
             if(compareStrings(people[i].surname, surname))
             {
                _address = people[i].walletAddress;
                return _address;
             }

        return _address;
    }

    function IsPersonExists(address walletAddress) public view returns (bool) {      
        uint256 numberOfPeople = people.length;

        for(uint i=0; i < numberOfPeople; i++)
            if(people[i].walletAddress == walletAddress) return true;

        return false;
    }

    function SendPayment(address payable _receiver) public payable {
        require(IsPersonExists(msg.sender), "You have to registered on people list.");

        (bool sent, bytes memory data) = _receiver.call{value: msg.value}("");

        require(sent, "Failed to send Ether");
        
        paymentHistory.push(Payment(msg.sender, _receiver, msg.value, block.timestamp));
    }

    function AddPerson(string memory name, string memory surname, address walletAddress) public {
        people.push(Person(name, surname, walletAddress));
    }

    function RemovePerson(address walletAddress) public {
        uint256 numberOfPeople = people.length;
        for(uint i=0; i < numberOfPeople; i++)
        {
            if(people[i].walletAddress == walletAddress) {
                people[i] = people[numberOfPeople - 1];
                people.pop();
                return;
            }
        }
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}