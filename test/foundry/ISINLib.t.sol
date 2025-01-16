// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/ISINLib.sol";

// Test contract to use the library
contract TestISIN {
    using ISINLib for string;
    
    function convert(string calldata isin) public pure returns (uint256) {
        return isin.toUint256();
    }
    
    function reverting(uint256 value) public pure returns (string memory) {
        return ISINLib.fromUint256(value);
    }
    
    function validate(string calldata isin) public pure returns (bool) {
        return isin.isValid();
    }
}

/// @title Test contract for ISINLib
/// @notice Contains comprehensive tests for the ISIN conversion library
contract ISINLibTest is Test {
    using ISINLib for string;
    
    TestISIN private test;
    
    function setUp() public {
        test = new TestISIN();
    }
    
    /// @notice Test well-known ISINs conversion
    function testWellKnownISINs() public {
        string[4] memory isins = [
            "US0378331005", // Apple Inc
            "US88160R1014", // Tesla Inc
            "DE0007164600", // SAP SE
            "GB0002374006"  // Diageo PLC
        ];
        
        for(uint i = 0; i < isins.length; i++) {
            assertBidirectionalConversion(isins[i]);
        }
    }
    
    /// @notice Test edge cases
    function testEdgeCases() public {
        // Test zero case
        assertEq(test.reverting(0), "000000000000", "Zero conversion failed");
        
        // Test all zeros
        assertBidirectionalConversion("000000000000");
        
        // Test all letters
        assertBidirectionalConversion("AAAAAAAAAAAA");
        
        // Test alternating pattern
        assertBidirectionalConversion("A1A1A1A1A1A1");
        
        // Test max value pattern
        assertBidirectionalConversion("ZZZZZZZZZZZZ");
    }
    
    /// @notice Test case sensitivity
    function testCaseSensitivity() public {
        string[3] memory variants = [
            "US0378331005", // uppercase
            "us0378331005", // lowercase
            "Us0378331005"  // mixed case
        ];
        
        uint256 expected = test.convert(variants[0]);
        
        for(uint i = 1; i < variants.length; i++) {
            uint256 result = test.convert(variants[i]);
            assertEq(result, expected, "Case sensitivity test failed");
        }
    }
    
    /// @notice Test invalid inputs
    function testInvalidInputs() public {
        // Test invalid length
        vm.expectRevert(ISINLib.InvalidISINLength.selector);
        test.convert("US037833100");  // Too short
        
        // Test invalid characters
        string[4] memory invalidIsins = [
            "US037833100$",
            "US037833100#",
            "US037833100@",
            "US037833100*"
        ];
        
        for(uint i = 0; i < invalidIsins.length; i++) {
            assertFalse(test.validate(invalidIsins[i]), "Invalid character validation failed");
        }
    }
    
    /// @notice Test validation function
    function testValidation() public {
        // Test valid ISINs
        assertTrue(test.validate("US0378331005"), "Valid ISIN validation failed");
        assertTrue(test.validate("us0378331005"), "Valid lowercase ISIN validation failed");
        
        // Test invalid ISINs
        assertFalse(test.validate("US037833100"), "Short ISIN validation failed");
        assertFalse(test.validate("US037833100$$"), "Invalid character validation failed");
    }
    
    /// @notice Test numeric order preservation
    function testOrderPreservation() public {
        uint256 value1 = test.convert("AA0000000001");
        uint256 value2 = test.convert("AA0000000002");
        uint256 value3 = test.convert("AA0000000003");
        
        assertTrue(value1 < value2, "Order preservation test failed (1<2)");
        assertTrue(value2 < value3, "Order preservation test failed (2<3)");
        assertTrue(value1 < value3, "Order preservation test failed (1<3)");
    }
    
    /// @notice Gas benchmarking
    function testGasUsage() public {
        string memory isin = "US0378331005";
        
        // Test encoding gas usage
        uint256 gasStart = gasleft();
        uint256 encoded = test.convert(isin);
        uint256 gasUsed = gasStart - gasleft();
        emit log_named_uint("Gas used for encoding", gasUsed);
        
        // Test decoding gas usage
        gasStart = gasleft();
        test.reverting(encoded);
        gasUsed = gasStart - gasleft();
        emit log_named_uint("Gas used for decoding", gasUsed);
    }
    
    /// @notice Fuzz testing for random inputs
    function testFuzz_BidirectionalConversion(uint256 value) public {
        // Limit the value to avoid overflow
        value = bound(value, 0, type(uint256).max / 36);
        
        string memory isin = test.reverting(value);
        uint256 converted = test.convert(isin);
        assertEq(converted, value, "Fuzz test failed");
    }
    
    /// @notice Helper function to test bidirectional conversion
    function assertBidirectionalConversion(string memory original) internal {
        uint256 encoded = test.convert(original);
        string memory decoded = test.reverting(encoded);
        assertEq(decoded, original.toUpperCase(), "Bidirectional conversion failed");
    }
    
    /// @notice Test ISIN checksum calculation
    function testChecksum() public {
        // Test known valid ISINs
        string[5] memory validISINs = [
            "US0378331005", // Apple Inc
            "US88160R1014", // Tesla Inc
            "DE0007164600", // SAP SE
            "GB0002374006", // Diageo PLC
            "FR0000131104"  // BNP Paribas
        ];
        
        for(uint i = 0; i < validISINs.length; i++) {
            assertTrue(
                test.validate(validISINs[i]) && 
                validISINs[i].hasValidChecksum(),
                "Valid ISIN checksum validation failed"
            );
        }

        // Test checksum calculation
        string memory isinNoChecksum = "US037833100";
        uint8 checksum = ISINLib.calculateChecksum(isinNoChecksum);
        assertEq(checksum, 5, "Checksum calculation failed for US0378331005");

        // Test invalid checksums
        assertFalse("US0378331006".hasValidChecksum(), "Invalid checksum accepted");
        assertFalse("US0378331004".hasValidChecksum(), "Invalid checksum accepted");
    }

    /// @notice Test edge cases for checksum
    function testChecksumEdgeCases() public {
        // Test with all zeros
        assertTrue("000000000000".hasValidChecksum(), "All zeros checksum failed");
        
        // Test with all nines
        assertTrue("999999999999".hasValidChecksum(), "All nines checksum failed");
        
        // Test with alternating digits
        string memory alternating = "A1B2C3D4E5F0";
        uint8 checksum = ISINLib.calculateChecksum(alternating[0:11]);
        string memory complete = string.concat(alternating[0:11], string(abi.encodePacked(uint8(checksum + 48))));
        assertTrue(complete.hasValidChecksum(), "Alternating pattern checksum failed");
    }

    /// @notice Fuzz testing for checksum calculation
    function testFuzz_Checksum(uint256 seed) public {
        // Generate a random 11-character ISIN prefix
        string memory prefix = generateRandomISINPrefix(seed);
        
        // Calculate its checksum
        uint8 checksum = ISINLib.calculateChecksum(prefix);
        
        // Verify checksum is within valid range
        assertTrue(checksum < 10, "Checksum out of valid range");
        
        // Create complete ISIN with calculated checksum
        string memory complete = string.concat(prefix, string(abi.encodePacked(uint8(checksum + 48))));
        
        // Verify the checksum is valid
        assertTrue(complete.hasValidChecksum(), "Fuzz test checksum validation failed");
    }

    /// @notice Helper function to generate random ISIN prefix for testing
    function generateRandomISINPrefix(uint256 seed) internal pure returns (string memory) {
        bytes memory result = new bytes(11);
        uint256 rand = seed;
        
        for(uint i = 0; i < 11; i++) {
            rand = uint256(keccak256(abi.encodePacked(rand)));
            uint8 charType = uint8(rand % 3);  // 0: digit, 1: uppercase, 2: lowercase
            
            if (charType == 0) {
                result[i] = bytes1(uint8(48 + (rand % 10)));  // 0-9
            } else if (charType == 1) {
                result[i] = bytes1(uint8(65 + (rand % 26)));  // A-Z
            } else {
                result[i] = bytes1(uint8(97 + (rand % 26)));  // a-z
            }
        }
        
        return string(result);
    }

    /// @notice Helper function to convert string to uppercase
    function toUpperCase(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bUpper = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if (uint8(bStr[i]) >= 97 && uint8(bStr[i]) <= 122) {
                bUpper[i] = bytes1(uint8(bStr[i]) - 32);
            } else {
                bUpper[i] = bStr[i];
            }
        }
        return string(bUpper);
    }
}