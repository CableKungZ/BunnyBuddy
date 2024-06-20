// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract PreMint is Ownable {
    struct PreMintData {
        address premintToken;
        address buyToken;
        uint256 premintAmount; // ratio: number of premint tokens per buy token
        uint256 buyAmount;     // ratio: number of buy tokens for premint tokens
        uint256 totalBuy;
        uint256 remaining;
        bool paused;
        address receiveAddress; // address to receive buyToken
    }

    PreMintData[] public preMints;

    event PreMintAdded(uint256 indexed preMintID, address premintToken, address buyToken, uint256 premintAmount, uint256 buyAmount, uint256 totalBuy, address receiveAddress);
    event PreMintPaused(uint256 indexed preMintID, bool paused);
    event TokensBought(uint256 indexed preMintID, address indexed buyer, uint256 buyAmount, uint256 premintAmount);

    function addPreMint(
        address _premintToken,
        address _buyToken,
        uint256 _premintAmount,
        uint256 _buyAmount,
        uint256 _totalBuy,
        address _receiveAddress,
        uint256 _premintTokenAmount
    ) external onlyOwner {
        require(IERC20(_premintToken).transferFrom(msg.sender, address(this), _premintTokenAmount), "Premint token transfer failed");

        preMints.push(PreMintData({
            premintToken: _premintToken,
            buyToken: _buyToken,
            premintAmount: _premintAmount,
            buyAmount: _buyAmount,
            totalBuy: _totalBuy,
            remaining: _totalBuy,
            paused: false,
            receiveAddress: _receiveAddress
        }));

        emit PreMintAdded(preMints.length - 1, _premintToken, _buyToken, _premintAmount, _buyAmount, _totalBuy, _receiveAddress);
    }

    function pausePreMint(uint256 _preMintID, bool _paused) external onlyOwner {
        require(_preMintID < preMints.length, "Invalid PreMint ID");
        preMints[_preMintID].paused = _paused;

        emit PreMintPaused(_preMintID, _paused);
    }

    function buyTokens(uint256 _preMintID, uint256 _buyTokenAmount) external {
        require(_preMintID < preMints.length, "Invalid PreMint ID");
        PreMintData storage preMint = preMints[_preMintID];

        require(!preMint.paused, "PreMint is paused");
        require(preMint.remaining >= _buyTokenAmount, "Not enough tokens remaining");

        uint256 premintTokenAmount = (_buyTokenAmount * preMint.premintAmount) / preMint.buyAmount;

        require(IERC20(preMint.buyToken).transferFrom(msg.sender, preMint.receiveAddress, _buyTokenAmount), "Buy token transfer failed");
        require(IERC20(preMint.premintToken).transfer(msg.sender, premintTokenAmount), "Premint token transfer failed");

        preMint.remaining -= _buyTokenAmount;

        emit TokensBought(_preMintID, msg.sender, _buyTokenAmount, premintTokenAmount);
    }

    function getPreMintStatus(uint256 _preMintID) external view returns (
        address premintToken,
        address buyToken,
        uint256 premintAmount,
        uint256 buyAmount,
        uint256 remaining,
        bool buyable,
        address receiveAddress
    ) {
        require(_preMintID < preMints.length, "Invalid PreMint ID");
        PreMintData storage preMint = preMints[_preMintID];

        return (
            preMint.premintToken,
            preMint.buyToken,
            preMint.premintAmount,
            preMint.buyAmount,
            preMint.remaining,
            !preMint.paused && preMint.remaining > 0,
            preMint.receiveAddress
        );
    }

    function getPreMintLength() external view returns (uint256) {
        return preMints.length;
    }
}
