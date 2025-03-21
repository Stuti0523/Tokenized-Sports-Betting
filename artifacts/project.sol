// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenizedSportsBetting {

    enum BetStatus { Pending, Won, Lost }

    struct Bet {
        uint256 id;
        address bettor;
        uint256 amount;
        uint256 odds;
        BetStatus status;
        uint256 payout;
    }

    uint256 public betCounter;
    uint256 public totalBets;
    uint256 public totalPayouts;
    mapping(uint256 => Bet) public bets;
    mapping(address => uint256) public tokenBalances;

    event BetPlaced(uint256 betId, address bettor, uint256 amount, uint256 odds);
    event BetResult(uint256 betId, BetStatus status, uint256 payout);
    event TokenTransferred(address from, address to, uint256 amount);

    modifier hasEnoughTokens(address _user, uint256 _amount) {
        require(tokenBalances[_user] >= _amount, "Insufficient funds");
        _;
    }

    modifier betExists(uint256 _betId) {
        require(bets[_betId].id != 0, "Bet does not exist");
        _;
    }

    // Place a bet
    function placeBet(uint256 _odds) external hasEnoughTokens(msg.sender, 1 ether) returns (uint256) {
        require(_odds > 0, "Invalid odds");

        // Place the bet and deduct tokens from the bettor's balance
        betCounter++;
        uint256 betId = betCounter;
        uint256 betAmount = 1 ether; // Fixed bet amount for simplicity
        tokenBalances[msg.sender] -= betAmount;
        
        uint256 payout = betAmount * _odds; // Calculate payout based on the odds
        bets[betId] = Bet({
            id: betId,
            bettor: msg.sender,
            amount: betAmount,
            odds: _odds,
            status: BetStatus.Pending,
            payout: payout
        });

        totalBets++;
        emit BetPlaced(betId, msg.sender, betAmount, _odds);
        return betId;
    }

    // Set the result of the bet (only the owner or the operator can set the result)
    function setBetResult(uint256 _betId, bool _won) external betExists(_betId) {
        Bet storage bet = bets[_betId];
        require(bet.status == BetStatus.Pending, "Bet already resolved");

        if (_won) {
            bet.status = BetStatus.Won;
            tokenBalances[bet.bettor] += bet.payout; // Transfer the payout to the bettor
            totalPayouts += bet.payout;
        } else {
            bet.status = BetStatus.Lost;
        }

        emit BetResult(_betId, bet.status, bet.payout);
    }

    // Deposit tokens into the contract
    function depositTokens() external payable {
        tokenBalances[msg.sender] += msg.value;
    }

    // Withdraw tokens from the contract
    function withdrawTokens(uint256 _amount) external hasEnoughTokens(msg.sender, _amount) {
        tokenBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    // Check bettor's token balance
    function getBalance(address _user) external view returns (uint256) {
        return tokenBalances[_user];
    }

    // View bet details
    function getBetDetails(uint256 _betId) external view returns (Bet memory) {
        return bets[_betId];
    }
}

