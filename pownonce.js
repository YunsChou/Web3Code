"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var crypto_1 = require("crypto");
function mine(nickname, difficulty) {
    var nonce = 0;
    var prefixStr = '0'.repeat(difficulty); // 这里使用 repeat 方法
    var startTime = Date.now();
    while (true) {
        var inputStr = "".concat(nickname).concat(nonce);
        var hashResult = (0, crypto_1.createHash)('sha256').update(inputStr).digest('hex');
        if (hashResult.startsWith(prefixStr)) {
            var elapsedTime = (Date.now() - startTime) / 1000;
            console.log("Nonce: ".concat(nonce));
            console.log("Hash: ".concat(hashResult));
            console.log("Time taken: ".concat(elapsedTime.toFixed(2), " seconds\n"));
            return;
        }
        nonce++;
    }
}
var nickname = "YunsChou"; // 替换为你的昵称
console.log("Mining for 4 leading zeros:");
mine(nickname, 4);
console.log("Mining for 5 leading zeros:");
mine(nickname, 5);
