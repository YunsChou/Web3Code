"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
var viem_1 = require("viem");
var chains_1 = require("viem/chains");
var client = (0, viem_1.createPublicClient)({
    chain: chains_1.sepolia,
    transport: (0, viem_1.http)(),
});
// 合约地址
var contractAddress = '0xaaD4892271392d72419c38dCac8FDA74c92D4a18'; // 替换为您的合约地址
var locksCount = 11; // 假设有 11 个锁
// 每个 LockInfo 结构体占用 3 个存储槽
var lockInfoSlotSize = 3;
// 辅助函数：读取存储槽
function getStorageAt(slot) {
    return __awaiter(this, void 0, void 0, function () {
        var hexSlot;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    hexSlot = "0x".concat(slot.toString(16));
                    return [4 /*yield*/, client.getStorageAt({
                            address: contractAddress,
                            slot: hexSlot,
                        })];
                case 1: return [2 /*return*/, _a.sent()];
            }
        });
    });
}
// 主函数：获取锁信息
function getLockInfo() {
    return __awaiter(this, void 0, void 0, function () {
        var i, userSlot, startTimeSlot, amountSlot, user, startTime, amount, error_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _a.trys.push([0, 7, , 8]);
                    i = 0;
                    _a.label = 1;
                case 1:
                    if (!(i < locksCount)) return [3 /*break*/, 6];
                    return [4 /*yield*/, getStorageAt(i * lockInfoSlotSize)];
                case 2:
                    userSlot = _a.sent();
                    return [4 /*yield*/, getStorageAt(i * lockInfoSlotSize + 1)];
                case 3:
                    startTimeSlot = _a.sent();
                    return [4 /*yield*/, getStorageAt(i * lockInfoSlotSize + 2)];
                case 4:
                    amountSlot = _a.sent();
                    user = userSlot ? "0x".concat(userSlot.slice(26)) : '0x0';
                    startTime = startTimeSlot ? parseInt(startTimeSlot, 16) : 0;
                    amount = amountSlot ? BigInt(amountSlot).toString() : '0';
                    console.log("locks[".concat(i, "]: user: ").concat(user, ", startTime: ").concat(startTime, ", amount: ").concat(amount));
                    _a.label = 5;
                case 5:
                    i++;
                    return [3 /*break*/, 1];
                case 6: return [3 /*break*/, 8];
                case 7:
                    error_1 = _a.sent();
                    console.error('Error fetching lock information:', error_1);
                    return [3 /*break*/, 8];
                case 8: return [2 /*return*/];
            }
        });
    });
}
// 执行获取锁信息的函数
getLockInfo();
