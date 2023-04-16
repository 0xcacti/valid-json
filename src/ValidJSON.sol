// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

abstract contract ValidJSON is Test {
    function isValidJSON(bytes memory json) public returns (bool) {
        uint256 position = 0;
        uint256 maxPosition = json.length;

        position = skipSpace(json, position, maxPosition);
        if (json[position] == bytes1("{")) {
            (, bool valid) = isValidObject(json, position, maxPosition);
            return valid;
        } else if (json[position] == bytes1("[")) {
            (, bool valid) = isValidArray(json, position, maxPosition);
            return valid;
        } else {
            return false;
        }
    }

    function isValidObject(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        if (json[position] != bytes1("{")) {
            return (position, false);
        }

        position = skipSpace(json, position + 1, maxPosition);

        if (json[position] == bytes1("}")) {
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

            if (json[position] != bytes1(":")) {
                return (position, false);
            }

            position = skipSpace(json, position + 1, maxPosition);

            (position, locallyValid) = isValidValue(json, position, maxPosition);

            if (!locallyValid) {
                return (position, false);
            }

            position = skipSpace(json, position, maxPosition);

            if (json[position] == bytes1(",")) {
                position = skipSpace(json, position + 1, maxPosition);
                continue;
            } else if (json[position] == bytes1("}")) {
                position += 1;
                return (position, true);
            } else {
                return (position, false);
            }
        }
        return (position, false);
    }

    function isValidArray(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        if (json[position] != bytes1("[")) {
            return (position, false);
        }

        position = skipSpace(json, position + 1, maxPosition);

        if (json[position] == bytes1("]")) {
            position += 1;
            return (position, true);
        }

        bool locallyValid = false;

        while (position < maxPosition) {
            (position, locallyValid) = isValidValue(json, position, maxPosition);
            if (!locallyValid) {
                return (position, false);
            }

            position = skipSpace(json, position, maxPosition);

            if (json[position] == bytes1(",")) {
                position = skipSpace(json, position + 1, maxPosition);
                continue;
            } else if (json[position] == bytes1("]")) {
                position += 1;
                return (position, true);
            } else {
                return (position, false);
            }
        }
        return (position, true);
    }

    function isValidValue(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        bytes1 currentByte = json[position];
        bool locallyValid = false;
        if (currentByte == bytes1("{")) {
            (position, locallyValid) = isValidObject(json, position, maxPosition);
        } else if (currentByte == bytes1("[")) {
            (position, locallyValid) = isValidArray(json, position, maxPosition);
        } else if (currentByte == bytes1('"')) {
            (position, locallyValid) = isValidString(json, position, maxPosition);
        } else if (currentByte == bytes1("t")) {
            if (position + 3 >= maxPosition) {
                return (position, false);
            }

            if (
                json[position + 1] == bytes1("r") && json[position + 2] == bytes1("u")
                    && json[position + 3] == bytes1("e")
            ) {
                position = skipSpace(json, position + 4, maxPosition);
                return (position, true);
            } else {
                return (position, false);
            }
        } else if (currentByte == bytes1("f")) {
            if (position + 4 >= maxPosition) {
                return (position, false);
            }
            if (
                json[position + 1] == bytes1("a") && json[position + 2] == bytes1("l")
                    && json[position + 3] == bytes1("s") && json[position + 4] == bytes1("e")
            ) {
                position = skipSpace(json, position + 5, maxPosition);
                return (position, true);
            } else {
                return (position, false);
            }
        } else if (currentByte == bytes1("n")) {
            if (
                json[position + 1] == bytes1("u") && json[position + 2] == bytes1("l")
                    && json[position + 3] == bytes1("l")
            ) {
                position = skipSpace(json, position + 4, maxPosition);
                return (position, true);
            } else {
                return (position, false);
            }
        } else if (currentByte == bytes1("-") || (currentByte >= bytes1("0") && currentByte <= bytes1("9"))) {
            (position, locallyValid) = isValidNumber(json, position, maxPosition);
        } else {
            return (position, false);
        }
        return (position, locallyValid);
    }

    function isValidNumber(bytes memory json, uint256 position, uint256 maxPosition)
        internal
        pure
        returns (uint256, bool)
    {
        bool locallyValid = false;

        if (json[position] == bytes1("-")) {
            position++;
        }

        if (json[position] == bytes1("0")) {
            position++;
        } else if (json[position] >= bytes1("1") || json[position] <= bytes1("9")) {
            position++;
            if (json[position] >= bytes1("0") && json[position] <= bytes1("9")) {
                (position, locallyValid) = isValidDigit(json, position, maxPosition);
                if (!locallyValid) {
                    return (position, false);
                }
            }
        } else {
            return (position, false);
        }

        if (json[position] == bytes1(".")) {
            (position, locallyValid) = isValidDigit(json, position + 1, maxPosition);
            if (!locallyValid) {
                return (position, false);
            }
        }

        if (json[position] != bytes1("e") && json[position] != bytes1("E")) {
            return (position, true);
        }

        position++;

        if (json[position] == bytes1("+") || json[position] == bytes1("-")) {
            position++;
        }

        (position, locallyValid) = isValidDigit(json, position, maxPosition);
        return (position, locallyValid);
    }

    function isValidDigit(bytes memory json, uint256 position, uint256 maxPosition)
        internal
        pure
        returns (uint256, bool)
    {
        if (json[position] < bytes1("0") || json[position] > bytes1("9")) {
            return (position, false);
        }
        position++;

        while (json[position] >= bytes1("0") && json[position] <= bytes1("9")) {
            position++;
        }
        return (position, true);
    }

    function isValidEscape(bytes memory json, uint256 position, uint256 maxPosition)
        internal
        pure
        returns (uint256, bool)
    {
        bytes1 currentByte = json[position];
        if (
            currentByte == bytes1('"') || currentByte == bytes1("\\") || currentByte == bytes1("/")
                || currentByte == bytes1("b") || currentByte == bytes1("f") || currentByte == bytes1("n")
                || currentByte == bytes1("r") || currentByte == bytes1("t")
        ) {
            position = skipSpace(json, position + 1, maxPosition);
            return (position, true);
        } else if (currentByte == bytes1("u")) {
            for (uint256 i = 1; i <= 4; i++) {
                currentByte = json[position + i];
                if (currentByte >= bytes1("0") && currentByte <= bytes1("9")) {
                    continue;
                } else if (currentByte >= bytes1("a") && currentByte <= bytes1("f")) {
                    continue;
                } else if (currentByte >= bytes1("a") && currentByte <= bytes1("f")) {
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

    function isValidString(bytes memory json, uint256 position, uint256 maxPosition)
        internal
        pure
        returns (uint256, bool)
    {
        if (json[position] != bytes1('"')) {
            return (position, false);
        }
        position++;
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
            if (json[position] == bytes1('"')) {
                return (position + 1, true);
            } else if (json[position] == bytes1("\\")) {
                escaped = true;
            } else if (json[position] < 0x20) {
                return (position, false);
            }

            position++;
        }
        return (position, false);
    }

    function skipSpace(bytes memory data, uint256 position, uint256 maxPosition) public pure returns (uint256) {
        // does this handle new lines
        while (position < maxPosition) {
            if (data[position] != bytes1(" ")) {
                return position;
            }
            position++;
        }
        return 0;
    }
}
