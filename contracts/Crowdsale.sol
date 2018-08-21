pragma solidity 0.4.24;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/zeppelin-solidity/contracts/crowdsale/distribution/utils/RefundVault.sol";
import "./Token.sol";

contract Crowdsale is Ownable {

    /**
    * @dev Use SafeMath library for all uint256 variables
    */
    using SafeMath for uint256;

    /**
    * @dev Our previously deployed Token (ERC20) contract
    */
    Token public token;

    /**
    * @dev RefundVault used to store ethereum during the Crowdsale and to refund investors if soft cap is not reached
    */
    RefundVault public vault;

    /**
    * @dev How many tokens a buyer takes per wei
    */
    uint256 public rate;

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
    * @dev Crowdsale's soft cap in token units
    */
    uint256 public softCap = 100000000 * (10 ** 18);

    /**
    * @dev Crowdsale start date
    */
    uint256 public startDate = 123;

    /**
    * @dev Crowdsale end date
    */
    uint256 public endDate = 123;

    /**
    * @dev Crowdsale is finished
    */
    bool public finalized = false;

    /**
    * @dev Emitted when an amount of tokens is beign purchased
    */
    event Purchase(address indexed sender, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * @dev Emitted when the crowdsale has beeen finalized
    */
    event Finalize(address indexed sender, uint256 when);

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
        vault = new RefundVault(_wallet);
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

        // Validate beneficiary and wei amount and date
        require(now >= startDate, "Crowdsale has not started yet");
        require(now <= endDate, "Crowdsale has finished");
        require(_beneficiary != address(0), "Beneficiary Address cannot be a null address");
        require(weiAmount > 0, "Wei amount must be a positive integer");

        // Calculate token amount
        uint256 tokenAmount = _getTokenAmount(weiAmount);

        // Update totals
        weiRaised = weiRaised.add(weiAmount);
        tokenPurchased = tokenPurchased.add(tokenAmount);

        // Make the actual purchase
        _purchaseTokens(_beneficiary, tokenAmount);

        // Transfer funds
        _transferFunds();

        // Emit purchase event
        emit Purchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
    }

    function finalize() public onlyOwner {
        finalized = true;

        if (isSoftCapReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }

        
    }

    /**
    * @dev Returns whenever we have reached our soft cap
    */
    function isSoftCapReached() public view returns (bool){
        return weiRaised >= softCap;
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
    * @dev Called at the end of the purchase, sends ethereums to the vault
    */
    function _transferFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
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
