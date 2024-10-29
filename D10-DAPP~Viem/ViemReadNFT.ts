import { createPublicClient, erc721Abi, http } from "viem";
import { mainnet } from "viem/chains";

const NFT_ADDRESS = '0x0483b0dfc6c78062b9e999a82ffb795925381415'

const publicClient = createPublicClient({
    chain: mainnet,
    transport: http()
})

async function readNFTInfo(tokenId: bigint) {
    console.log(`read contract: ${NFT_ADDRESS}, tokenId: ${tokenId}`);
    console.log('------------------------');

    const owner = await publicClient.readContract({
        address: NFT_ADDRESS,
        abi: erc721Abi,
        functionName: 'ownerOf',
        args: [tokenId]
    })

    const metadata = await publicClient.readContract({
        address: NFT_ADDRESS,
        abi: erc721Abi,
        functionName: 'tokenURI',
        args: [tokenId]
    })

    console.log(`-->> nft-owner: ${owner}`)
    console.log(`-->> nft-metadata: ${metadata}`)
}

readNFTInfo(88n);