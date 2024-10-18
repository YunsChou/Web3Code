// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IERC721Coin.sol";
import "./IERC721Receiver.sol";

contract ERC721Coin is IERC721Coin {
    using Strings for uint256;

    string public name;
    string public symbol;
    string public baseURI;

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenOwners;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _allApprovals; 

    error ERC721InvalidReceiver(address receiver);

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }
    
    // 查询某个地址中 nft 余额
    function balanceOf(address owner) external view returns (uint256 balance) {
        return _balances[owner];
    }

    // 查询某个 nft 所有者地址
    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return _tokenOwners[tokenId];
    }

    // 【单个授权】给某个 地址 授权 nft (必须是所有者才能授权) 
    function approve(address to, uint256 tokenId) external {
        // 需要判断是否token所有者
        address owner = _tokenOwners[tokenId];
        require(owner == msg.sender, "is not owner");
        // 授权
        _tokenApprovals[tokenId] = to;
         emit Approval(msg.sender, to, tokenId);
    }

    // 【批量授权】给某个 地址 授权 所有nft (必须是所有者才能授权) 
    function setApprovalForAll(address operator, bool _approved) external {
        _allApprovals[msg.sender][operator] = _approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    // 查询某个 nft 的授权地址
    function getApproved(uint256 tokenId) external view returns (address operator) {
        return _tokenApprovals[tokenId];
    }

    // 查询 所有者地址 是否 给另一个地址 全部授权
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _allApprovals[owner][operator];
    }

    // 转账：普通授权转账
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        _transfer(from, to, tokenId);
    }

    // 安全转账
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
       this.safeTransferFrom(from, to, tokenId, "");
    }

    // 安全转账：和普通授权转账区别？多了个回调
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
       _transfer(from, to, tokenId);
       _checkOnERC721Received(from, to, tokenId, data);
    }

    
    // 转账
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        // 接收者地址不为空
        require(to != address(0), "to address is 0x");
        
        address tokenOwner = _tokenOwners[tokenId];
        // 以下条件需要合并判断 ||，分开判断相当于 &
        // 调用者是否token 持有人地址
        // from 是否owner授权地址 or 是否owner批量授权地址
        require(tokenOwner == msg.sender || _tokenApprovals[tokenId] == from || _allApprovals[tokenOwner][from], "is not owner or approvee");

        // 取消该tokenId授权
        _tokenApprovals[tokenId] = address(0);
        // 修改tokenId所有者
        _tokenOwners[tokenId] = to;

        // 开始转账（记账）
        _balances[tokenOwner] -= 1;
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);    
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private  {
        if (to.code.length > 0) { // 检查是合约地址
            try IERC721Receiver(to).onERC721Received(from, to, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else { // 回退并现实具体原因
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "to address is 0x");
        require(_tokenOwners[tokenId] == address(0), "tokenId had mint");

        _tokenOwners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _tokenOwners[tokenId];
        require(owner == msg.sender, "msg.sender is not owner");

        _tokenOwners[tokenId] = address(0);
        _balances[owner] -= 1;

        emit Transfer(owner, address(0), tokenId);
    }

    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        require(_tokenOwners[tokenId] != address(0), "tokenId is not exist");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
    
}