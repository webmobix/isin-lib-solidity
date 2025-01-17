// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library ISINLib {
    /// @notice Encodes an ISIN string to a uint256 value.
    /// @param isin The ISIN string to encode (must be uppercase A-Z, 0-9, and 12 characters long).
    /// @return numericValue The uint256 representation of the ISIN.
    function toUint256(
        string memory isin
    ) internal pure returns (uint256 numericValue) {
        bytes memory isinBytes = bytes(isin);
        require(isinBytes.length == 12, "ISIN must be 12 characters long");

        for (uint256 i = 0; i < isinBytes.length; i++) {
            bytes1 ch = isinBytes[i];
            uint256 val;
            if (ch >= "0" && ch <= "9") {
                val = uint256(uint8(ch) - 48);
            } else if (ch >= "A" && ch <= "Z") {
                val = uint256(uint8(ch) - 65 + 10);
            } else {
                revert("Invalid character in ISIN");
            }
            numericValue = numericValue * 36 + val;
        }
    }

    uint256 constant MAX_ISIN_VALUE = 4738381338321616896; // 36^12 - 1

    /// @notice Decodes a uint256 back to an ISIN string.
    /// @param value The uint256 value to decode.
    /// @return isin The original ISIN string.
    function fromUint256(
        uint256 value
    ) internal pure returns (string memory isin) {
        if (value == 0) return "000000000000";

        // Ensure the input value is within the valid ISIN range
        require(value <= MAX_ISIN_VALUE, "Invalid uint256 to decode as ISIN");

        bytes memory isinBytes = new bytes(12); // ISIN is fixed-length

        uint256 index = 12;
        uint256 base = 36;

        // Decode the uint256 into base-36 characters
        while (value > 0) {
            uint256 remainder = value % base;
            bytes1 ch;
            if (remainder < 10) {
                ch = bytes1(uint8(remainder + 48)); // 0-9
            } else {
                ch = bytes1(uint8(remainder - 10 + 65)); // 10-35
            }
            isinBytes[--index] = ch;
            value /= base;
        }

        // Pad with leading zeros if the result is shorter than 12 characters
        while (index > 0) {
            isinBytes[--index] = "0";
        }

        // Return the decoded ISIN as a string
        return string(isinBytes);
    }
}
