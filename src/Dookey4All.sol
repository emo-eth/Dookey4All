// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IDelegationRegistry } from "./IDelegationRegistry.sol";
import { ERC721TokenReceiver } from "solmate/tokens/ERC721.sol";
import { IERC721 } from "forge-std/interfaces/IERC721.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC1155 } from "forge-std/interfaces/IERC1155.sol";

/**
 * @title  Dookey4All
 * @author emo.eth
 * @notice When provided with a Sewer Pass via safeTransferFrom, allow anyone to add themselves as a delegate using the
 *         DelegationRegistry and play the Dookey Dash game.
 *         The original owner of the Sewer Pass can withdraw it at any time by calling withdrawSewerPass; after which
 *         anyone else can provide their own Sewer Pass to the contract.
 */
contract Dookey4All is ERC721TokenReceiver {
    /// @dev Emitted when a sewer pass is deposited
    event Sponsored(address indexed sponsor, uint256 indexed passId);
    /// @dev Emitted when a sewer pass is withdrawn
    event SponsorshipWithdrawn(address indexed sponsor, uint16 indexed passId);

    /// @dev Thrown when an ERC721 that is not the SewerPass tries to call onERC721Received
    error OnlySewerPass();
    /// @dev Thrown when SewerPass calls onERC721Received and there is already a sponsor
    error AlreadySponsored();
    /// @dev Thrown when a caller that is not the sponsor calls the withdrawSewerPass function
    error OnlySponsor();
    /// @dev Thrown when a caller tries to add themselves as a delegate when there is no sponsor
    error NoSponsor();
    /// @dev Thrown when a caller that is not the deployer tries to call the rescueToken function
    error OnlyDeployer();
    /// @dev Thrown when the deployer tries to "rescue" the sponsored token
    error CannotRescueSponsoredToken();

    /// @dev constant references to the delegation registry and sewer pass
    IDelegationRegistry constant DELEGATION_REGISTRY = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);
    IERC721 constant SEWER_PASS = IERC721(0x764AeebcF425d56800eF2c84F2578689415a2DAa);

    /// @dev store the deployer in case someone sends tokens to the contract without using safeTransferFrom
    address immutable DEPLOYER;

    /// @dev address that provided the sewer pass
    address public sponsor;
    /// @dev id of the sewer pass provided
    uint16 public passId;

    constructor() {
        // set the deployer
        DEPLOYER = msg.sender;
    }

    /**
     * @notice Add the caller as a delegate for this address
     */
    function delegateSelf() public {
        // don't let users delegate themselves if there is no sponsor
        if (sponsor == address(0)) {
            revert NoSponsor();
        }
        DELEGATION_REGISTRY.delegateForAll(msg.sender, true);
    }

    /**
     * @notice Allows the sponsor to withdraw their sewer pass, which will reset the sponsor and passId.
     */
    function withdrawSewerPass() external {
        address _sponsor = sponsor;
        if (msg.sender != _sponsor) {
            revert OnlySponsor();
        }
        uint16 _passId = passId;
        sponsor = address(0);
        passId = 0;
        SEWER_PASS.transferFrom(address(this), _sponsor, _passId);
        emit SponsorshipWithdrawn(_sponsor, _passId);
    }

    /**
     * @notice Override the onERC721Received function to only allow a single sewer pass to be sent to this smart
     *         contract, and to record its original owner (the "sponsor") and its specific ID.
     */
    function onERC721Received(
        address,
        address from,
        uint256 id,
        bytes calldata
    )
        external
        virtual
        override
        returns (bytes4)
    {
        // reject calls from tokens that are not the sewer pass
        if (msg.sender != address(SEWER_PASS)) {
            revert OnlySewerPass();
        }
        // if there is already a sponsor, reject the call
        if (sponsor != address(0)) {
            revert AlreadySponsored();
        }
        // store the address that owned the sewer pass as the "sponsor"
        sponsor = from;
        // store the specific ID of the sewer pass (max ID is 30,000 which is < 65,535)
        passId = uint16(id);
        // emit an event
        emit Sponsored(from, id);
        // return the ERC721TokenReceiver.onERC721Received selector
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    /**
     * @notice Rescue tokens that were sent to this contract without using safeTransferFrom. Only callable by the
     *         deployer, and disallows the deployer from removing the sponsored token.
     */
    function rescueToken(address tokenAddress, bool erc20, uint256 id) external {
        // restrict to deployer
        if (msg.sender != DEPLOYER) {
            revert OnlyDeployer();
        }
        if (erc20) {
            // transfer entire ERC20 balance to the deployer
            IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
        } else {
            // allow rescuing sewer pass tokens, but not the sponsored token
            // sewer pass tokens which are *not* the sponsored token can be transferred using normal transferFrom
            // but the cononERC721Received will not be invoked to register them as the sponsored token, so they cannot
            // be withdrawn otherwise
            if (tokenAddress == address(SEWER_PASS) && id == passId) {
                revert CannotRescueSponsoredToken();
            }
            // transfer the token to the deployer
            IERC721(tokenAddress).transferFrom(address(this), msg.sender, id);
        }
        // no need to cover ERC1155 since they only implement safeTransferFrom, and this contract will reject them all
        // same with ether as there are no payable methods; those who selfdestruct, etc funds should expect to lose them
    }
}
