import { createHash } from 'crypto';

function mine(nickname: string, difficulty: number): void {
    let nonce = 0;
    const prefixStr = '0'.repeat(difficulty); // 这里使用 repeat 方法
    const startTime = Date.now();

    while (true) {
        const inputStr = `${nickname}${nonce}`;
        const hashResult = createHash('sha256').update(inputStr).digest('hex');

        if (hashResult.startsWith(prefixStr)) {
            const elapsedTime = (Date.now() - startTime) / 1000;
            console.log(`Nonce: ${nonce}`);
            console.log(`Hash: ${hashResult}`);
            console.log(`Time taken: ${elapsedTime.toFixed(2)} seconds\n`);
            return;
        }

        nonce++;
    }
}

const nickname = "YunsChou"; // 替换为你的昵称
console.log("Mining for 4 leading zeros:");
mine(nickname, 4);
console.log("Mining for 5 leading zeros:");
mine(nickname, 5);