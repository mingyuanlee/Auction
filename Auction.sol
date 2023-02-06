pragma solidity ^0.8.4;

contract Auction {

  // A bid contains these information:
  // -> bidAmount
  // -> the timestamp when they bid
  // -> more information can be added
  struct Bid {
    uint amount;
    uint timestamp;
  }

  address payable public beneficiary;
  uint public auctionEndTime;
  
  address public highestBidder;
  uint public highestBidAmount;

  // record the address and its amount stored on the contract
  mapping(address => uint) storedAmount;
  // record the address and its bidHistory
  mapping(address => Bid[]) biddingHistory;

  bool auctionEnded;

  event HighestBidIncreased(address bidder, uint amount);
  event AuctionEnded(address winner, uint amount);

  error AuctionAlreadyEnded();
  error BidNotHighEnough(uint highestBid);
  error AuctionNotYetEnded();
  error AuctionEndAlreadyCalled();

  constructor(
    uint biddingTime,
    address payable _beneficiary
  ) {
    beneficiary = _beneficiary;
    auctionEndTime = block.timestamp + biddingTime;
  }

  function bid() external payable {

    // check if the auction is ended
    if (block.timestamp > auctionEndTime) {
      revert AuctionAlreadyEnded();
    }

    uint previousAmount = storedAmount[msg.sender];
    uint currentAmount = previousAmount + msg.value;

    // check if the bid is the highest
    if (currentAmount <= highestBidAmount) {
      revert BidNotHighEnough(highestBidAmount);
    }

    // update the highest bidder
    highestBidder = msg.sender;
    highestBidAmount = currentAmount;
    storedAmount[highestBidder] = currentAmount;

    // update the bidding history
    biddingHistory[highestBidder].push(Bid({amount: highestBidAmount, timestamp: block.timestamp}));

    emit HighestBidIncreased(msg.sender, msg.value);

  }

  // Let bidders withdraw the store amount by themselves
  function withdraw() external returns (bool) {
    uint amount = storedAmount[msg.sender];
    if (amount > 0) {
      // add the lock to prevent users' consecutive calls in a very short time
      storedAmount[msg.sender] = 0;
      if (!payable(msg.sender).send(amount)) {
        storedAmount[msg.sender] = amount;
        return false;
      }
    }
    return true;
  }

  function endAuction() external {

    if (block.timestamp < auctionEndTime) {
      revert AuctionNotYetEnded();
    }

    if (auctionEnded) {
      revert AuctionEndAlreadyCalled();
    }

    auctionEnded = true;
    emit AuctionEnded(highestBidder, highestBidAmount);

    beneficiary.transfer(highestBidAmount);
  }

}