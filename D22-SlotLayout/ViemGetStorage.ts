import { createPublicClient, http } from 'viem';
import { sepolia } from 'viem/chains';

const client = createPublicClient({
    chain: sepolia,
    transport: http(),
});

// 合约地址
const contractAddress = '0xaaD4892271392d72419c38dCac8FDA74c92D4a18'; // 替换为您的合约地址
const locksCount = 11; // 假设有 11 个锁

// 每个 LockInfo 结构体占用 3 个存储槽
const lockInfoSlotSize = 3;

// 辅助函数：读取存储槽
async function getStorageAt(slot: number) {
    const hexSlot = `0x${slot.toString(16)}`;
    return await client.getStorageAt({
        address: contractAddress,
        slot: hexSlot as `0x${string}`,
    });
}

// 主函数：获取锁信息
async function getLockInfo() {
    try {
        for (let i = 0; i < locksCount; i++) {
            const userSlot = await getStorageAt(i * lockInfoSlotSize);
            const startTimeSlot = await getStorageAt(i * lockInfoSlotSize + 1);
            const amountSlot = await getStorageAt(i * lockInfoSlotSize + 2);

            // 转换读取的值
            const user = userSlot ? `0x${userSlot.slice(26)}` : '0x0'; // 地址
            const startTime = startTimeSlot ? parseInt(startTimeSlot, 16) : 0; // 时间戳
            const amount = amountSlot ? BigInt(amountSlot).toString() : '0'; // 金额

            console.log(`locks[${i}]: user: ${user}, startTime: ${startTime}, amount: ${amount}`);
        }
    } catch (error) {
        console.error('Error fetching lock information:', error);
    }
}

// 执行获取锁信息的函数
getLockInfo();