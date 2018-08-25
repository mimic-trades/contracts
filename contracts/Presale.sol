pragma solidity 0.4.24;

import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./Token.sol";

contract Presale is Ownable {

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
    * @dev The address where all the tokens are stored
    */
    address public holder;

    /**
    * @dev The amount of wei raised during the ICO
    */
    uint256 public weiRaised;

    /**
    * @dev The amount of tokens purchased by the buyers
    */
    uint256 public tokenPurchased;

    /**
    * @dev Crowdsale start date
    */
    uint256 public constant startDate = 1535994000; // 2018-09-03 17:00:00 (UTC)

    /**
    * @dev Crowdsale end date
    */
    uint256 public constant endDate = 1541264400; // 2018-10-01 10:00:00 (UTC)

    /**
    * @dev The minimum amount of ethereum that we accept as a contribution
    */
    uint256 public minimumAmount = 40 ether;

    /**
    * @dev The maximum amount of ethereum that an address can contribute
    */
    uint256 public maximumAmount = 200 ether;

    /**
    * @dev Mapping tracking how much an address has contribuited
    */
    mapping (address => uint256) public contributionAmounts;

    /**
    * @dev Mapping containing which addresses are whitelisted
    */
    mapping (address => bool) public whitelist;

    /**
    * @dev Emitted when an amount of tokens is beign purchased
    */
    event Purchase(address indexed sender, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * @dev Emitted when we change the conversion rate 
    */
    event ChangeRate(uint256 rate);

    /**
    * @dev Emitted when we change the minimum contribution amount
    */
    event ChangeMinimumAmount(uint256 amount);

    /**
    * @dev Emitted when we change the maximum contribution amount
    */
    event ChangeMaximumAmount(uint256 amount);

    /**
    * @dev Emitted when the whitelisted state of and address is changed
    */
    event Whitelist(address indexed beneficiary, bool indexed whitelisted);

    /**
    * @dev Contract constructor
    * @param _tokenAddress The address of the previously deployed Token contract
    */
    constructor(address _tokenAddress, uint256 _rate, address _wallet, address _holder) public {
        require(_tokenAddress != address(0), "Token Address cannot be a null address");
        require(_rate > 0, "Conversion rate must be a positive integer");
        require(_wallet != address(0), "Wallet Address cannot be a null address");
        require(_holder != address(0), "Holder Address cannot be a null address");

        token = Token(_tokenAddress);
        rate = _rate;
        wallet = _wallet;
        holder = _holder;
    }

    /**
    * @dev Modifier used to verify if an address can purchase
    */
    modifier canPurchase(address _beneficiary) {
        require(now >= startDate, "Presale has not started yet");
        require(now <= endDate, "Presale has finished");

        require(whitelist[_beneficiary] == true, "Your address is not whitelisted");

        uint256 amount = uint256(contributionAmounts[_beneficiary]).add(msg.value);

        require(msg.value >= minimumAmount, "Cannot contribute less than the minimum amount");
        require(amount <= maximumAmount, "Cannot contribute more than the maximum amount");
        
        _;
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
    function purchase(address _beneficiary) internal canPurchase(_beneficiary) {
        uint256 weiAmount = msg.value;

        // Validate beneficiary and wei amount
        require(_beneficiary != address(0), "Beneficiary Address cannot be a null address");
        require(weiAmount > 0, "Wei amount must be a positive integer");

        // Calculate token amount
        uint256 tokenAmount = _getTokenAmount(weiAmount);

        // Update totals
        weiRaised = weiRaised.add(weiAmount);
        tokenPurchased = tokenPurchased.add(tokenAmount);
        contributionAmounts[_beneficiary] = contributionAmounts[_beneficiary].add(weiAmount);

        _transferEther(weiAmount);

        // Make the actual purchase and send the tokens to the contributor
        _purchaseTokens(_beneficiary, tokenAmount);

        // Emit purchase event
        emit Purchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
    }

    /**
    * @dev Updates the conversion rate to a new value
    * @param _rate The new conversion rate
    */
    function updateConversionRate(uint256 _rate) public onlyOwner {
        require(_rate > 0, "Conversion rate must be a positive integer");

        rate = _rate;

        emit ChangeRate(_rate);
    }

    /**
    * @dev Updates the minimum contribution amount to a new value
    * @param _amount The new minimum contribution amount expressed in wei
    */
    function updateMinimumAmount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Minimum amount must be a positive integer");

        minimumAmount = _amount;

        emit ChangeMinimumAmount(_amount);
    }

    /**
    * @dev Updates the maximum contribution amount to a new value
    * @param _amount The new maximum contribution amount expressed in wei
    */
    function updateMaximumAmount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Maximum amount must be a positive integer");

        maximumAmount = _amount;

        emit ChangeMaximumAmount(_amount);
    }

    /**
    * @dev Updates the whitelisted status of an address
    * @param _addr The address in question
    * @param _whitelist The new whitelist status
    */
    function setWhitelist(address _addr, bool _whitelist) public onlyOwner {
        require(_addr != address(0x0), "Whitelisted address must be valid");

        whitelist[_addr] = _whitelist;

        emit Whitelist(_addr, _whitelist);
    }

    /**
    * @dev Processes the actual purchase (token transfer)
    * @param _beneficiary The Address that will receive the tokens
    * @param _amount The amount of tokens to transfer
    */
    function _purchaseTokens(address _beneficiary, uint256 _amount) internal {
        token.transferFrom(holder, _beneficiary, _amount);
    }

    /**
    * @dev Transfers the ethers recreived from the contributor to the Presale wallet
    * @param _amount The amount of ethers to transfer
    */
    function _transferEther(uint256 _amount) internal {
        // this should throw an exeption if it fails
        wallet.transfer(_amount);
    }

    /**
    * @dev Returns an amount of wei converted in tokens
    * @param _wei Value in wei to be converted
    * @return Amount of tokens 
    */
    function _getTokenAmount(uint256 _wei) internal view returns (uint256) {
        // wei * ((rate * (30 + 100)) / 100)
        return _wei.mul(rate.mul(130).div(100));
    }

}