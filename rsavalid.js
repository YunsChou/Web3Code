"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var forge = require("node-forge");
var crypto_1 = require("crypto");
// 生成 RSA 密钥对
function generateKeyPair() {
    var _a = forge.pki.rsa.generateKeyPair(2048), privateKey = _a.privateKey, publicKey = _a.publicKey;
    return {
        publicKey: forge.pki.publicKeyToPem(publicKey),
        privateKey: forge.pki.privateKeyToPem(privateKey),
    };
}
// 使用私钥对数据进行签名
function signData(privateKeyPem, data) {
    var privateKey = forge.pki.privateKeyFromPem(privateKeyPem);
    var md = forge.md.sha256.create();
    md.update(data, 'utf8');
    var signature = privateKey.sign(md);
    return forge.util.encode64(signature);
}
// 使用公钥验证签名
function verifySignature(publicKeyPem, data, signature) {
    var publicKey = forge.pki.publicKeyFromPem(publicKeyPem);
    var md = forge.md.sha256.create();
    md.update(data, 'utf8');
    var decodedSignature = forge.util.decode64(signature);
    return publicKey.verify(md.digest().bytes(), decodedSignature);
}
// POW 签名示例
function mineForNonce(nickname, difficulty) {
    var nonce = 0;
    var prefixStr = '0'.repeat(difficulty);
    while (true) {
        var data = "".concat(nickname).concat(nonce);
        var hash_1 = (0, crypto_1.createHash)('sha256').update(data).digest('hex');
        if (hash_1.startsWith(prefixStr)) {
            return { nonce: nonce, hash: hash_1 };
        }
        nonce++;
    }
}
// 主程序
var _a = generateKeyPair(), publicKey = _a.publicKey, privateKey = _a.privateKey;
var nickname = "YunsChou"; // 替换为您的昵称
var difficulty = 4;
var _b = mineForNonce(nickname, difficulty), nonce = _b.nonce, hash = _b.hash;
var dataToSign = "".concat(nickname).concat(nonce);
var signature = signData(privateKey, dataToSign);
console.log("Nonce: ".concat(nonce));
console.log("Hash: ".concat(hash));
console.log("Signature: ".concat(signature));
// 验证签名
var isVerified = verifySignature(publicKey, dataToSign, signature);
console.log("Signature Verified: ".concat(isVerified));
