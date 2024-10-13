// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // Import Strings library

contract HighRollerNFT is ERC721Enumerable, Ownable {
    using Strings for uint256; // Use Strings for uint256 to string conversion

    uint256 public tokenCounter;
    string private baseTokenURI;

    constructor(address initialOwner, string memory _baseTokenURI) ERC721("HighRollerNFT", "HRNFT") Ownable(initialOwner) {
        tokenCounter = 0;
        baseTokenURI = _baseTokenURI; // Set the initial base URI
    }

    // Mint function to allow the vault to mint NFTs
    function mint(address to) external onlyOwner {
        _safeMint(to, tokenCounter);
        tokenCounter++;
    }

    // Override the base URI function to return the baseTokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Allow the owner to set a new base URI
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // Override tokenURI to append token ID to the base URL
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}
