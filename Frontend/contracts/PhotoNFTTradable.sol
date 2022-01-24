// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {PhotoNFT} from "./PhotoNFT.sol";
import {PhotoNFTData} from "./PhotoNFTData.sol";

/**
 * @title - PhotoNFTTradable contract
 * @notice - This contract has role that put on sale of photoNFTs
 */
contract PhotoNFTTradable {
    event TradeStatusChange(address ad, bytes32 status);
    event TradePremiumStatusChange(address ad, bool status);
    event OpenTradeInfo(address owner, address sender);

    //cjh
    // PhotoNFT public photoNFT;
    PhotoNFTData public photoNFTData;

    struct Trade {
        address seller;
        uint256 photoId; // PhotoNFT's token ID
        uint256 photoPrice;
        bytes32 status; // Open, Executed, Cancelled
        bool premiumStatus; // false : not , true: premium
    }
    mapping(address => Trade) public trades; // [Key]: PhotoNFT's token ID

    uint256 tradeCounter;

    constructor(PhotoNFTData _photoNFTData) public {
        photoNFTData = _photoNFTData;
        tradeCounter = 0;
    }

    /**
     * @notice - This method is only executed when a seller create a new PhotoNFT
     * @dev Opens a new trade. Puts _photoId in escrow.
     * @param _photoId The id for the photoId to trade.
     * @param _photoPrice The amount of currency for which to trade the photoId.
     */
    function registerTradeWhenCreateNewPhotoNFT(
        PhotoNFT photoNFT,
        uint256 _photoId,
        uint256 _photoPrice,
        address seller
    ) public {
        // photoNFT.transferFrom(msg.sender, address(this), _photoId);

        tradeCounter += 1; /// [Note]: New. Trade count is started from "1". This is to align photoId

        //cjh
        // trades[tradeCounter] = Trade({
        trades[address(photoNFT)] = Trade({
            seller: seller,
            photoId: _photoId,
            photoPrice: _photoPrice,
            status: "Cancelled",
            premiumStatus: false
        });
        //tradeCounter += 1;  /// [Note]: Original
        // emit TradeStatusChange(address(photoNFT), "Open");
    }

    /**
     * @dev Opens a trade by the seller.
     */
    function openTrade(
        PhotoNFT photoNFT,
        uint256 _photoId,
        uint256 price
    ) public {
        Trade storage trade = trades[address(photoNFT)];
        require(
            msg.sender == trade.seller,
            "Trade can be open only by seller."
        );
        // emit OpenTradeInfo(msg.sender, trade.seller);

        photoNFTData.updateStatus(photoNFT, "Open", price);
        photoNFT.transferFrom(msg.sender, address(this), trade.photoId);
        // trades[photoNFT].status = "Open";
        //cjh
        trade.status = "Open";
        emit TradeStatusChange(address(photoNFT), "Open");
    }

    /**
     * @dev Cancels a trade by the seller.
     */
    function cancelTrade(PhotoNFT photoNFT, uint256 _photoId) public {
        Trade storage trade = trades[address(photoNFT)];

        require(
            msg.sender == trade.seller,
            "Trade can be cancelled only by seller."
        );
        // require(trade.status == "Open", "Trade is not Open.");

        photoNFTData.updateStatus(photoNFT, "Cancelled", 0);
        photoNFT.transferFrom(address(this), trade.seller, trade.photoId);
        trade.status = "Cancelled";
        emit TradeStatusChange(address(photoNFT), "Cancelled");
    }

    /**
     * @dev Opens a trade by the seller.
     */
    function updatePremiumStatus(
        PhotoNFT photoNFT,
        uint256 _photoId,
        bool _newState
    ) public {
        Trade storage trade = trades[address(photoNFT)];
        require(
            msg.sender == trade.seller,
            "Trade can be open only by seller."
        );
        photoNFTData.updatePremiumStatus(photoNFT, _newState);

        trade.premiumStatus = _newState;
        emit TradePremiumStatusChange(address(photoNFT), _newState);
    }

    /**
     * @dev Executes a trade. Must have approved this contract to transfer the amount of currency specified to the seller. Transfers ownership of the photoId to the filler.
     */
    function transferOwnershipOfPhotoNFT(
        PhotoNFT _photoNFT,
        uint256 _photoId,
        address _buyer
    ) public {
        PhotoNFT photoNFT = _photoNFT;

        Trade memory trade = getTrade(_photoNFT);
        require(trade.status == "Open", "Trade is not Open.");

        _updateSeller(_photoNFT, _photoId, _buyer);

        //cjh

        photoNFT.transferFrom(address(this), _buyer, trade.photoId);
        trade.status = "Cancelled";
        emit TradeStatusChange(address(_photoNFT), "Cancelled");
    }

    function _updateSeller(
        PhotoNFT photoNFT,
        uint256 _photoId,
        address _newSeller
    ) internal {
        Trade storage trade = trades[address(photoNFT)];
        trade.seller = _newSeller;
    }

    /**
     * @dev - Returns the details for a trade.
     */
    function getTrade(PhotoNFT photoNFT)
        public
        view
        returns (Trade memory trade_)
    {
        Trade memory trade = trades[address(photoNFT)];
        return trade;
        //return (trade.seller, trade.photoId, trade.photoPrice, trade.status);
    }
}
