import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { NFTList } from "../generated/schema"
import { NFTList as NFTListEvent } from "../generated/NFTMarket/NFTMarket"
import { handleNFTList } from "../src/nft-market"
import { createNFTListEvent } from "./nft-market-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let seller = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let nftAddress = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let nftTokenId = BigInt.fromI32(234)
    let payToken = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let payPrice = BigInt.fromI32(234)
    let newNFTListEvent = createNFTListEvent(
      seller,
      nftAddress,
      nftTokenId,
      payToken,
      payPrice
    )
    handleNFTList(newNFTListEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("NFTList created and stored", () => {
    assert.entityCount("NFTList", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "NFTList",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "seller",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "NFTList",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "nftAddress",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "NFTList",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "nftTokenId",
      "234"
    )
    assert.fieldEquals(
      "NFTList",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "payToken",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "NFTList",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "payPrice",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
