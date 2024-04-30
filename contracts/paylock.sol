// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.7.0;

contract Paylock {
    
    enum State { Working , Completed , Done_1 , Delay , Done_2 , Forfeit }
    
    int disc;
    State st;

    int clock;
    int timeUnit = 4;

    address timeAdd;
    
    constructor(address _timeAdd) public {
        st = State.Working;
        disc = 0;
        clock = 0;
        timeAdd = _timeAdd;
    }

    function signal() public {
        require( st == State.Working );
        st = State.Completed;
        disc = 10;
    }

    function collect_1_Y() public {
        require( st == State.Completed );
        require(clock < timeUnit);
        st = State.Done_1;
        disc = 10;
    }

    function collect_1_N() external {
        require( st == State.Completed );
        require(clock >= timeUnit);
        st = State.Delay;
        disc = 5;
    }

    function collect_2_Y() external {
        require( st == State.Delay );
        require(clock < timeUnit*2);
        st = State.Done_2;
        disc = 5;
    }

    function collect_2_N() external {
        require( st == State.Delay );
        require(clock >= timeUnit*2);
        st = State.Forfeit;
        disc = 0;
    }

    function tick() external {
        require(msg.sender == timeAdd);
        clock ++;
    }
}

contract Supplier {
    
    Paylock public p;
    Rental public r;

    enum State { Working , Completed }
    
    State st;
    bool hasResouce = false;
    
    constructor(address pp,address payable rr) public {
        p = Paylock(pp);
        r = Rental(rr);
        st = State.Working;
    }
    
    function finish() external {
        require (st == State.Working);
        p.signal();
        st = State.Completed;
    }

    function aquire_resource() external payable {
        require(!hasResouce,"already rental resouce");
        r.rent_out_resource.value(msg.value)();
        hasResouce = true;
    }

    function return_resource() external {
        require(hasResouce,"not rental resouce");
        r.retrieve_resource();
        hasResouce = false;
    }

     // receive function to handle incoming ether
    event Receive(address,uint); 
    receive() external payable { 
        emit Receive(msg.sender, msg.value);
    }
    // fallback function - where the magic happens
    event Fallback(address,uint);
    fallback() external payable { 
        emit Fallback(msg.sender, msg.value);
    }

    function send() external payable returns (string memory ss){
        return "转账成功";
    }
}

contract Rental {
    address resource_owner;
    bool resource_available;
    uint deposit = 1 wei;
    // mapping (address=>uint) balanceOf;
    constructor() public {
        resource_available = true;
    }
    
    function rent_out_resource() external payable {  
        require(resource_available == true,"resource already rental");
        //CHECK FOR PAYMENT HERE
        require(msg.value >= 1 wei, "LT 1 wei");
        // balanceOf[msg.sender] = msg.value;
        resource_owner = msg.sender;
        resource_available = false;
    }

    function retrieve_resource() external {
        require(resource_available == false && msg.sender == resource_owner,"resource not rental");
        //RETURN DEPOSIT HERE
        address payable x = payable(address(msg.sender));
        (bool success,) = x.call.value(address(this).balance)(abi.encodeWithSignature("receive()"));
        require(success,"Transfer failed");
        resource_owner = address(0);
        resource_available = true;
    }
}