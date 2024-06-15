// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
error NotOwner();
contract FundMe{
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    constructor(){
        i_owner = msg.sender;
    }

    function fund() public payable{
        require(msg.value.getConversionRate() >= MINIMUM_USD, "Didn't send enough");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256){
        // ETH/USD price feed address of Sepolia Network.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }

    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    function withdraw() public onlyOwner {
        /* starting index, ending index, stop amount */
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder]=0;
        }

        funders = new address[](0);
        //payable(msg.sender).transfer(address(this).balance);

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");


    }


     fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

}