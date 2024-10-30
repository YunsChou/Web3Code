import {
  NFTList as NFTListEvent,
  NFTSold as NFTSoldEvent
} from "../generated/NFTMarket/NFTMarket"
import { NFTList, NFTSold } from "../generated/schema"

export function handleNFTList(event: NFTListEvent): void {
  let entity = new NFTList(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.seller = event.params.seller
  entity.nftAddress = event.params.nftAddress
  entity.nftTokenId = event.params.nftTokenId
  entity.payToken = event.params.payToken
  entity.payPrice = event.params.payPrice

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleNFTSold(event: NFTSoldEvent): void {
  let entity = new NFTSold(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.buyer = event.params.buyer
  entity.nftAddress = event.params.nftAddress
  entity.nftTokenId = event.params.nftTokenId
  entity.payToken = event.params.payToken
  entity.payPrice = event.params.payPrice

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
