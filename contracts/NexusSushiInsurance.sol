// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ISushiswapRouter.sol";
import "hardhat/console.sol";

/**
 * @dev This contract stores assets until the foundation decides what to do with them.
 */
contract NexusSushiInsurance is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // --- fields ---
    address public constant ORBS = address(0xff56Cc6b1E6dEd347aA0B7676C85AB0B3D08B0FA);

    // --- events ---

    /**
     * @dev triggered after the owner removed ORBS tokens from the contract
     *
     * @param  _asset          asset address
     * @param  _destination    address that recieved the tokens
     * @param  _amountBefore   amount of tokens in contract before the action
     * @param  _amountAfter    amount of tokens in contract after the action
     */
    event AssetRemoved(
        address indexed _asset,
        address indexed _destination,
        uint256 _amountBefore,
        uint256 _amountAfter
    );

    // --- modifiers ---

    constructor() {}

    // --- views ---

    function orbsBalance() public view returns (uint256 balance) {
        balance = IERC20(ORBS).balanceOf(address(this));
    }

    function assetBalance(address asset_) public view returns (uint256 balance) {
        balance = IERC20(asset_).balanceOf(address(this));
    }

    // --- owner actions ---

    /**
     * @dev transfers asset tokens to the contract owner. If the `amount_` is set
     * to 0, the total asset balance of the contract will be transferred.
     *
     * @param amount_   the desired amount to transfer. 0 means total balance.
     */
    function transferAsset(address asset_, uint256 amount_) public onlyOwner {
        uint256 balanceBefore = IERC20(asset_).balanceOf(address(this));

        require(amount_ <= balanceBefore, "amount: bigger than balance");

        if (amount_ == 0) {
            // transfer the total amount
            if (balanceBefore > 0) {
                IERC20(asset_).safeTransfer(owner(), balanceBefore);
            }
        } else {
            IERC20(asset_).safeTransfer(owner(), amount_);
        }

        uint256 balanceAfter = IERC20(asset_).balanceOf(address(this));
        emit AssetRemoved(asset_, owner(), balanceBefore, balanceAfter);
    }

    /**
     * @dev transfers ORBS tokens to the contract owner. If the `amount_` is set
     * to 0, the total ORBS balance of the contract will be transferred.
     *
     * @param amount_   the desired amount to transfer. 0 means total balance.
     */
    function transferOrbs(uint256 amount_) external onlyOwner {
        transferAsset(ORBS, amount_);
    }

    /**
     * @dev withdraw a given list of tokens
     *
     * @param tokens_   the desired tokens list to withdraw
     */
    function rescueAssets(address[] memory tokens_) external onlyOwner {
        uint256 ercLen = tokens_.length;
        for (uint256 i = 0; i < ercLen; i++) {
            address token = tokens_[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).safeTransfer(owner(), balance);
            }
        }
    }
}
