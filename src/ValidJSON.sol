// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract ValidJSON {
    function isValidJSON(bytes memory json) public returns (bool) {
        uint256 position = 0;
        uint256 maxPosition = json.length;

        position = skipSpace(json, position, maxPosition);

        if (json[position] == "{") {
            (, bool valid) = isValidObject(json, position, maxPosition);
            return valid;
        } else if (json[position] == "[") {
            (, bool valid) = isValidArray(json, position, maxPosition);
            return valid;
        } else {
            return false;
        }
    }


    function isValidObject(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        if (json[position] != "{") {
            return (position, false);
        }

        position = skipSpace(json, position + 1, maxPosition);

        if (json[position] == "}") {
            position += 1;
            return (position, true);
        }
        bool locallyValid = false;

        while (position < maxPosition) {
            (position, locallyValid) = isValidString(json, position, maxPosition);
            if (!locallyValid) {
                return (position, false);
            }

            position = skipSpace(json, position, maxPosition);

            if (json[position] != ":") {
                return (position, false);
            }

            position = skipSpace(json, position + 1, maxPosition);

            (position, locallyValid) = isValidValue(json, position, maxPosition);
            if (!locallyValid) {
                return (position, false);
            }

            position = skipSpace(json, position, maxPosition);

            if (json[position] == ",") {
                position = skipSpace(json, position + 1, maxPosition);
                continue;
            } else if (json[position] == "}") {
                position += 1;
                return (position, true);
            } else {
                return (position, false);
            }
        }
    }

    function isValidArray(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {}

    function isValidValue(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        bytes1 currentByte = json[position];
        bool locallyValid = false;
        if (currentByte == "{") {
            (position, locallyValid) = isValidObject(json, position, maxPosition);
            if (!locallyValid) {
                return (position, false);
            }
        } else if (currentByte == "[") {
            (position, locallyValid) = isValidArray(json, position, maxPosition);
            if (!locallyValid) {
                return (position, false);
            }
        } else if (currentByte == '"') {
            (position, locallyValid) = isValidString(json, position, maxPosition);
            if (!locallyValid) {
                return (position, false);
            }
        } else if (currentByte == "t") {
            if (json[position + 1] == "r" && json[position + 2] == "u" && json[position + 3] == "e") { // TODO handle overflow 
                position = skipSpace(json, position + 4, maxPosition);
                return (position, true);
            } else {
                return (position, false);
            }
        } else if (currentByte == "f") {
            if (json[position + 1] == "a" && json[position + 2] == "l" && json[position + 3] == "s" && json[position + 4] == "e") {
                position = skipSpace(json, position + 5, maxPosition);
                return (position, true);
            } else {
                return (position, false);
            }
        } else if (currentByte == "n") {
            if (json[position + 1] == "u" && json[position + 2] == "l" && json[position + 3] == "l") {
                position = skipSpace(json, position + 4, maxPosition);
                return (position, true);
            } else {
                return (position, false);
            }
        } else if (currentByte == "-" || (currentByte >= "0" && currentByte <= "9")) {
            (position, locallyValid) =  isValidNumber(json, position, maxPosition);
        } else {
            return (position, false);
        }

    }


    function isValidNumber(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        bytes1 currentByte = json[position];
        if (currentByte == "-") {
            position = skipSpace(json, position + 1, maxPosition);
            currentByte = json[position];
        }

        if (currentByte == "0") {
            position = skipSpace(json, position + 1, maxPosition);
        } else if (currentByte >= "1" && currentByte <= "9") {
            (position, ) = isValidDigit(json, position, maxPosition);
        } else {
            return (position, false);
        }

        currentByte = json[position];
        if (currentByte == ".") {
            (position, ) = isValidDigit(json, position + 1, maxPosition);
        }

        currentByte = json[position];
        if (currentByte == "e" || currentByte == "E") {
            position = skipSpace(json, position + 1, maxPosition);
            currentByte = json[position];
            if (currentByte == "+" || currentByte == "-") {
                position = skipSpace(json, position + 1, maxPosition);
            }
            (position, ) = isValidDigit(json, position, maxPosition);
        }

        return (position, true);
        
    }

    function isValidDigit(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        bytes1 currentByte = json[position];
        if (currentByte >= "0" && currentByte <= "9") {
            position = skipSpace(json, position + 1, maxPosition);
            return (position, true);
        } else {
            return (position, false);
        }
    }

    function isValidEscape(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        bytes1 currentByte = json[position];
        if (
            currentByte == '"' || currentByte == "\\" || currentByte == "/" || currentByte == "b" || currentByte == "f"
                || currentByte == "n" || currentByte == "r" || currentByte == "t"
        ) {
            position = skipSpace(json, position + 1, maxPosition);
            return (position, true);
        } else if (currentByte == "u") {
            for (uint256 i = 1; i <= 4; i++) {
                currentByte = json[position + i];
                if (currentByte >= "0" && currentByte <= "9") {
                    continue;
                } else if (currentByte >= "A" && currentByte <= "F") {
                    continue;
                } else if (currentByte >= "a" && currentByte <= "f") {
                    continue;
                } else {
                    return (position, false);
                }
            }
            position = skipSpace(json, position + 5, maxPosition);
            return (position, true);
        } else {
            return (position, false);
        }
    }

    function isValidString(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        if (json[position] != '"') {
            return (position, false);
        }
        bool escaped = false;
        bool locallyValid = false;

        while (position < maxPosition) {

            if (escaped) {
                (position, locallyValid) = isValidEscape(json, position, maxPosition);
                if (!locallyValid) {
                    return (position, false);
                }
                escaped = false;
            }

            if (json[position] == '"') {
                return (position + 1, true);
            } else if (json[position] == '\\') {
                escaped = true;
            } else if (json[position] < 0x20) { // I don't understand this line
                return (position, false);
            }

            position++;
        }
        return (position, false);
    }

    function skipSpace(bytes memory data, uint256 position, uint256 maxPosition) public returns (uint256) { // does this handle new lines
        while (position < maxPosition) {
            if (data[position] != " ") {
                return position;
            }
            position++;
        }
        return 0;
    }
}
