import { createPublicClient, http, parseAbiItem } from "viem";
import { mainnet } from "viem/chains";

// USDT 合约地址
const USDT_ADDRESS = '0xdac17f958d2ee523a2206206994597c13d831ec7'


// Transfer 事件的 ABI
const transferEvent = parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 value)')

const RPC_URL = `https://eth-mainnet.g.alchemy.com/v2/WK4nOGEwzeWZqG5G6WvfUuzR2FPqlLt2`

// 创建以太坊客户端
const publicClient = createPublicClient({
    chain: mainnet,
    transport: http(RPC_URL, {
        batch: true,
        retryCount: 3,
        retryDelay: 1000,
    })
})

async function watchUSDTTransfers() {
    console.log('Starting USDT transfer monitoring...');
    console.log(`Watching contract: ${USDT_ADDRESS}`);
    console.log('------------------------');

    const unwatch = publicClient.watchEvent({
        address: USDT_ADDRESS,
        event: transferEvent,
        onLogs: (logs) => {
            for (const log of logs) {
                console.log('-->> From:', log.args.from);
                console.log('-->> To:', log.args.to);
                console.log('-->> Value:', log.args.value);
                console.log('------------------------');
            }
        }
    });

}

watchUSDTTransfers();