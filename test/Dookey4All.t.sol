// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { IDelegationRegistry } from "../src/IDelegationRegistry.sol";
import { ERC721TokenReceiver } from "solmate/tokens/ERC721.sol";
import { IERC721 } from "forge-std/interfaces/IERC721.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { IERC1155 } from "forge-std/interfaces/IERC1155.sol";
import { Dookey4All } from "../src/Dookey4All.sol";
import { TestERC20, ERC20 } from "./helpers/TestERC20.sol";

contract Dookey4AllTest is Test {
    /// @dev constant references to the delegation registry and sewer pass
    IDelegationRegistry constant DELEGATION_REGISTRY = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);
    IERC721 constant SEWER_PASS = IERC721(0x764AeebcF425d56800eF2c84F2578689415a2DAa);
    Dookey4All dookey;
    address deployer = makeAddr("deployer");
    address sponsor2 = makeAddr("sponsor2");

    function setUp() public {
        // fork mainnet for real data
        vm.createSelectFork(getChain("mainnet").rpcUrl);
        vm.prank(deployer);
        dookey = new Dookey4All();
        yoink(SEWER_PASS, 1, address(this));
        yoink(SEWER_PASS, 2, address(this));
        yoink(SEWER_PASS, 3, sponsor2);
    }

    /// @dev Yoink an existing token from a wallet and give it to the recipient
    function yoink(IERC721 token, uint256 id, address recipient) internal {
        address owner = token.ownerOf(id);
        vm.prank(owner);
        token.transferFrom(owner, recipient, id);
    }

    function testErrorNoSponsor() public {
        vm.expectRevert(Dookey4All.NoSponsor.selector);
        dookey.delegateSelf();
    }

    function testErrorOnlyDeployer() public {
        vm.expectRevert(Dookey4All.OnlyDeployer.selector);
        dookey.rescueToken(address(SEWER_PASS), false, 1);
    }

    function testErrorOnlySewerPass() public {
        vm.expectRevert(Dookey4All.OnlySewerPass.selector);
        dookey.onERC721Received(address(this), address(this), 1, "");
    }

    function testSponsor() public {
        SEWER_PASS.safeTransferFrom(address(this), address(dookey), 1);
        assertEq(dookey.sponsor(), address(this));
        assertEq(dookey.passId(), 1);
    }

    function testErrorOnlySponsor() public {
        SEWER_PASS.safeTransferFrom(address(this), address(dookey), 1);
        vm.expectRevert(Dookey4All.OnlySponsor.selector);
        vm.prank(sponsor2);
        dookey.withdrawSewerPass();
    }

    function testErrorAlreadySponsored() public {
        SEWER_PASS.safeTransferFrom(address(this), address(dookey), 1);
        vm.expectRevert(Dookey4All.AlreadySponsored.selector);
        SEWER_PASS.safeTransferFrom(address(this), address(dookey), 2);
    }

    function testNewSponsor() public {
        SEWER_PASS.safeTransferFrom(address(this), address(dookey), 1);
        dookey.withdrawSewerPass();
        assertEq(SEWER_PASS.ownerOf(1), address(this));
        assertEq(dookey.sponsor(), address(0));
        assertEq(dookey.passId(), 0);
        vm.prank(sponsor2);
        SEWER_PASS.safeTransferFrom(address(sponsor2), address(dookey), 3);
        assertEq(dookey.sponsor(), address(sponsor2));
        assertEq(dookey.passId(), 3);
    }

    function testDelegateSelf() public {
        SEWER_PASS.safeTransferFrom(address(this), address(dookey), 1);
        vm.prank(deployer);
        dookey.delegateSelf();
        assertEq(DELEGATION_REGISTRY.checkDelegateForAll(deployer, address(dookey)), true);
    }

    function testRescueTokenErc20() public {
        TestERC20 token = new TestERC20();
        token.mint(address(dookey), 100);
        vm.prank(deployer);
        dookey.rescueToken(address(token), true, 0);
        assertEq(token.balanceOf(address(deployer)), 100);
    }

    function testRescueTokenErc721() public {
        yoink(SEWER_PASS, 69, address(dookey));
        vm.prank(deployer);
        dookey.rescueToken(address(SEWER_PASS), false, 69);
    }

    function testErrorCannotRescueSponsoredToken() public {
        SEWER_PASS.safeTransferFrom(address(this), address(dookey), 1);
        vm.expectRevert(Dookey4All.CannotRescueSponsoredToken.selector);
        vm.prank(deployer);
        dookey.rescueToken(address(SEWER_PASS), false, 1);
    }
}
