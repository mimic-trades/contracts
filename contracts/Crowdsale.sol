pragma solidity 0.4.24;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./Token.sol";

contract Crowdsale {

    /**
    * @dev Use SafeMath library for all uint256 variables
    */
    using SafeMath for uint256;

    /**
    * @dev Our previously deployed Token (ERC20) contract
    */
    Token public token;

    /**
    * @dev How many tokens a buyer takes per wei
    */
    uint256 public rate;

    /**
    * @dev The address where all the funds will be stored
    */
    address public wallet;

    /**
    * @dev The amount of wei raised during the ICO
    */
    uint256 public weiRaised;

    /**
    * @dev The amount of tokens purchased by the buyers
    */
    uint256 public tokenPurchased;

    /**
    * @dev Crowdsale's hard cap in token units
    */
    uint256 public hardCap = 100000000 * (10 ** 18);

    /**
    * @dev Crowdsale start date
    */
    uint256 public startDate = 123;

    /**
    * @dev Crowdsale end date
    */
    uint256 public endDate = 123;

    /**
    * @dev Emitted when an amount of tokens is beign purchased
    */
    event Purchase(address indexed sender, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * @dev Contract constructor
    * @param _tokenAddress The address of the previously deployed Token contract
    */
    constructor(address _tokenAddress, uint256 _rate, address _wallet) public {
        require(_tokenAddress != address(0), "Token Address cannot be a null address");
        require(_rate > 0, "Conversion rate must be a positive integer");
        require(_wallet != address(0), "Wallet Address cannot be a null address");

        token = Token(_tokenAddress);
        rate = _rate;
        wallet = _wallet;
    }

    /**
    * @dev Fallback function, called when someone tryes to pay send ether to the contract address
    */
    function () external payable {
        purchase(msg.sender);
    }

    /**
    * @dev General purchase function, used by the fallback function and from buyers who are buying for other addresses
    * @param _beneficiary The Address that will receive the tokens
    */
    function purchase(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;

        // Validate beneficiary and wei amount
        require(_beneficiary != address(0), "Beneficiary Address cannot be a null address");
        require(weiAmount > 0, "Wei amount must be a positive integer");

        // Calculate token amount
        uint256 tokenAmount = _getTokenAmount(weiAmount);

        // Update totals
        weiRaised = weiRaised.add(weiAmount);
        tokenPurchased = tokenPurchased.add(tokenAmount);

        // Make the actual purchase
        _purchaseTokens(_beneficiary, tokenAmount);

        // Emit purchase event
        emit Purchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
    }

    /**
    * @dev Processes the actual purchase (token transfer)
    * @param _beneficiary The Address that will receive the tokens
    * @param _amount The amount of tokens to transfer
    */
    function _purchaseTokens(address _beneficiary, uint256 _amount) internal {
        // TODO: implement
    }

    /**
    * @dev Returns an amount of wei converted in tokens
    * @param _wei Value in wei to be converted
    * @return Amount of tokens 
    */
    function _getTokenAmount(uint256 _wei) internal view returns (uint256) {
        // TODO: add time slices
        return _wei.mul(rate);
    }

}
