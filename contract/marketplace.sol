// SPDX-License-Identifier: MIT
//dev note: add quantity attribute;
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Marketplace {

    uint internal productsLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Product {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        Logistics logistics;
        
    }
    struct Logistics{
        uint quantity;
        uint sold;
        uint price;
    }

    mapping (uint => Product) internal products;

    modifier onlyOwner(uint _index){
        require(msg.sender == products[_index].owner, "only Owner can access this function");
        _;
    }

    function writeProduct(
        string memory _name,
        string memory _image,
        string memory _description, 
        string memory _location, 
        uint _price,
        uint _quantity
    
    ) public {
        uint _sold = 0;
        products[productsLength] = Product(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            Logistics(
                _quantity,
                _sold,
                _price
            )
        );
        productsLength++;
    }

    function buyProduct(uint _index) public payable  {
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            products[_index].owner,
            products[_index].logistics.price
          ),
          "Transfer failed."
        );
        products[_index].logistics.sold++;
        products[_index].logistics.quantity--;
    }

    function addStock(uint _index, uint _quantity) pulbic onlyOwner(_index){
        products[_index].logistics.quantity += _quantity;

    }

    function changePrice(uint _index, uint _price) public onlyOwner(_index){
        products[_index].logistics.price = _price;
    }

    
    function readLogistics(uint _index)public view returns(string memory){
            string memory temp;
            uint val;
            temp ="Price" ;
            val = products[_index].logistics.price;
            temp = string(bytes.concat(bytes(temp) ,": ",bytes(Strings.toString(val))));
            val = products[_index].logistics.sold;
            temp = string(bytes.concat(bytes(temp) ,"    Sold: ",bytes(Strings.toString(val))));
            val = products[_index].logistics.quantity;
            temp = string(bytes.concat(bytes(temp) ,"    Quantity: ",bytes(Strings.toString(val))));
        return(
        temp
        );
    }
    function getLogistics(uint _index) public view returns (
        uint,
        uint,
        uint
    ){
        return ( 
            products[_index].logistics.price,
            products[_index].logistics.sold,
            products[_index].logistics.quantity
        );
    }
    function readProduct(uint _index) public view returns (
        address payable,
        string memory, 
        string memory, 
        string memory, 
        string memory, 
        string memory
    ) {
        return (
            products[_index].owner,
            products[_index].name, 
            products[_index].image, 
            products[_index].description, 
            products[_index].location, 
            readLogistics(_index)            
        );
    }
   
    
    function getProductsLength() public view returns (uint) {
        return (productsLength);
    }
}