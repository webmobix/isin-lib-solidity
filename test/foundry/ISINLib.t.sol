// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/forge-std/src/Test.sol";
import {ISINLib} from "../../src/ISINLib.sol";

contract ISINLibTest is Test {
    using ISINLib for string;

    function testBidirectionalConversion() public pure {
        string[] memory ISINs = new string[](3);
        ISINs[0] = "US9311421039";
        ISINs[1] = "GB0002374006";
        ISINs[2] = "FR0000131104";

        for (uint256 i = 0; i < ISINs.length; i++) {
            uint256 encoded = ISINs[i].toUint256();
            string memory decoded = ISINLib.fromUint256(encoded);
            assertEq(decoded, ISINs[i], "Bidirectional conversion failed");
        }
    }

    function testFromUint256_Zero() public pure {
        string memory result = ISINLib.fromUint256(0);
        assertEq(result, "000000000000", "Zero conversion failed");
    }

    function testRevertOnInvalidInput_ToUint256() public {
        vm.expectRevert();
        ISINLib.toUint256("invalid");
    }
}