// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../lib/gyro-pools/IOneSidedECLPJoiner.sol";
import "../src/L2Gyd.sol";
import {IERC20} from "oz/token/ERC20/IERC20.sol";

contract OneSidedECLPJoinerLiveTest is Test {
    IOneSidedECLPJoiner joiner = IOneSidedECLPJoiner(0xA0a555c1c11ef36D2381768EB734Fa2bddf1322b);
    L2Gyd l2gyd = L2Gyd(0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8);

    address alice = makeAddr("alice");
    address router = 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8;
    address l1escrow = 0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8;
    address bootstrapping_pool_addr = 0x820b69faD931d4b4Bf14E70fF234A8390F6A0658;

    // Here this is stataUSDC
    address other_token_addr = 0x7CFaDFD5645B50bE87d546f42699d863648251ad; 

    uint64 mainnetChainSelector = 3_734_403_246_176_062_136;

    uint256 MAX_UNDEPLOYED_PERCENTAGE = 1e-4 * 1e18;  // 1bp

    function setUp() public {
        // Fork arbitrum.
        // Block from: Mon Nov  4 16:57:12 CET 2024
        vm.createSelectFork(vm.envString("ARBITRUM_RPC_URL"), 270993705);
    }

    function testExecutionNormal1() public {
        _testExecutionNormal(1e6 * 1e18);
    }

    function testExecutionNormal2() public {
        _testExecutionNormal(1e4 * 1e18);
    }

    /// @notice Tests a "normal" execution, where some address approves tokens, then calls into
    /// the joiner.
    function _testExecutionNormal(uint256 amount_in_s) internal {
        // First, fund alice with GYD from the bridge. We have to jump through all of the hoops
        // unfortunately.
        vm.startPrank(router);
        bytes memory data = abi.encode(alice, amount_in_s, "");
        l2gyd.ccipReceive(
          _receivedMessage(mainnetChainSelector, l1escrow, data)
        );
        vm.stopPrank();

        // Now, call into the joiner.
        vm.startPrank(alice);
        l2gyd.approve(address(joiner), amount_in_s);
        joiner.joinECLPOneSided(bootstrapping_pool_addr, address(l2gyd), amount_in_s, alice);
        vm.stopPrank();

        IERC20 lp_token = IERC20(bootstrapping_pool_addr);
        IERC20 gyd_token = IERC20(address(l2gyd));
        IERC20 other_token = IERC20(other_token_addr);

        // joiner has no tokens left
        assertEq(lp_token.balanceOf(address(joiner)), 0);
        assertEq(gyd_token.balanceOf(address(joiner)), 0);
        assertEq(other_token.balanceOf(address(joiner)), 0);
        
        // alice now has tokens as expected
        assertGt(lp_token.balanceOf(alice), 0);
        assertEq(other_token.balanceOf(alice), 0);

        // not too many tokens are leftover
        uint256 undeployed_gyd = gyd_token.balanceOf(alice);
        console.log("Total undeployed GYD", undeployed_gyd);
        console.log("Bp/100 undeployed (approximate)", divDown(undeployed_gyd, amount_in_s) * 1e6 / 1e18);
        assertLe(undeployed_gyd, mulDown(amount_in_s, MAX_UNDEPLOYED_PERCENTAGE));
    }

    function testExecutionCCIP1() public {
        _testExecutionCCIP(1e6 * 1e18);
    }

    function testExecutionCCIP2() public {
        _testExecutionCCIP(1e4 * 1e18);
    }

    /// @notice Tests an execution where the contract is called from CCIP using its special method.
    function _testExecutionCCIP(uint256 amount_in_s) internal {
        bytes memory call_data = abi.encodeWithSelector(
            joiner.joinECLPOneSidedCCIP.selector,
            bootstrapping_pool_addr,
            address(l2gyd),
            alice
        );

        vm.startPrank(router);
        bytes memory data = abi.encode(address(joiner), amount_in_s, call_data);
        l2gyd.ccipReceive(
          _receivedMessage(mainnetChainSelector, l1escrow, data)
        );
        // TODO this fails.
        vm.stopPrank();
        // TODO ^ assert that it does NOT emit the failure event.

        // After this, everything should look just like above:

        IERC20 lp_token = IERC20(bootstrapping_pool_addr);
        IERC20 gyd_token = IERC20(address(l2gyd));
        IERC20 other_token = IERC20(other_token_addr);

        // joiner has no tokens left
        assertEq(lp_token.balanceOf(address(joiner)), 0);
        assertEq(gyd_token.balanceOf(address(joiner)), 0);
        assertEq(other_token.balanceOf(address(joiner)), 0);
        
        // alice now has tokens as expected
        assertGt(lp_token.balanceOf(alice), 0);
        assertEq(other_token.balanceOf(alice), 0);

        // not too many tokens are leftover
        uint256 undeployed_gyd = gyd_token.balanceOf(alice);
        console.log("Total undeployed GYD", undeployed_gyd);
        console.log("Bp/100 undeployed (approximate)", divDown(undeployed_gyd, amount_in_s) * 1e6 / 1e18);
        assertLe(undeployed_gyd, mulDown(amount_in_s, MAX_UNDEPLOYED_PERCENTAGE));
    }

    function _receivedMessage(
      uint64 chainSelector,
      address senderContract,
      bytes memory data
    ) internal pure returns (Client.Any2EVMMessage memory) {
      return Client.Any2EVMMessage({
        messageId: 0,
        sourceChainSelector: chainSelector,
        sender: abi.encode(senderContract),
        data: data,
        destTokenAmounts: new Client.EVMTokenAmount[](0)
      });
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b / 1e18;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * 1e18 / b;
    }
}
