const domain = {
    name: "EIP712Domain",
    version: "1",
    chainId: "",
    verifyingContract: ""
};

// "EIP712Domain(string name,uint256 chainId,address verifyingContract)"

// "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
const types = {
    EIP712Domain: [
        { name: "name", type: "string" },
        { name: "chainId", type: "uint256" },
        { name: "verifyingContract", type: "address" },
    ],
    PermitSingle: [
        { name: "details", type: "PermitDetails" },
        { name: "spender", type: "address" },
        { name: "sigDeadline", type: "uint256" },
    ],
    PermitDetails: [
        { name: "token", type: "token" },
        { name: "amount", type: "uint160" },
        { name: "expiration", type: "uint48" },
        { name: "nonce", type: "uint48" },
    ]
};

const message = {
    name: "",
    chainId: "",
    verifyingContract: ""
};

import { createPublicClient, createWalletClient, custom, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { mainnet } from "viem/chains";

const publicClient = createPublicClient({
    chain: mainnet,
    transport: http()
});

const walletClient = createWalletClient({
    transport: http()
});

const account = privateKeyToAccount("0xda");

const signature = await walletClient.signTypedData({
    account,
    domain,
    types,
    primaryType: "",
    message,
})

const valid = await publicClient.verifyTypedData({
    address: account.address,
    domain,
    types,
    primaryType: "Mail",
    message,
    signature
})

