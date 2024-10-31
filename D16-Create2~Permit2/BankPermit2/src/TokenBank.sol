// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import "./CoinToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPermit2 {
    // function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}

contract TokenBank {
    mapping(address => mapping(address => uint256)) public addrAmount;
    // 【！！！】在存钱之前，帐户已授权一个超大额度到Permit2合约
    address public permit2Contract;

    constructor(address _permit2Contract) {
        permit2Contract = _permit2Contract;
    }

    function depositWithPermit2(
        address token,
        uint256 amount,
        IPermit2.PermitTransferFrom calldata permit,
        bytes calldata signature
    ) external {
        IPermit2.SignatureTransferDetails memory transferDetails =
            IPermit2.SignatureTransferDetails(address(this), amount);

        uint256 beforeBalance = IERC20(token).balanceOf(msg.sender);
        // 验签（授权转账，往合约中存钱）
        IPermit2(permit2Contract).permitTransferFrom(permit, transferDetails, msg.sender, signature);
        // 检查余额是否一致
        uint256 afterBalance = IERC20(token).balanceOf(msg.sender);
        require(afterBalance == beforeBalance - amount, "permitTransferFrom error");

        // 合约中记账存入的额度
        addrAmount[msg.sender][token] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        uint256 b = addrAmount[msg.sender][token];
        require(b >= amount, "bank amount is not enought");
        IERC20(token).transfer(msg.sender, amount);
        addrAmount[msg.sender][token] = b - amount;
    }
}
