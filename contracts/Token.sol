pragma solidity 0.4.24;

import "../node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";

contract Token is StandardToken, BurnableToken, Ownable {

    /**
    * @dev Use SafeMath library for all uint256 variables
    */
    using SafeMath for uint256;

    /**
    * @dev ERC20 variables
    */
    string public name = "MIMIC";
    string public symbol = "MIMIC";
    uint256 public decimals = 18;

    /**
    * @dev Total token supply
    */
    uint256 public INITIAL_SUPPLY = 900000000 * (10 ** decimals);

    /** 
    * @dev Addresses where the tokens will be stored initially
    */
    address public constant ICO_ADDRESS        = 0x93Fc953BefEF145A92760476d56E45842CE00b2F;
    address public constant PRESALE_ADDRESS    = 0x3be448B6dD35976b58A9935A1bf165d5593F8F27;

    /**
    * @dev Address that can receive the tokens before the end of the ICO
    */
    address public constant BACKUP_ONE     = 0x9146EE4eb69f92b1e59BE9C7b4718d6B75F696bE;
    address public constant BACKUP_TWO     = 0xe12F95964305a00550E1970c3189D6aF7DB9cFdd;
    address public constant BACKUP_THREE   = 0x2FBF54a91535A5497c2aF3BF5F64398C4A9177a2;
    address public constant BACKUP_FOUR    = 0xa41554b1c2d13F10504Cc2D56bF0Ba9f845C78AC;

    /** 
    * @dev Team members has temporally locked token.
    *      Variables used to define how the tokens will be unlocked.
    */
    uint256 public lockStartDate = 0;
    uint256 public lockEndDate = 0;
    uint256 public lockAbsoluteDifference = 0;
    mapping (address => uint256) public initialLockedAmounts;

    /**
    * @dev Defines if tokens arre free to move or not 
    */
    bool public areTokensFree = false;

    /** 
    * @dev Emitted when the token locked amount of an address is set
    */
    event SetLockedAmount(address indexed owner, uint256 amount);

    /** 
    * @dev Emitted when the token locked amount of an address is updated
    */
    event UpdateLockedAmount(address indexed owner, uint256 amount);

    /**
    * @dev Emitted when it will be time to free the unlocked tokens
    */
    event FreeTokens();

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[owner] = totalSupply_;
    }

    /** 
    * @dev Check whenever an address has the power to transfer tokens before the end of the ICO
    * @param _sender Address of the transaction sender
    * @param _to Destination address of the transaction
    */
    modifier canTransferBeforeEndOfIco(address _sender, address _to) {
        require(
            areTokensFree ||
            _sender == owner ||
            _sender == ICO_ADDRESS ||
            _sender == PRESALE_ADDRESS ||
            (
                _to == BACKUP_ONE ||
                _to == BACKUP_TWO ||
                _to == BACKUP_THREE || 
                _to == BACKUP_FOUR
            )
            , "Cannot transfer tokens yet"
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
        uint256 afterTransfer = balances[_sender].sub(_amount);
        require(afterTransfer >= getLockedAmount(_sender), "Not enought unlocked tokens");
        
        _;
    }

    /** 
    * @dev Returns the amount of tokens an address has locked
    * @param _addr The address in question
    */
    function getLockedAmount(address _addr) public view returns (uint256){
        if (now >= lockEndDate || initialLockedAmounts[_addr] == 0x0)
            return 0;

        if (now < lockStartDate) 
            return initialLockedAmounts[_addr];

        uint256 alpha = uint256(now).sub(lockStartDate); // absolute purchase date
        uint256 tokens = initialLockedAmounts[_addr].sub(alpha.mul(initialLockedAmounts[_addr]).div(lockAbsoluteDifference)); // T - (α * T) / β

        return tokens;
    }

    /** 
    * @dev Sets the amount of locked tokens for a specific address. It doesn't transfer tokens!
    * @param _addr The address in question
    * @param _amount The amount of tokens to lock
    */
    function setLockedAmount(address _addr, uint256 _amount) public onlyOwner {
        require(_addr != address(0x0), "Cannot set locked amount to null address");

        initialLockedAmounts[_addr] = _amount;

        emit SetLockedAmount(_addr, _amount);
    }

    /** 
    * @dev Updates (adds to) the amount of locked tokens for a specific address. It doesn't transfer tokens!
    * @param _addr The address in question
    * @param _amount The amount of locked tokens to add
    */
    function updateLockedAmount(address _addr, uint256 _amount) public onlyOwner {
        require(_addr != address(0x0), "Cannot update locked amount to null address");
        require(_amount > 0, "Cannot add 0");

        initialLockedAmounts[_addr] = initialLockedAmounts[_addr].add(_amount);

        emit UpdateLockedAmount(_addr, _amount);
    }

    /**
    * @dev Frees all the unlocked tokens
    */
    function freeTokens() public onlyOwner {
        require(!areTokensFree, "Tokens have already been freed");

        areTokensFree = true;

        lockStartDate = now;
        // lockEndDate = lockStartDate + 365 days;
        lockEndDate = lockStartDate + 1 days;
        lockAbsoluteDifference = lockEndDate.sub(lockStartDate);

        emit FreeTokens();
    }

    /**
    * @dev Override of ERC20's transfer function with modifiers
    * @param _to The address to which tranfer the tokens
    * @param _value The amount of tokens to transfer
    */
    function transfer(address _to, uint256 _value)
        public
        canTransferBeforeEndOfIco(msg.sender, _to) 
        canTransferIfLocked(msg.sender, _value) 
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Override of ERC20's transfer function with modifiers
    * @param _from The address from which tranfer the tokens
    * @param _to The address to which tranfer the tokens
    * @param _value The amount of tokens to transfer
    */
    function transferFrom(address _from, address _to, uint _value) 
        public
        canTransferBeforeEndOfIco(_from, _to) 
        canTransferIfLocked(_from, _value) 
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

}
