// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract LemonadeStand {
    
    address owner;
    uint skuCount;
    
    enum State { ForSale, Sold, Shipped }
    
    struct Item {
        string name;
        uint sku;
        uint price;
        State state;
        address seller;
        address buyer;
    }
    
    // Define mapping 'items' that maps the SKU (a number) to an Item.
    mapping (uint => Item) items;
    
    // Events
    event ForSale(uint skuCount);
    event Sold(uint sku);
    event Shipped(uint sku);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier verifyCaller (address _address) {
        require(msg.sender == _address);
        _;
    }
    
    modifier paidEnough(uint _price) {
        require(msg.value >= _price);
        _;
    }
    
    modifier forSale(uint _sku) {
        require(items[_sku].state == State.ForSale);
        _;
    }
    
    modifier sold(uint _sku) {
        require(items[_sku].state == State.Sold);
        _;
    }
    
    modifier checkValue(uint _sku) {
        _;
        uint _price = items[_sku].price;
        uint amountToRefund = msg.value - _price;
        payable(items[_sku].buyer).transfer(amountToRefund);
    }
    
    // Constructor
    constructor() {
        owner = msg.sender;
        skuCount = 0;
    }
    
    function addItem(string memory _name, uint _price) onlyOwner public {
        // Increment sku
        skuCount = skuCount + 1;
        
        // emit the appropriate event
        emit ForSale(skuCount);
        
        // Add the new item into inventory and mark it for sale
        items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
    }
    
    function buyItem(uint sku) forSale(sku) paidEnough(items[sku].price) checkValue(sku) public payable {
        address buyer = msg.sender;
        uint price = items[sku].price;
        // Update buyer
        items[sku].buyer = buyer;
        // Update State
        items[sku].state = State.Sold;
        // Transfer money to the seller
        payable(items[sku].seller).transfer(price);
        // emit the appropriate event
        emit Sold(sku);
    }
    
    function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, string memory stateIs, address seller, address buyer) {
        uint state;
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint(items[_sku].state);
        if (state == 0) {
            stateIs = "For Sale";
        }
        if (state == 1) {
            stateIs = "Sold";
        }
        if (state == 2) {
            stateIs = "Shipped";
        }
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
    }
    
    function shipItem(uint _sku) sold(_sku) verifyCaller(items[_sku].seller) public {
        items[_sku].state = State.Shipped;
        emit Shipped(_sku);
    }
    
}