import * as forge from 'node-forge';
import { createHash } from 'crypto';

// 生成 RSA 密钥对
function generateKeyPair(): { publicKey: string; privateKey: string } {
    const { privateKey, publicKey } = forge.pki.rsa.generateKeyPair(2048);
    return {
        publicKey: forge.pki.publicKeyToPem(publicKey),
        privateKey: forge.pki.privateKeyToPem(privateKey),
    };
}

// 使用私钥对数据进行签名
function signData(privateKeyPem: string, data: string): string {
    const privateKey = forge.pki.privateKeyFromPem(privateKeyPem);
    const md = forge.md.sha256.create();
    md.update(data, 'utf8');
    const signature = privateKey.sign(md);
    return forge.util.encode64(signature);
}

// 使用公钥验证签名
function verifySignature(publicKeyPem: string, data: string, signature: string): boolean {
    const publicKey = forge.pki.publicKeyFromPem(publicKeyPem);
    const md = forge.md.sha256.create();
    md.update(data, 'utf8');
    const decodedSignature = forge.util.decode64(signature);
    return publicKey.verify(md.digest().bytes(), decodedSignature);
}

// POW 签名示例
function mineForNonce(nickname: string, difficulty: number): { nonce: number; hash: string } {
    let nonce = 0;
    const prefixStr = '0'.repeat(difficulty);

    while (true) {
        const data = `${nickname}${nonce}`;
        const hash = createHash('sha256').update(data).digest('hex');

        if (hash.startsWith(prefixStr)) {
            return { nonce, hash };
        }

        nonce++;
    }
}

// 主程序
const { publicKey, privateKey } = generateKeyPair();
const nickname = "YunsChou"; // 替换为您的昵称
const difficulty = 4;

const { nonce, hash } = mineForNonce(nickname, difficulty);
const dataToSign = `${nickname}${nonce}`;
const signature = signData(privateKey, dataToSign);

console.log(`Nonce: ${nonce}`);
console.log(`Hash: ${hash}`);
console.log(`Signature: ${signature}`);

// 验证签名
const isVerified = verifySignature(publicKey, dataToSign, signature);
console.log(`Signature Verified: ${isVerified}`);