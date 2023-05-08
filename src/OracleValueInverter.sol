// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./IOracle.sol";

contract OracleValueInverter {
    IOracle immutable a3oracle;

    mapping(address => bool) public acceptedTermsOfService;

    modifier onlyAcceptedTermsOfService() {
        require(
            acceptedTermsOfService[msg.sender],
            "Terms of Service not accepted"
        );
        _;
    }

    constructor(IOracle oracle) {
        // Accept the ToS required in the oracle contract
        oracle.acceptTermsOfService();
        a3oracle = oracle;
    }

    function acceptTermsOfService() external {
        acceptedTermsOfService[msg.sender] = true;
    }

    function readData()
        external
        view
        onlyAcceptedTermsOfService
        returns (uint256)
    {
        uint256 price = a3oracle.readData();

        // The price returned by the A3 oracle is scaled to 18 decimals.
        // The inverted price is calculated as: 1e18/`price`.
        // Solidity does not handle floating point numbers, as a result of this,
        // doing such a division can result in a floating number which would be retiurned as 0.
        // To get the the inverted price:
        // 1. multiply 1e18 by a sclae of 1e18 to handle a case of a floating number.
        // 2. divide the result of step 1 by the price gotten from `readData`
        return (1e18 * 1e18) / price;
    }
}
