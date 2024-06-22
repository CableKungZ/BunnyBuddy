// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract PresaleToken is Ownable {
    struct Presale {
        address presaleToken;
        address buyToken;
        uint256 price;
        uint256 remaining;
    }

    mapping(uint256 => Presale) public presaleList;
    uint256 public presaleCount;

    event PresaleSet(uint256 indexed presaleIndex, address presaleToken, address buyToken, uint256 price, uint256 remaining);
    event TokenBought(uint256 indexed presaleIndex, address indexed buyer, uint256 amount);
    event TokenWithdrawn(uint256 indexed presaleIndex, uint256 amount);

    function setPresale(address _presaleToken, address _buyToken, uint256 _price, uint256 _remaining) external onlyOwner {
        presaleList[presaleCount] = Presale({
            presaleToken: _presaleToken,
            buyToken: _buyToken,
            price: _price,
            remaining: _remaining
        });
        emit PresaleSet(presaleCount, _presaleToken, _buyToken, _price, _remaining);
        presaleCount++;
    }

    function buy(uint256 _presaleIndex, uint256 _presaleAmount) external {
        Presale storage presale = presaleList[_presaleIndex];
        require(presale.remaining >= _presaleAmount, "Not enough tokens remaining");

        uint256 cost = _presaleAmount * presale.price;
        require(IERC20(presale.buyToken).transferFrom(msg.sender, address(this), cost), "Payment failed");

        presale.remaining -= _presaleAmount;
        require(IERC20(presale.presaleToken).transfer(msg.sender, _presaleAmount), "Token transfer failed");

        emit TokenBought(_presaleIndex, msg.sender, _presaleAmount);
    }

    function withdrawToken(uint256 _presaleIndex, uint256 _amount) external onlyOwner {
        Presale storage presale = presaleList[_presaleIndex];
        require(IERC20(presale.presaleToken).transfer(msg.sender, _amount), "Token transfer failed");

        emit TokenWithdrawn(_presaleIndex, _amount);
    }
}
