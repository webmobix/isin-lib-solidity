// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ISIN Converter Library
/// @notice Library for converting between ISIN strings and uint256 values
/// @dev Optimized for gas efficiency using assembly and unchecked operations
library ISINLib {
    /// @notice Custom errors for better gas efficiency
    error InvalidISINLength();
    error InvalidCharacter();
    error InvalidValue();

    /// @notice Convert ISIN string to uint256
    /// @param isin The ISIN string to convert
    /// @return The uint256 representation of the ISIN
    function toUint256(string calldata isin) internal pure returns (uint256) {
        bytes calldata isinBytes = bytes(isin);
        
        // Check length
        if (isinBytes.length != 12) revert InvalidISINLength();
        
        uint256 result;
        assembly {
            let data := calldataload(isinBytes.offset)
            
            for { let i := 0 } lt(i, 12) { i := add(i, 1) } {
                let char := and(shr(mul(sub(31, i), 8), data), 0xff)
                let value
                
                // Check if digit (0x30-0x39)
                switch and(
                    gte(char, 0x30),
                    lte(char, 0x39)
                )
                case 1 {
                    value := sub(char, 0x30)
                }
                // Check if uppercase letter (0x41-0x5A)
                case 0 {
                    switch and(
                        gte(char, 0x41),
                        lte(char, 0x5A)
                    )
                    case 1 {
                        value := add(sub(char, 0x41), 10)
                    }
                    // Check if lowercase letter (0x61-0x7A)
                    case 0 {
                        switch and(
                            gte(char, 0x61),
                            lte(char, 0x7A)
                        )
                        case 1 {
                            value := add(sub(char, 0x61), 10)
                        }
                        default {
                            // Invalid character
                            revert(0, 0)
                        }
                    }
                }
                
                // Multiply previous result by 36 and add new value
                result := add(mul(result, 36), value)
            }
        }
        
        return result;
    }

    /// @notice Convert uint256 back to ISIN string
    /// @param value The uint256 to convert
    /// @return The ISIN string representation
    function fromUint256(uint256 value) internal pure returns (string memory) {
        // Handle zero case
        if (value == 0) return "000000000000";
        
        bytes memory result = new bytes(12);
        assembly {
            let position := add(result, 43) // 31 + 12
            
            for { let i := 0 } lt(i, 12) { i := add(i, 1) } {
                let remainder := mod(value, 36)
                
                // Convert to character
                let char := remainder
                switch lt(remainder, 10)
                case 1 { char := add(0x30, remainder) }     // 0-9
                default { char := add(0x41, sub(remainder, 10)) }  // A-Z
                
                // Store character
                mstore8(position, char)
                position := sub(position, 1)
                value := div(value, 36)
            }
        }
        
        return string(result);
    }

    /// @notice Check if an ISIN string is valid
    /// @param isin The ISIN string to validate
    /// @return True if the ISIN is valid
    function isValid(string calldata isin) internal pure returns (bool) {
        bytes calldata isinBytes = bytes(isin);
        
        if (isinBytes.length != 12) return false;
        
        bool valid = true;
        assembly {
            let data := calldataload(isinBytes.offset)
            
            for { let i := 0 } lt(i, 12) { i := add(i, 1) } {
                let char := and(shr(mul(sub(31, i), 8), data), 0xff)
                
                // Combine all character validations
                let isValidIsin := or(
                    and(gte(char, 0x30), lte(char, 0x39)),  // 0-9
                    or(
                        and(gte(char, 0x41), lte(char, 0x5A)),  // A-Z
                        and(gte(char, 0x61), lte(char, 0x7A))   // a-z
                    )
                )
                
                if iszero(isValidIsin) {
                    valid := 0
                    break
                }
            }
        }
        
        return valid;
    }

    /// @notice Calculate ISIN checksum digit according to ISO 6166
    /// @param isin The ISIN without checksum digit (11 characters)
    /// @return The checksum digit (0-9)
    function calculateChecksum(string calldata isin) internal pure returns (uint8) {
        bytes calldata isinBytes = bytes(isin);
        
        if (isinBytes.length != 11) revert InvalidISINLength();
        
        uint256 sum = 0;
        bool alternate = false;
        
        assembly {
            let data := calldataload(isinBytes.offset)
            
            // Process each character from right to left
            for { let i := 10 } gte(i, 0) { i := sub(i, 1) } {
                let char := and(shr(mul(sub(31, i), 8), data), 0xff)
                let value
                
                // Convert character to numeric value
                switch and(gte(char, 0x30), lte(char, 0x39))
                case 1 { value := sub(char, 0x30) }             // 0-9 => 0-9
                default {
                    switch and(gte(char, 0x41), lte(char, 0x5A))
                    case 1 { value := add(sub(char, 0x41), 10) } // A-Z => 10-35
                    default {
                        switch and(gte(char, 0x61), lte(char, 0x7A))
                        case 1 { value := add(sub(char, 0x61), 10) } // a-z => 10-35
                        default { revert(0, 0) }
                    }
                }
                
                // Double alternate digits
                switch alternate
                case 1 {
                    value := mul(value, 2)
                    // If doubled value is > 9, sum its digits
                    switch gt(value, 9)
                    case 1 {
                        value := add(mod(value, 10), div(value, 10))
                    }
                }
                
                sum := add(sum, value)
                alternate := iszero(alternate)
            }
        }
        
        // Calculate check digit: (10 - (sum mod 10)) mod 10
        return uint8((10 - (sum % 10)) % 10);
    }

    /// @notice Validate ISIN checksum
    /// @param isin The complete ISIN (12 characters)
    /// @return True if the checksum is valid
    function hasValidChecksum(string calldata isin) internal pure returns (bool) {
        bytes calldata isinBytes = bytes(isin);
        
        if (isinBytes.length != 12) return false;
        
        // Get the provided check digit
        uint8 providedChecksum;
        assembly {
            let lastChar := and(shr(mul(20, 8), calldataload(isinBytes.offset)), 0xff)
            providedChecksum := sub(lastChar, 0x30)  // Convert from ASCII
        }
        
        // Calculate expected checksum using first 11 characters
        bytes memory prefix = new bytes(11);
        assembly {
            // Copy first 11 characters
            let data := calldataload(isinBytes.offset)
            mstore(add(prefix, 32), and(shr(8, shl(8, data)), not(shl(248, 0xFF))))
        }
        
        uint8 calculatedChecksum = calculateChecksum(string(prefix));
        return providedChecksum == calculatedChecksum;
    }
}
