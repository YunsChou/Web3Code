import { createPublicClient, http, parseAbiItem, formatUnits } from "viem";
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

// https://viem.sh/docs/actions/public/getLogs
async function watchUSDTLatest100Transfers() {
    console.log('Starting USDT transfer monitoring...');
    console.log(`Watching contract: ${USDT_ADDRESS}`);
    console.log('------------------------');

    try {
        const latestBlockNum = await publicClient.getBlockNumber();
        const startBlockNum = latestBlockNum - 100n;

        console.log(`-->> 查询区块：${startBlockNum} ~ ${latestBlockNum}`);

        const logs = await publicClient.getLogs({
            address: USDT_ADDRESS,
            event: transferEvent,
            fromBlock: startBlockNum,
            toBlock: latestBlockNum
        })

        logs.forEach(log => {
            let logArgs = log.args as {
                from: string;
                to: string;
                value: bigint;
            }

            console.log('USDC Transfer:')
            console.log('From:', logArgs.from)
            console.log('To:', logArgs.to)
            console.log('Amount:', formatUnits(logArgs.value, 6), 'USDC')
            console.log(`-----交易区块: ${log.blockNumber}, 交易hash: ${log.transactionHash}-----`)
            console.log(`从 ${logArgs.from} 转账给 ${logArgs.to} ${formatUnits(logArgs.value, 6)} USDC `)

        })
    } catch (error) {
        console.log(`-->> check error: ${error}`);
    }
}

watchUSDTLatest100Transfers();

