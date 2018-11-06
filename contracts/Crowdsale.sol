pragma solidity 0.4.24;

import "../node_modules/zeppelin-solidity/contracts/crowdsale/distribution/utils/RefundVault.sol";
import "../node_modules/zeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
import "./Token.sol";

contract MimicCrowdsale is RefundableCrowdsale {

    /**
    * @dev Use SafeMath library for all uint256 variables
    */
    using SafeMath for uint256;

    /**
    * @dev The address where all the tokens are stored
    */
    address public holder;

    /**
    * @dev  Mapping containing the first whitelist
    */
    mapping (address => bool) public whitelistA;
    
    /**
    * @dev  Mapping containing the second whitelist
    */
    mapping (address => bool) public whitelistB;

    /**
    * @dev Mapping tracking how much an address has contribuited
    */
    mapping (address => uint256) public contributionAmounts;

    /**
    * @dev Maximum amount of ether whitelistA will be able to contribute
    *      the first day
    */
    uint256 public firstDayCap = 4 ether;

    /**
    * @dev The minimum amount of ethereum that we accept as a contribution
    */
    uint256 public minimumAmount = 0.1 ether;

    /**
    * @dev The maximum amount of ethereum that we accept as a contribution.
    *      Starting from day two
    */
    uint256 public maximumAmount = 80 ether;

    /**
    * @dev Crowdsale start date
    */
    uint256 public openingTime = 123;

    /**
    * @dev Crowdsale end date
    */
    uint256 public closingTime = 123;
    
    /**
    * @dev End of first day
    */
    uint256 public firstDayClosingTime = openingTime + 1 days;

    /**
    * @dev Start date of the decreasing bonus period
    */
    uint256 public startOfDecreasingBonusTime = openingTime + 4 days;

    /**
    * @dev End date of the decreasing bonus period
    */
    uint256 public endOfDecreasingBonusTime = startOfDecreasingBonusTime + 14 days;

    /**
    * @dev Decreasing period in days
    */
    uint256 public absoluteDecreasingPeriodInDays = (endOfDecreasingBonusTime - startOfDecreasingBonusTime) / 1 days;

    /*
    goal --
    isFinished
    openingTime --
    closingTime --
    token --
    wallet --
    rate --
    weiRaised
    */

    /**
    * @dev Contract constructor
    * @param _token Token's contract address
    * @param _wallet Receiving wallet's address
    * @param _holder Tokens' holder address
    * @param _rate The initial conversion
    * @param _goal The minimum amount of wei to raise in order to finalize the Crowdsale
    */
    constructor(address _token, address _wallet, address _holder, uint256 _rate, uint256 _goal) RefundableCrowdsale(_goal) public {
        require(_token != address(0), "Token Address cannot be a null address");
        require(_wallet != address(0), "Wallet Address cannot be a null address");
        require(_holder != address(0), "Holder Address cannot be a null address");
        require(_rate > 0, "Conversion rate must be a positive integer");
        
        token = ERC20(_token);
        wallet = _wallet;
        holder = _holder;
        rate = _rate;
    }

    /**
    * @dev Calculates the bonus amount based on the time of the transaction
    */
    function getBonus() public view returns (uint256) {
        uint256 bonus = 0;
        
        if (now >= openingTime && now < firstDayClosingTime) {
            // first day
            bonus = 20;
        } else if (now >= firstDayClosingTime && now < startOfDecreasingBonusTime) {
            // first 2 days after first day
            if (now < firstDayClosingTime + 1 days) {
                bonus = 20;
            } else {
                bonus = 15;
            }
        } else if (now >= startOfDecreasingBonusTime && now < endOfDecreasingBonusTime) {
            // decreasing bonus period
            uint256 difference = (now - startOfDecreasingBonusTime) / 1 days;
            bonus = absoluteDecreasingPeriodInDays - difference;
        }
        
        return bonus;
    }

    /**
    * @dev Prevalidates with some sanity checks
    * @param _beneficiary The address that's goind go receive the tokens
    * @param _amount The amount of wei contributed
    */
    function _preValidatePurchase(address _beneficiary, uint256 _amount) internal {
        require(_beneficiary != address(0), "Beneficiary cannot be a null address");
        require(_amount > 0, "Contribution amount must be a positive integer");
        require(_amount >= minimumAmount, "Cannot contribute less than the minimum amount");
        require(now >= openingTime, "Crowdsale has not started yet");
        require(now < closingTime, "Crowdsale has ended");

        uint256 nextAmount = contributionAmounts[_beneficiary].add(_amount);
        if (_isFirstDay()) {
            if (!_isInWhitelistA(_beneficiary)) {
                revert("This address cannot contribute the first day");
            }

            require(nextAmount <= firstDayCap, "Cannot contribute more than the maximum amount");
        } else {
            require(_isInWhitelistA(_beneficiary) || _isInWhitelistB(_beneficiary), "Address not whitelisted");
            require(nextAmount <= maximumAmount, "Cannot contribute more than the maximum amount");
        }
    }

    /**
    * @dev Actual purchase function, executed only if the prevalidation function didn't fail
    * @param _beneficiary The address that's goind go receive the tokens
    * @param _amount The amount of wei contributed
    */
    function _processPurchase(address _beneficiary, uint256 _amount) internal {
        uint256 tokenAmount = _getTokenAmount(_amount);
        require(tokenAmount > 0, "Cannot transfer zero tokens");
        
        // update stats
        contributionAmounts[_beneficiary] = contributionAmounts[_beneficiary].add(_amount);

        _deliverTokens(_beneficiary, tokenAmount);
    }

    /**
    * @dev Transfer calculated tokens to the beneficiary address
    * @param _beneficiary The address that's goind go receive the tokens
    * @param _amount The amount of tokens to transfer
    */
    function _deliverTokens(address _beneficiary, uint256 _amount) internal {
        token.transfer(_beneficiary, _amount);
    }

    /**
    * @dev Calculates the amount of tokens to transfer accounting for the current bonus
    * @param _wei The contribution amount in wei
    */
    function _getTokenAmount(uint256 _wei) internal view returns (uint256) {
        // wei * ((rate * (BONUS + 100)) / 100)
        return _wei.mul(rate.mul(getBonus().add(100)).div(100));
    }

    /**
    * @dev Returns true if we are in the first day of the Crowdsale
    */
    function _isFirstDay() internal view returns (bool) {
        return now < firstDayClosingTime;
    }

    /**
    * @dev Checks if the beneficiary address is in our first whitelist 
    */
    function _isInWhitelistA(address _beneficiary) internal view returns (bool) {
        return whitelistA[_beneficiary] == true;
    }

    /**
    * @dev Checks if the beneficiary address is in our second whitelist 
    */
    function _isInWhitelistB(address _beneficiary) internal view returns (bool) {
        return whitelistB[_beneficiary] == true;
    }

}
