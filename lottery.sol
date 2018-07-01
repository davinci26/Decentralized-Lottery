pragma solidity ^0.4.4;

contract lottery {

  uint constant exchange_rate = 1;
  uint constant threshold = 1000;
  uint256 locked_time = 1;
  uint256 SEED = 0;
  
  address owner;
  bool emergency = false;
  
  // Owner can disable the contract
  function set_emergency() external {
      require(msg.sender == owner);
      emergency = true;
  }

  // Check if its an emergency
  modifier not_emergency() {
        require(!emergency);
        _;
  }
  
  // Require that all the participants of the lottery have revealed their commits
  modifier all_commits_opened() {
      require(total_tokens==threshold);
      bool time_flag = now > locked_time + 2 days;
      bool commit_flag = true ;
      for (uint ii = total_users_l; ii<total_users_u; ii++) {
        bool tmp = user_info[user_addresses[msg.sender]].revealed;
        if (!tmp && time_flag) {
            user_info[user_addresses[msg.sender]].tokens == 0;
            total_tokens -= user_info[user_addresses[msg.sender]].tokens;
        }
        commit_flag = commit_flag && tmp;
      }
      require(commit_flag || time_flag);
      _;
  }
  
  struct account {
      bytes32 commited_nonce;
      address user_adress;
      uint256 nonce;
      uint256 tokens;
      bool revealed;
  }
  
  function uint_sub(uint256 a, uint256 b) returns (uint256){
        if (a > b) {
            return a-b;
        }
        return 0;
    }
  
  // Mapping Unique ID to account
  mapping (uint => account) private user_info;
  // Mapping from Eth address to Unique ID
  mapping (address => uint) private user_addresses;
  // Mapping from Eth address to returns (Push - Pull Technique)
  mapping (address => uint) private token_returns;
  
  // Helper Variables for each lottery
  uint  public total_tokens = 1;
  uint   total_users_l = 1;
  uint   total_users_u = 1;
  
  function optimized_lot() {
      owner = msg.sender;
  }

  /**
  @title buy_tickets:
  @dev Allows nodes to exchange ether for lottery tokens at a fixed exchange rate.
  @param commitment User commitment (SHA-3) to a random string
  */
  
  function buy_tickets(bytes32 commitment) payable external not_emergency {
    require(msg.value >= exchange_rate);
    require(total_tokens < threshold);
    uint amount = (msg.value) / exchange_rate;
    token_returns[msg.sender] += (msg.value) % exchange_rate;
    // If the user is a new user add him to the unique users mapping.
    if (user_addresses[msg.sender]==0) {
      user_info[total_users_u].commited_nonce = commitment;
      user_info[total_users_u].user_adress = msg.sender;
      total_users_u++;
    }
    token_returns[msg.sender] += uint_sub(amount + total_tokens,threshold);
    amount -= uint_sub(amount + total_tokens,threshold);
    user_info[total_users_u].tokens += amount;
    total_tokens += amount;
  }
  /**
  @title reveal_commits:
  @dev Allows nodes to reveal their commitments
  @param nonce_ The string that the user commited to when he bought the tickets
  */
  
  function reveal_commits(uint256 nonce_) external not_emergency {
    require(total_tokens==threshold);
    require(user_addresses[msg.sender]!=0); 
    require(!user_info[user_addresses[msg.sender]].revealed);
    require(keccak256(nonce_) == user_info[user_addresses[msg.sender]].commited_nonce);
    user_info[user_addresses[msg.sender]].nonce = nonce_;
    SEED += nonce_;
    locked_time = block.timestamp;
  }
  /**
  * @dev make_lottery initiliaze the lottery and assigns the returns to an adress.
  */
  function make_lottery() external not_emergency all_commits_opened {
    uint random_number = uint(sha3(SEED)) % (total_tokens) + 1;
    uint running_sum = 0; 
    bool found = false;
    for (uint ii = total_users_l; ii<total_users_u; ii++) {
      running_sum += user_info[ii].tokens;
      if (running_sum >= random_number && !found) {
        token_returns[user_info[ii].user_adress] += threshold;
        found = true;
      }
      user_info[ii] = account(bytes32(0),address(0),0,0,false);
      user_addresses[user_info[ii].user_adress] = 0;
    }
    total_users_l = total_users_u;
    total_tokens = 1;
  }


  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function untrusted_withdraw() external returns (bool) {
    uint amount = exchange_rate*token_returns[msg.sender];
    require(amount!=0);
    token_returns[msg.sender] = 0;
    if (!msg.sender.send(amount)) {
      token_returns[msg.sender] = amount / exchange_rate;
      return false;
    }
    return true; 
  }
 
}