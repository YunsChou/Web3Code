import { createPublicClient, http } from "viem";
import { mainnet } from "viem/chains";

const publicClient = createPublicClient({
    chain: mainnet,
    transport: http()
})

async function watchEthBlock() {
    const unwatch = publicClient.watchBlocks(
        {
            onBlock: block => {
                console.log("-->> block number: ", block.number);
                console.log("-->> block hash: ", block.hash);
            }
        }
    )
}

watchEthBlock();