// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../ISINLib.sol";

contract TestISIN {
    using ISINLib for string;
    using ISINLib for uint256;

    function toUint256(string calldata isin) external pure returns (uint256) {
        return isin.toUint256();
    }

    function fromUint256(uint256 value) external pure returns (string memory) {
        return value.fromUint256();
    }
}
