// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import 'hardhat/console.sol';

contract OwnableAndWhitelistble {
    address public owner;
    mapping(address => bool) internal whitelist;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WhitelistAdded(address indexed sender, address indexed whitelistUser);
    event WhitelistRemoved(address indexed sender, address indexed whitelistUser);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), 'You cant transfer ownerships to address 0x0');
        require(newOwner != owner, 'You cant transfer ownerships to yourself');
        emit OwnershipTransferred(owner, newOwner);
        whitelist[owner] = false;
        whitelist[newOwner] = true;
        owner = newOwner;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], 'Only whitelist users can call this function');
        _;
    }

    function addToWhitelist(address newWhitelistUser) external onlyOwner {
        require(newWhitelistUser != address(0), 'You cant add to whitelist address 0x0');
        emit WhitelistAdded(msg.sender, newWhitelistUser);
        whitelist[newWhitelistUser] = true;
    }

    function removeFromWhitelist(address newWhitelistUser) external onlyOwner {
        require(whitelist[newWhitelistUser], 'You cant remove from whitelist');
        emit WhitelistRemoved(msg.sender, newWhitelistUser);
        whitelist[newWhitelistUser] = false;
    }
}

contract CocktailNFT is ERC721, OwnableAndWhitelistble {
    string public _name = 'Cocktail NFT';
    string public _symbol = 'COCK';

    uint256 public tokenCounter;

    string[] public rarities;
    mapping(string => bool) public isValidRarity;

    mapping(string => string[]) public defaultCocktails;
    mapping(string => uint256) public defaultPrice;

    mapping(string => string[]) public specialCocktails;
    mapping(string => SpecialCockailInfo) public specialCocktailsInfo;

    mapping(uint256 => CocktailInfo) public cocktailsInfo;

    struct SpecialCockailInfo {
        uint256 numenator;
        uint256 denominator;
        uint256 bonus;
        uint256 total;
    }

    struct CocktailInfo {
        uint256 price;
        string rarity;
        string tokenURI;
    }

    event Minted(address to, string rarity, string tokenURI);

    constructor() ERC721(_name, _symbol) {
        tokenCounter = 0;
        owner = msg.sender;
        whitelist[msg.sender] = true;

        setDefaultPrice('Gold', 50);
        setDefaultPrice('Silver', 20);
        setDefaultPrice('Bronze', 5);

        setSpecialCocktailInfo('Gold', 10, 1, 100, 0);
        setSpecialCocktailInfo('Silver', 10, 1, 100, 0);
        setSpecialCocktailInfo('Bronze', 10, 1, 100, 0);
    }

    function mintCustom(
        address to,
        string memory rarity,
        uint256 amount
    ) public onlyWhitelist {
        require(isValidRarity[rarity], 'Illegal rarity');

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = tokenCounter;
            _safeMint(to, tokenId);

            uint256 randomSpecial = randomInt(
                0,
                specialCocktailsInfo[rarity].denominator + specialCocktailsInfo[rarity].total,
                tokenId
            );
            uint256 randomIndex = randomInt(0, defaultCocktails[rarity].length, tokenId);
            string memory tokenURI_ = defaultCocktails[rarity][randomIndex];
            uint256 price = defaultPrice[rarity];

            setCocktailInfo(tokenId, rarity, tokenURI_, price);
            emit Minted(to, rarity, tokenURI_);

            // if (randomSpecial > specialCocktailsInfo[rarity].numenator) {
                
            // } else {
                // uint256 randomIndex = randomInt(0, specialCocktails[rarity].length, tokenId);
                // string memory tokenURI_ = specialCocktails[rarity][randomIndex];
                // uint256 price = defaultPrice[rarity] * specialCocktailsInfo[rarity].bonus;
                // specialCocktailsInfo[rarity].total++;

                // setCocktailInfo(tokenId, rarity, tokenURI_, price);
                // tokenCounter++;
                // emit Minted(to, rarity, tokenURI_);
            // }
            tokenCounter++;
        }
    }

    function burn(uint256 tokenId) public {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        require(_isApprovedOrOwner(msg.sender, tokenId), 'Burning is not allowed for not owner');
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return cocktailsInfo[tokenId].tokenURI;
    }

    function getPrice(uint256 tokenId) external view returns (uint256 price) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return cocktailsInfo[tokenId].price;
    }

    function getRarity(uint256 tokenId) external view returns (string memory rarity) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return cocktailsInfo[tokenId].rarity;
    }

    function setCocktailInfo(
        uint256 tokenId,
        string memory rarity,
        string memory tokenURI_,
        uint256 price
    ) internal {
        require(_exists(tokenId), 'ERC721Metadata: URI set of nonexistent token');
        cocktailsInfo[tokenId].rarity = rarity;
        cocktailsInfo[tokenId].tokenURI = tokenURI_;
        cocktailsInfo[tokenId].price = price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return '';
    }

    function addDefaultCocktail(string memory rarity, string memory tokenURI_) public onlyOwner {
        defaultCocktails[rarity].push(tokenURI_);
    }

    function addSpecialCocktail(string memory rarity, string memory tokenURI_) public onlyOwner {
        specialCocktails[rarity].push(tokenURI_);
    }

    function setDefaultPrice(string memory rarity, uint256 price) public onlyOwner {
        rarities.push(rarity);
        isValidRarity[rarity] = true;
        defaultPrice[rarity] = price;
    }

    function setSpecialCocktailInfo(
        string memory rarity,
        uint256 bonus,
        uint256 numenator,
        uint256 denominator,
        uint256 total
    ) public onlyOwner {
        specialCocktailsInfo[rarity].numenator = numenator;
        specialCocktailsInfo[rarity].denominator = denominator;
        specialCocktailsInfo[rarity].bonus = bonus;
        specialCocktailsInfo[rarity].total = total;
    }

    function addDefaultCocktails(string memory rarity, string[] memory tokenURIs) external onlyOwner {
        uint256 length = tokenURIs.length;
        for (uint256 i = 0; i < length; i++) addDefaultCocktail(rarity, tokenURIs[i]);
    }

    function addSpecialCocktails(string memory rarity, string[] memory tokenURIs) external onlyOwner {
        uint256 length = tokenURIs.length;
        for (uint256 i = 0; i < length; i++) addSpecialCocktail(rarity, tokenURIs[i]);
    }

    function randomInt(
        uint256 _from,
        uint256 _to,
        uint256 _salt
    ) public view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, _salt))
        );
        return (randomNumber % (_to - _from)) + _from;
    }
}
