import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import { NFTList, NFTSold } from "../generated/NFTMarket/NFTMarket"

export function createNFTListEvent(
  seller: Address,
  nftAddress: Address,
  nftTokenId: BigInt,
  payToken: Address,
  payPrice: BigInt
): NFTList {
  let nftListEvent = changetype<NFTList>(newMockEvent())

  nftListEvent.parameters = new Array()

  nftListEvent.parameters.push(
    new ethereum.EventParam("seller", ethereum.Value.fromAddress(seller))
  )
  nftListEvent.parameters.push(
    new ethereum.EventParam(
      "nftAddress",
      ethereum.Value.fromAddress(nftAddress)
    )
  )
  nftListEvent.parameters.push(
    new ethereum.EventParam(
      "nftTokenId",
      ethereum.Value.fromUnsignedBigInt(nftTokenId)
    )
  )
  nftListEvent.parameters.push(
    new ethereum.EventParam("payToken", ethereum.Value.fromAddress(payToken))
  )
  nftListEvent.parameters.push(
    new ethereum.EventParam(
      "payPrice",
      ethereum.Value.fromUnsignedBigInt(payPrice)
    )
  )

  return nftListEvent
}

export function createNFTSoldEvent(
  buyer: Address,
  nftAddress: Address,
  nftTokenId: BigInt,
  payToken: Address,
  payPrice: BigInt
): NFTSold {
  let nftSoldEvent = changetype<NFTSold>(newMockEvent())

  nftSoldEvent.parameters = new Array()

  nftSoldEvent.parameters.push(
    new ethereum.EventParam("buyer", ethereum.Value.fromAddress(buyer))
  )
  nftSoldEvent.parameters.push(
    new ethereum.EventParam(
      "nftAddress",
      ethereum.Value.fromAddress(nftAddress)
    )
  )
  nftSoldEvent.parameters.push(
    new ethereum.EventParam(
      "nftTokenId",
      ethereum.Value.fromUnsignedBigInt(nftTokenId)
    )
  )
  nftSoldEvent.parameters.push(
    new ethereum.EventParam("payToken", ethereum.Value.fromAddress(payToken))
  )
  nftSoldEvent.parameters.push(
    new ethereum.EventParam(
      "payPrice",
      ethereum.Value.fromUnsignedBigInt(payPrice)
    )
  )

  return nftSoldEvent
}
