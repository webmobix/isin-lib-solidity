# isin-lib-solidity

A Solidity library for efficient and reversible conversion between International Securities Identification Numbers (ISINs) as strings and `uint256` values directly within EVM smart contracts.

This library is crucial for smart contracts that need to manage or reference financial instruments identified by ISINs, enabling a direct and gas-optimized link between off-chain ISIN strings and on-chain `uint256` identifiers.

## Why This Library Matters

Financial instruments use 12-character alphanumeric ISINs for global identification. Smart contracts on EVM blockchains, however, primarily use `uint256` for unique IDs (like NFT tokenIds). This data type mismatch can be a hurdle. `isin-lib-solidity` provides a gas-efficient, on-chain solution using base36 encoding to convert ISIN strings to `uint256` and back. This ensures a reliable one-to-one mapping, vital for integrating traditional financial assets with DeFi applications directly on the blockchain.

## Features

- Converts ISIN strings (must be uppercase A-Z, 0-9, and 12 characters long) to `uint256`.
- Converts `uint256` values back to 12-character ISIN strings, padding with leading zeros if necessary.
- Uses base36 encoding, implemented with gas optimization in mind for Solidity.
- Includes input validation for ISIN string format and length.
- Designed as a library for easy integration into other smart contracts.

## Installation

**Using a package manager (e.g., npm/yarn for Hardhat/Truffle projects):**

```bash
npm install your-package-name # Or your actual package name
# or
yarn add your-package-name # Or your actual package name
```

Then import in your Solidity contract:

```solidity
// Adjust path if your package structure is different
import "your-package-name/contracts/ISINLib.sol";
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISINLib.sol"; // Or from node_modules if installed

contract FinancialProductRegistry {
  mapping(uint256 => string) public idToIsinString;
  mapping(string => uint256) public isinStringToId; // Be mindful of gas costs for string keys

  event ProductRegistered(
    string indexed isinString,
    uint256 indexed instrumentId
  );

  /**
   * @notice Registers a product using its ISIN string.
   * @param isinString The ISIN of the product as a 12-character string (uppercase A-Z, 0-9).
   */
  function registerProduct(string memory isinString) public {
    // The ISINLib.toUint256 function already requires 12 chars.
    // Additional check for empty string can be done if needed, though ISINLib will revert.
    // require(bytes(isinString).length > 0, "ISINLib: ISIN string cannot be empty");
    require(
      isinStringToId[isinString] == 0,
      "ISINLib: Product already registered with this ISIN"
    );

    uint256 instrumentId = ISINLib.toUint256(isinString); // Library function call

    idToIsinString[instrumentId] = isinString;
    isinStringToId[isinString] = instrumentId;

    // --- Placeholder for NFT minting logic (e.g., ERC721 _mint) ---
    // _mint(msg.sender, instrumentId);
    // --- End Placeholder ---

    emit ProductRegistered(isinString, instrumentId);
  }

  /**
   * @notice Retrieves the ISIN string for a given instrument ID.
   * @param instrumentId The uint256 ID of the instrument.
   * @return The ISIN string.
   */
  function getIsinFromId(
    uint256 instrumentId
  ) public view returns (string memory) {
    string memory isinString = idToIsinString[instrumentId];
    // ISINLib.fromUint256(0) returns "000000000000".
    // If an ID 0 is not a valid instrumentId, or if empty string means not found:
    require(
      bytes(isinString).length > 0,
      "ISINLib: Instrument ID not found or ISIN is empty"
    );
    return isinString;
  }

  /**
   * @notice Retrieves the instrument ID for a given ISIN string.
   * @param isinString The ISIN string of the instrument.
   * @return The uint256 instrument ID.
   */
  function getIdFromIsin(
    string memory isinString
  ) public view returns (uint256) {
    uint256 instrumentId = isinStringToId[isinString];
    require(instrumentId != 0, "ISINLib: ISIN not found"); // Assumes ID 0 is not used for valid ISINs
    return instrumentId;
  }
}
```

## API

The ISINLib.sol library provides the following core functions:

`function toUint256(string memory isin) internal pure returns uint256 numericValue)`

- Encodes an ISIN string to a uint256 value.
- Parameters:
  - isin (string memory): The ISIN string to encode (must be uppercase A-Z, 0-9, and 12 characters long).
- Returns: The uint256 representation of the ISIN.
- Reverts if the ISIN string is not 12 characters long or contains invalid characters.

`function fromUint256(uint256 value) internal pure returns (string memory isin)`

- Decodes a uint256 back to an ISIN string.
- Parameters:
  - value: The uint256 value to decode.
- Returns: The original ISIN string (12 characters, padded with leading '0's if necessary). "000000000000" for input 0.
- Reverts if the input value is greater than MAX_ISIN_VALUE (36^12 - 1).

## Sister Libraries

This library can be complemented by similar libraries in other languages for consistent ISIN <=> uint256 conversion across different environments:

- For JavaScript/TypeScript front-end or Node.js applications
  [https://github.com/webmobix/isin-lib-js](https://github.com/webmobix/isin-lib-js)
- For Java applications
  [https://github.com/webmobix/isin-lib-java](https://github.com/webmobix/isin-lib-java)

## Contributing

Contributions are welcome.
