pragma solidity 0.4.24;

import "../node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";

contract Token is StandardToken, BurnableToken, Ownable {

    using SafeMath for uint256;

    /**
    * @dev ERC20 variables
    */
    string public name = "MIMIC";
    string public symbol = "MIM";
    uint256 public decimals = 18;

    /** a
    * @dev Total token supplys
    */
    uint256 public INITIAL_SUPPLY = 200000000 * (10 ** decimals);

    /** 
    * @dev Addresses where the tokens will be stored initially
    */
    address constant TEAM_ADDRESS       = 0x0;
    address constant RESERVE_ADDRESS    = 0x0;
    address constant LIQUIDITY_ADDRESS  = 0x0;
    address constant ADVISOR_ADDRESS    = 0x0;
    address constant BOUNTIES_ADDRESS   = 0x0;
    address constant PARTNERS_ADDRESS   = 0x0;
    address constant ICO_ADDRESS        = 0x0;
    address constant PRESALE_ADDRESS    = 0x0;

    /** 
    * @dev ICO end date
    */
    uint256 constant ICO_END_DATE = 12345;

    /** 
    * @dev Team members has temporally locked token.
    *      Variables used to define how the tokens will be unlocked.
    */
    uint256 constant LOCK_START_DATE    = 12345;
    uint256 constant LOCK_END_DATE      = 12345;
    uint256 constant LOCK_ABS_DIFF      = LOCK_END_DATE - LOCK_START_DATE;
    mapping (address => uint256) public initialLockedAmounts;

    /** 
    * @dev Emitted when the token locked amount of an address is set
    */
    event SetLockedAmount(address indexed owner, uint256 indexed amount);

    /** 
    * @dev Emitted when the token locked amount of an address is updated
    */
    event UpdateLockedAmount(address indexed owner, uint256 indexed amount);

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[owner] = totalSupply_;
    }

    /** 
    * @dev Check whenever an address has the power to transfer tokens before the end of the ICO
    * @param _sender Address of the transaction sender
    */
    modifier canTransferBeforeEndOfIco(address _sender) {
        require(
            now >= ICO_END_DATE ||
            _sender == owner ||
            _sender == TEAM_ADDRESS ||
            _sender == RESERVE_ADDRESS || 
            _sender == LIQUIDITY_ADDRESS ||
            _sender == ADVISOR_ADDRESS ||
            _sender == BOUNTIES_ADDRESS ||
            _sender == PARTNERS_ADDRESS ||
            _sender == ICO_ADDRESS ||
            _sender == PRESALE_ADDRESS
            , "ICO hasn't ended yet. Cannot transfer tokens."
        );

        _;
    }

    /** 
    * @dev Check whenever an address can transfer an certain amount of token in the case all or some part
    *      of them are locked
    * @param _sender Address of the transaction sender
    * @param _amount The amount of tokens the address is trying to transfer
    */
    modifier canTransferIfLocked(address _sender, uint256 _amount) {
        require(getLockedAmount(_sender) < _amount, "Locked amount is greater than transferring amount");

        _;
    }

    /** 
    * @dev Returns the amount of tokens an address has locked
    * @param _addr The address in question
    */
    function getLockedAmount(address _addr) public view returns (uint256){
        if (now >= LOCK_END_DATE || initialLockedAmounts[_addr] == 0x0)
            return 0;

        if (now < LOCK_START_DATE) 
            return initialLockedAmounts[_addr];

        uint256 alpha = uint256(now).sub(LOCK_START_DATE); // absolute purchase date
        uint256 tokens = initialLockedAmounts[_addr].sub(alpha.mul(initialLockedAmounts[_addr]).div(LOCK_ABS_DIFF)); // T - (α * T) / β

        return tokens;
    }

    /** 
    * @dev Sets the amount of locked tokens for a specific address. It doesn't transfer tokens!
    * @param _addr The address in question
    * @param _amount The amount of tokens to lock
    */
    function setLockedAmount(address _addr, uint256 _amount) onlyOwner public {
        require(_addr != address(0x0), "Cannot set locked amount to null address");

        initialLockedAmounts[_addr] = _amount;

        emit SetLockedAmount(_addr, _amount);
    }

    /** 
    * @dev Updates (adds) the amount of locked tokens for a specific address. It doesn't transfer tokens!
    * @param _addr The address in question
    * @param _amount The amount of locked tokens to add
    */
    function updateLockedAmount(address _addr, uint256 _amount) onlyOwner public {
        require(_addr != address(0x0), "Cannot update locked amount to null address");
        require(_amount > 0, "Cannot add 0");

        initialLockedAmounts[_addr] = initialLockedAmounts[_addr].add(_amount);

        emit UpdateLockedAmount(_addr, _amount);
    }

    function transfer(address _to, uint256 _value) canTransferBeforeEndOfIco(msg.sender) canTransferIfLocked(msg.sender, _value) public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransferBeforeEndOfIco(_from) canTransferIfLocked(_from, _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

}
