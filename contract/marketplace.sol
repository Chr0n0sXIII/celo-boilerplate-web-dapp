// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Marketplace {
    // event that is emitted when a product is restocked
    event Restock(uint index, uint amount);

    uint private productsLength = 0;
    address internal cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Product {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        Logistics logistics;
    }
    struct Logistics {
        uint quantity;
        uint sold;
        uint price;
    }

    mapping(uint => Product) private products;
    mapping(uint => bool) private _exists;

    /// @dev ensures product with id _index exists
    modifier exists(uint _index) {
        require(_exists[_index], "Query of nonexistent product");
        _;
    }

    /**
     * @dev creates a new product on the blockchain
     * @notice the input data must not contain empty values
     */
    function writeProduct(
        string calldata _name,
        string calldata _image,
        string calldata _description,
        string calldata _location,
        uint _price,
        uint _quantity
    ) public {
        require(bytes(_name).length > 0, "Empty name");
        require(bytes(_image).length > 0, "Empty image");
        require(bytes(_description).length > 0, "Empty description");
        require(bytes(_location).length > 0, "Empty loca_location");
        require(_price > 0, "Price needs to be at least one wei");
        require(_quantity > 0, "Quantity needs to be at least one");
        uint _sold = 0;
        products[productsLength] = Product(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            Logistics(_quantity, _sold, _price)
        );
        _exists[productsLength] = true;
        productsLength++;
    }

    /// @return Product details with _index
    /// @notice Logistics also returns the logistics of product
    function readProduct(uint _index) public view exists(_index) returns (Product memory) {
        return (products[_index]);
    }

    /**
     * @dev allow users to buy a product with id of _index
     * @notice an Amount for number of products needs to be specified
     */
    function buyProduct(uint _index, uint amount) public payable exists(_index) {
        Product storage currentProduct = products[_index];
        require(
            currentProduct.owner != msg.sender,
            "You can't buy your own product"
        );
        require(
            currentProduct.logistics.quantity >= amount,
            "Amount can't be fulfilled by the current inventory of product"
        );

        uint newSoldAmount = currentProduct.logistics.sold + amount;
        uint newQuantity = currentProduct.logistics.quantity - amount;

        currentProduct.logistics.sold = newSoldAmount;
        currentProduct.logistics.quantity = newQuantity;
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                currentProduct.owner,
                currentProduct.logistics.price * amount
            ),
            "Transfer failed."
        );
    }

    /**
     * @dev allow products' owners to restock their inventory
     * @notice an amount needs to be specified
     */
    function reStockProduct(uint _index, uint amount) public exists(_index) {
        Product storage currentProduct = products[_index];
        require(currentProduct.owner == msg.sender, "Unauthorized caller");

        uint newQuantity = currentProduct.logistics.quantity + amount;
        currentProduct.logistics.quantity = newQuantity;
        emit Restock(_index, amount);
    }

    function getProductsLength() public view returns (uint) {
        return (productsLength);
    }
}
