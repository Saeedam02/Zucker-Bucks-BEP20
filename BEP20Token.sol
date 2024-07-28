pragma solidity 0.5.16;

import "./Context.sol";
import "./IBEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract BEP20Token is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  // Mapping from address to account balances
  mapping (address => uint256) private _balances;

  // Mapping from owner to spender allowances
  mapping (address => mapping (address => uint256)) private _allowances;

  // Mapping to keep track of waitlisted addresses
  mapping(address => bool) private _waitlist;

  // Total supply of tokens
  uint256 private _totalSupply;
 
  // Token details
  uint8 private _decimals;
  string private _symbol;
  string private _name;
 
  // Sell tax percentage
  uint256 private _sellTax;

  /**
   * @dev Constructor that gives msg.sender all of existing tokens and adds them to the waitlist.
   */
  constructor() public {
    _name = "Zuker Bucks";
    _symbol = "Zuck";
    _decimals = 18;
    _totalSupply = 1000000 * (10 ** uint256(_decimals));  
    _balances[msg.sender] = _totalSupply;
    _waitlist[msg.sender] = true; // Add the owner to the waitlist
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the total supply of tokens.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Returns the balance of a specific account.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev Transfers tokens to a specific address.
   *
   * Requirements:
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev Approves `spender` to spend `amount` of the caller's tokens.
   *
   * Requirements:
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev Transfers tokens from one address to another using the allowance mechanism.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount));
  }

  /**
   * @dev Sets the sell tax percentage.
   *
   * Can only be called by the owner.
   */
  function setSellTax(uint256 tax) external onlyOwner {
    _sellTax = tax;
  }

  /**
   * @dev Sells `amount` of tokens.
   *
   * Requirements:
   * - Caller must be in the waitlist.
   * - Caller must wait 30 days after being added to the waitlist to sell.
   * - Applies the sell tax to the transaction.
   */
  function sell(uint256 amount) external {
    require(_waitlist[msg.sender], "You bought less amount than the acceptable amount so you need to wait 30 days.");
    uint256 taxAmount = amount.mul(_sellTax).div(100);
    uint256 sellAmount = amount.sub(taxAmount);

    _transfer(_msgSender(), address(this), taxAmount); // Send tax to contract or another address
    _transfer(_msgSender(), msg.sender, sellAmount);  // Proceed with the transfer
  }
}