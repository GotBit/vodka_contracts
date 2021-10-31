// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool succes);
    function decimals() external view returns (uint8 decimals);
}
interface ITokenConverter {
    function convertTwoUniversal(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) external view returns (uint256);
}


contract Dispenser {

    address public BUSD;
    ITokenConverter tokenConverter;
    constructor(address tokenConverter_, address busd) {
        tokenConverter = ITokenConverter(tokenConverter_);
        BUSD = busd;
    }

    function dispense(address tokenAddress, uint amount) external {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
    }

    function getPrice(address tokenAddress) external view returns (uint price) {
        IERC20 token = IERC20(tokenAddress);
        uint coin = 10 ** token.decimals();
        return tokenConverter.convertTwoUniversal(BUSD, tokenAddress, coin);
    } 
}
