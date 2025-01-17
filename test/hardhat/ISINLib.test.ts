import { expect } from "chai";
import { ethers } from "hardhat";

describe("ISINLib", function () {
  let test: any;

  beforeEach(async function () {
    // Get factory for TestISIN, checking its bytecode first to see if it needs linking
    const TestISIN = await ethers.getContractFactory("TestISIN");
    
    // Deploy TestISIN without trying to link the library - it should use the library through the "using for" statement
    test = await TestISIN.deploy();
    await test.deployed();
  });

  async function runTestCases(testCases: string[]) {
    for (const testCase of testCases) {
      const encoded = await test.toUint256(testCase);
      const decoded = await test.fromUint256(encoded);
      expect(decoded).to.equal(testCase);
    }
  }

  it("should correctly encode and decode ISINs", async function () {
    const testCases = [
      "US0378331005", // Apple Inc.
      "DE000BAY0017", // Bayer AG
      "GB0002374006", // Diageo plc
      "FR0000131104", // BNP Paribas
      "CH0012221716", // ABB Ltd
    ];

    await runTestCases(testCases);
  });

  it("should handle edge cases correctly", async function () {
    const testCases = [
      "000000000000", // All zeros
      "999999999999", // All nines
      "AAAAAAAAAAAA", // All As
      "ZZZZZZZZZZZZ", // All Zs
    ];

    await runTestCases(testCases);
  });
});