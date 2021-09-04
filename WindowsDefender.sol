// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract windowsDefender is Context, Ownable{

    uint256 public marketing_tax = 3;
    uint256 public team_tax = 2;

    address private _marketingAdd;
    address private _teamAdd;
    address private _devAdd;

    constructor(address marketingWallet, address teamWallet, address devWallet){
        _marketingAdd = marketingWallet;
        _teamAdd = teamWallet;
        _devAdd = devWallet;
    }

    receive() external payable {
        forwardFunds();
    }

    function forwardFunds() internal {
        uint256 totFees = marketing_tax + team_tax;
        uint256 BNBbalance = address(this).balance;
        uint256 marketingBNB = BNBbalance * marketing_tax / totFees;
        uint256 teamBNB = (BNBbalance * team_tax / totFees) * 75 / 100;
        uint256 devBNB = (BNBbalance * team_tax / totFees) * 25 / 100;

        if(marketingBNB > 0) payable(_marketingAdd).transfer(marketingBNB);
        if(teamBNB > 0) payable(_teamAdd).transfer(teamBNB);
        if(devBNB > 0) payable(_devAdd).transfer(devBNB);
    }

    function forceForwardFunds() external {
        forwardFunds();
    }

    function setWallets(address marketingWallet, address teamWallet, address devWallet) external onlyOwner{
        require(marketingWallet != address(0x000000000000000000000000000000000000dEaD));
        require(teamWallet != address(0x000000000000000000000000000000000000dEaD));
        require(devWallet != address(0x000000000000000000000000000000000000dEaD));
        _marketingAdd = marketingWallet;
        _teamAdd = teamWallet;
        _devAdd = devWallet;
    }

    function setTaxes(uint256 _marketing_tax, uint256 _team_tax) external onlyOwner{
        marketing_tax = _marketing_tax;
        team_tax = _team_tax;
    }

    function takeTokensWronglySent(IERC20 tokenAddress) external onlyOwner{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        address payable wallet = payable(msg.sender);
        tokenBEP.transfer(wallet, tokenAmt);
    }
}
