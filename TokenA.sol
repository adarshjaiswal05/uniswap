// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract TokenA is ERC20{

    address admin;
    constructor()ERC20("TokenA","TKNA"){
        admin= msg.sender;
    }

    function mint (address account, uint256 amount) external {
        require(msg.sender == admin , "only admin can mint the tokens");
        _mint( account, amount);
    }

    function burn ( uint256 amount) external {
        require( balanceOf(msg.sender) >= amount , "you dont have enough token to burn");
        _burn( msg.sender, amount);
    }

}