// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract ValidJSON {

    function isValidJSON(bytes memory json) public returns(bool) {
        uint256 position = 0;
        uint256 maxPosition = json.length;

        position = skipSpace(json);

        if (json[position] == '{') {
            return isValidObject(json, position, maxPosition);
        } else if (json[position] == '[') {
            return isValidArray(json, position, maxPosition);
        } else {
            return false;
        }

    }

    function isValidObject(bytes memory json, uint256 position, uint256 maxPosition) internal returns(bool) {

    }

    function isValidArray(bytes memory json, uint256 position, uint256 maxPosition) internal returns(bool) {

    }

    function skipSpace(bytes memory data) public returns (uint256) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] != ' ') {
                return i;
            }
        }
        return 0;
    }

}

