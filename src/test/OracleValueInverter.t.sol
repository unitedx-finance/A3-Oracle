// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {BaseSetup} from "./BaseSetup.sol";
import {Aggr3Oracle} from "../Aggr3Oracle.sol";
import {OracleValueInverter} from "../OracleValueInverter.sol";
import {IOracle} from "../IOracle.sol";
import {console} from "./utils/Console.sol";

contract OracleValueInverterTest is BaseSetup {
    Aggr3Oracle internal aggr3Oracle;
    OracleValueInverter internal aggr3OracleWrapper;

    function setUp() public override {
        super.setUp();

        vm.prank(owner);
        aggr3Oracle = new Aggr3Oracle(owner, "Description", "Terms of service");
        vm.stopPrank();

        aggr3OracleWrapper = new OracleValueInverter(
            IOracle(address(aggr3Oracle))
        );
    }

    function testAcceptedTermsOfService() public {
        bool accepted = aggr3Oracle.acceptedTermsOfService(
            address(aggr3OracleWrapper)
        );
        assertTrue(accepted);
    }

    function testReadPriceIfAcceptedToS() public {
        uint256 price = 2e18;

        vm.prank(owner);
        aggr3Oracle.writeData(price);
        vm.stopPrank();

        vm.startPrank(reader);
        aggr3OracleWrapper.acceptTermsOfService();

        assertTrue(aggr3OracleWrapper.acceptedTermsOfService(reader));

        uint256 priceData = aggr3OracleWrapper.readData();

        assertEq(priceData, 5e17);
        vm.stopPrank();
    }

    function testReadPriceRevertIfNotAcceptedToS() public {
        vm.expectRevert(abi.encodePacked("Terms of Service not accepted"));

        vm.prank(reader);
        aggr3OracleWrapper.readData();
    }
}
