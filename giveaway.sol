// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Giveaway {
    // Owner of the contract (creator of the giveaway)
    address public owner;

    // Struct to hold the giveaway coupon information
    struct Coupon {
        bool isClaimed;
        uint donationAmount; // Amount donated for the coupon
    }

    // Mapping to store the donations and the coupon details
    mapping(address => uint) public donations; // Address -> Amount donated
    mapping(address => Coupon) public coupons;  // Address -> Coupon details

    // Array to store the donor addresses
    address[] public donorList;

    // Total Ether pool for the giveaway
    uint public totalDonations;

    // Event declaration for donation received
    event DonationReceived(address indexed donor, uint amount, uint totalPool);

    // Event declaration for giveaway winner assignment
    event GiveawayWinnerAssigned(address indexed winner, uint amount);

    // Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // Modifier to ensure that only the winner can withdraw
    modifier onlyWinner(address _winner) {
        require(coupons[_winner].donationAmount > 0, "This address has not won");
        _;
    }

    // Constructor to initialize the contract with the owner
    constructor() {
        owner = msg.sender; // Set the contract creator as the owner
    }

    // Payable function to allow users to donate Ether and generate a coupon
    function donate() external payable {
    require(msg.value > 0, "Donation must be greater than 0");

    // Update donations and total pool
    donations[msg.sender] += msg.value;
    totalDonations += msg.value;

    // Update coupon's donation amount (instead of overwriting)
    coupons[msg.sender].donationAmount += msg.value;

    // Create a new coupon only if it's the first time the user is donating
    if (donations[msg.sender] == msg.value) {
        coupons[msg.sender] = Coupon({
            isClaimed: false,
            donationAmount: msg.value
        });
        donorList.push(msg.sender); // Add sender to donor list if not already present
    }

    // Emit the donation event
    emit DonationReceived(msg.sender, msg.value, totalDonations);
}

    // Only the owner can assign a giveaway winner
    function assignWinner(address _winner) external onlyOwner {
        require(donations[_winner] > 0, "Winner must have donated");
        require(!coupons[_winner].isClaimed, "Coupon already claimed");

        // Emit the event when the winner is assigned
        emit GiveawayWinnerAssigned(_winner, donations[_winner]);
    }

    // Winner can claim their prize (Ether) based on their coupon
    function claimPrize() external onlyWinner(msg.sender) {
        require(!coupons[msg.sender].isClaimed, "Coupon already claimed");

        uint contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to claim");

        // Mark the coupon as claimed
        coupons[msg.sender].isClaimed = true;

        // Transfer all the Ether in the contract to the winner
        payable(msg.sender).transfer(contractBalance);
    }

    // Function to get all the donors who have donated
    function getAllDonors() public view returns (address[] memory) {
        return donorList;
    }
}
