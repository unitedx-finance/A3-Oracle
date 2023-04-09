// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {MultiOwnable} from "./MultiOwnable.sol";

contract Aggr3Oracle is MultiOwnable {
    string public description; // short string describing this oracle's data (e.g. "ADA/USD")
    string public termsOfService; // terms of service

    struct Data { uint256 value; address owner; }
    mapping(uint256 => Data) private data; // data provided by the oracle per nonce
    uint256 private nonce = 0; // nonce for accessing the Data structure
    uint256 private median; // median value calculated from unique owner data

    event DataWritten(uint256 data, address indexed owner);

    mapping(address => bool) public acceptedTermsOfService;

    modifier onlyAcceptedTermsOfService() {
        require(acceptedTermsOfService[msg.sender], "Terms of Service not accepted");
        _;
    }

    constructor(address _owner, string memory _description, string memory _termsOfService) MultiOwnable(_owner) {
        description = _description;
        termsOfService = _termsOfService;
    }

    function writeData(uint256 _data) external onlyOwner {
        data[nonce] = Data(_data, msg.sender);
        emit DataWritten(data[nonce].value, msg.sender);
        nonce++;
        updateMedian();
    }

    function updateMedian() internal {
        uint256[] memory values = new uint256[](3);
        address[] memory uniqueOwners = new address[](3);
        uint256 index = 0;

        for (int256 i = int256(nonce) - 1; i >= 0 && index < 3; i--) {
            bool isOwnerUnique = true;
            for (uint256 j = 0; j < index; j++) {
                if (uniqueOwners[j] == data[uint256(i)].owner) {
                    isOwnerUnique = false;
                    break;
                }
            }

            if (isOwnerUnique) {
                values[index] = data[uint256(i)].value;
                uniqueOwners[index] = data[uint256(i)].owner;
                index++;
            }
        }

        if (index == 1) median = values[0]; 
        else if (index == 2) median = (values[0] + values[1]) / 2;
        else median = median3(values[0], values[1], values[2]);
    }

    function readData() external view onlyAcceptedTermsOfService returns (uint256) {
        return median;
    }

    function acceptTermsOfService() external {
        acceptedTermsOfService[msg.sender] = true;
    }

    function median3(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        if (a > b) {
            if (c >= a) return a;
            else if (b >= c) return b;
            else return c;
        }
        else { // b >= a
            if (c >= b) return b;
            else if (a >= c) return a;
            else return c;
        }
    }
}
