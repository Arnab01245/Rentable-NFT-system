// Make sure you have web3.js installed and connected to the Ethereum network

const web3 = new Web3(window.ethereum); // Using MetaMask or any provider
const contractAddress = 'YOUR_CONTRACT_ADDRESS'; // Replace with your smart contract address
const abi = [ /* Your contract ABI here */ ]; 

const nftContract = new web3.eth.Contract(abi, contractAddress);

let accounts;

// Connect to MetaMask and get the user's account
async function connectWallet() {
    accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    document.getElementById("wallet-status").innerText = `Connected: ${accounts[0]}`;
}

// Fetch available NFTs for rent from the smart contract
async function fetchNFTs() {
    try {
        const totalNFTs = await nftContract.methods.totalSupply().call();
        const nftCardsContainer = document.getElementById('nft-cards');
        nftCardsContainer.innerHTML = '';

        for (let i = 0; i < totalNFTs; i++) {
            const nft = await nftContract.methods.nfts(i).call();
            const card = document.createElement('div');
            card.classList.add('nft-card');
            
            const nftImage = nft.imageUrl || "default-image.png";  // Placeholder image
            const nftName = nft.name || "NFT Name";
            const nftDescription = nft.description || "NFT Description";

            card.innerHTML = `
                <img src="${nftImage}" alt="${nftName}">
                <div class="nft-details">
                    <h3>${nftName}</h3>
                    <p>${nftDescription}</p>
                    <button onclick="rentNFT(${i})">Rent This NFT</button>
                </div>
            `;
            nftCardsContainer.appendChild(card);
        }
    } catch (error) {
        console.error("Error fetching NFTs:", error);
    }
}

// Rent NFT functionality
async function rentNFT(nftId) {
    try {
        const rentalDuration = prompt("Enter rental duration in days:");
        const rentPrice = await nftContract.methods.getRentPrice(nftId).call();
        
        const totalPrice = rentPrice * rentalDuration;
        const accounts = await web3.eth.getAccounts();

        // Approve and rent the NFT
        await nftContract.methods.rentNFT(nftId, rentalDuration)
            .send({ from: accounts[0], value: totalPrice });

        alert("NFT rented successfully!");
    } catch (error) {
        console.error("Error renting NFT:", error);
    }
}

// Handle form submission
document.getElementById('rental-form').addEventListener('submit', async (event) => {
    event.preventDefault();

    const nftId = document.getElementById('nftId').value;
    const rentalDuration = document.getElementById('rentalDuration').value;

    rentNFT(nftId, rentalDuration);
});

// Initialize the app
async function init() {
    await connectWallet();
    await fetchNFTs();
}

window.onload = init;
