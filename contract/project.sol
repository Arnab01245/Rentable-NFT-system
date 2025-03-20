// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RentableNFT {

    // NFT structure to store owner and metadata (URI)
    struct NFT {
        address owner;
        string tokenURI;
    }

    // Rental structure to store rent information
    struct Rental {
        address renter;
        uint256 rentPricePerDay;
        uint256 rentalStart;
        uint256 rentalEnd;
    }

    uint256 public nextTokenId;
    mapping(uint256 => NFT) public nfts;
    mapping(uint256 => Rental) public rentals;
    mapping(address => uint256[]) public userNFTs; // Mapping of user to their NFTs

    event NFTMinted(uint256 tokenId, address owner, string tokenURI);
    event NFTRented(uint256 tokenId, address renter, uint256 rentalStart, uint256 rentalEnd);
    event NFTReturned(uint256 tokenId);

    // Modifier to check if the sender is the owner of the NFT
    modifier onlyOwner(uint256 tokenId) {
        require(nfts[tokenId].owner == msg.sender, "Not the owner of this NFT");
        _;
    }

    // Modifier to check if the sender is the renter of the NFT
    modifier onlyRenter(uint256 tokenId) {
        require(rentals[tokenId].renter == msg.sender, "Not the renter of this NFT");
        _;
    }

    // Mint a new NFT
    function mintNFT(address to, string memory metadataURI) public {
        uint256 tokenId = nextTokenId;
        nextTokenId++;

        nfts[tokenId] = NFT({
            owner: to,
            tokenURI: metadataURI
        });

        userNFTs[to].push(tokenId);

        emit NFTMinted(tokenId, to, metadataURI);
    }

    // Set rental information for an NFT
    function setRentalInfo(uint256 tokenId, uint256 rentPricePerDay) public onlyOwner(tokenId) {
        rentals[tokenId] = Rental({
            renter: address(0),
            rentPricePerDay: rentPricePerDay,
            rentalStart: 0,
            rentalEnd: 0
        });
    }

    // Rent an NFT
    function rentNFT(uint256 tokenId, uint256 rentalDurationInDays) public payable {
        Rental storage rental = rentals[tokenId];

        // Ensure NFT is not already rented
        require(rental.renter == address(0), "NFT already rented");

        uint256 totalRentPrice = rental.rentPricePerDay * rentalDurationInDays;
        require(msg.value >= totalRentPrice, "Insufficient payment");

        rental.renter = msg.sender;
        rental.rentalStart = block.timestamp;
        rental.rentalEnd = block.timestamp + rentalDurationInDays * 1 days;

        emit NFTRented(tokenId, msg.sender, rental.rentalStart, rental.rentalEnd);
    }

    // Return rented NFT
    function returnNFT(uint256 tokenId) public onlyRenter(tokenId) {
        Rental storage rental = rentals[tokenId];

        // Ensure the rental period has ended
        require(block.timestamp >= rental.rentalEnd, "Rental period not over yet");

        // Return the NFT
        rental.renter = address(0);
        rental.rentalStart = 0;
        rental.rentalEnd = 0;

        emit NFTReturned(tokenId);
    }

    // Get NFTs owned by a user
    function getUserNFTs(address user) public view returns (uint256[] memory) {
        return userNFTs[user];
    }

    // Withdraw contract balance to the owner (NFT contract deployer)
    function withdraw() public {
        // Ensure the caller is the owner of the contract (simplified for the example)
        require(msg.sender == nfts[0].owner, "Only the contract owner can withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    // Get the owner of an NFT
    function ownerOf(uint256 tokenId) public view returns (address) {
        return nfts[tokenId].owner;
    }

    // Get the token URI of an NFT
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return nfts[tokenId].tokenURI;
    }

    // Helper function to get rental information of an NFT
    function getRentalInfo(uint256 tokenId) public view returns (address renter, uint256 rentPricePerDay, uint256 rentalStart, uint256 rentalEnd) {
        Rental storage rental = rentals[tokenId];
        return (rental.renter, rental.rentPricePerDay, rental.rentalStart, rental.rentalEnd);
    }
}
