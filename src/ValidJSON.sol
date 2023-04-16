// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "src/Constants.sol";

/// @title ValidJSON
/// @author 0xcacti 
/// @notice This contract is used to validate JSON strings.  
///         All code operates on bytes as string indexing does not work in Solidity for string memory. 
/// @dev This contract only currently returns true or false. DO NOT use this to validate unicode strings. 
///      Additionally be aware of high gas costs and potential stack overflow issues for very long JSON. 
abstract contract ValidJSON {


    /// @notice This function is used to validate a JSON string. 
    /// @dev This is the entry point to the entire process.  
    /// @param json The JSON string (as a bytes array) to validate.
    /// @return bool Returns true if the JSON string is valid, false otherwise.
    function isValidJSON(bytes memory json) public returns (bool) {
        uint256 position = 0;
        uint256 maxPosition = json.length;

        position = skipSpace(json, position, maxPosition);
        if (json[position] == CURLY_OPEN_BRACKET) {
            (, bool valid) = isValidObject(json, position, maxPosition);
            return valid;
        } else if (json[position] == SQUARE_OPEN_BRACKET) {
            (, bool valid) = isValidArray(json, position, maxPosition);
            return valid;
        } else {
            return false;
        }
    }

    /// @notice This function validates if a json object is valid.
    /// @dev JSON objects are surrounded by curly braces. 
    /// @param json The JSON string (as a bytes array) to validate.
    /// @param position The current position in the JSON string.
    /// @param maxPosition The length of the JSON string.
    /// @return uint256 The new position in the JSON string.
    /// @return bool Returns true if the JSON object is valid, false otherwise.
    function isValidObject(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        if (json[position] != CURLY_OPEN_BRACKET) {
            return (position, false);
        }

        position = skipSpace(json, position + 1, maxPosition);

        if (json[position] == CURLY_CLOSE_BRACKET) {
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

            if (json[position] != COLON) {
                return (position, false);
            }

            position = skipSpace(json, position + 1, maxPosition);

            (position, locallyValid) = isValidValue(json, position, maxPosition);

            if (!locallyValid) {
                return (position, false);
            }

            position = skipSpace(json, position, maxPosition);

            if (json[position] == COMMA) {
                position = skipSpace(json, position + 1, maxPosition);
                continue;
            } else if (json[position] == CURLY_CLOSE_BRACKET) {
                position += 1;
                return (position, true);
            } else {
                return (position, false);
            }
        }
        return (position, false);
    }

    /// @notice This function validates if a json array is valid.
    /// @dev JSON arrays are surrounded by square brackets.
    /// @param json The JSON string (as a bytes array) to validate.
    /// @param position The current position in the JSON string.
    /// @param maxPosition The length of the JSON string.
    /// @return uint256 The new position in the JSON string.
    /// @return bool Returns true if the JSON array is valid, false otherwise.
    function isValidArray(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        if (json[position] != SQUARE_OPEN_BRACKET) {
            return (position, false);
        }

        position = skipSpace(json, position + 1, maxPosition);

        if (json[position] == SQUARE_CLOSE_BRACKET) {
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

            if (json[position] == COMMA) {
                position = skipSpace(json, position + 1, maxPosition);
                continue;
            } else if (json[position] == SQUARE_CLOSE_BRACKET) {
                position += 1;
                return (position, true);
            } else {
                return (position, false);
            }
        }
        return (position, true);
    }

    /// @notice This function validates if a json value (of any type) is valid.
    /// @dev JSON values can be objects, arrays, strings, numbers, or booleans.
    /// @param json The JSON string (as a bytes array) to validate.
    /// @param position The current position in the JSON string.
    /// @param maxPosition The length of the JSON string.
    /// @return uint256 The new position in the JSON string.
    /// @return bool Returns true if the JSON value is valid, false otherwise.
    function isValidValue(bytes memory json, uint256 position, uint256 maxPosition) internal returns (uint256, bool) {
        bytes1 currentByte = json[position];
        bool locallyValid = false;
        if (currentByte == CURLY_OPEN_BRACKET) {
            (position, locallyValid) = isValidObject(json, position, maxPosition);
        } else if (currentByte == SQUARE_OPEN_BRACKET) {
            (position, locallyValid) = isValidArray(json, position, maxPosition);
        } else if (currentByte == QUOTE) {
            (position, locallyValid) = isValidString(json, position, maxPosition);
        } else if (currentByte == T) {
            if (position + 3 >= maxPosition) {
                return (position, false);
            }
            if (
                json[position + 1] == R && json[position + 2] == U
                    && json[position + 3] == E
            ) {
                position = skipSpace(json, position + 4, maxPosition);
                return (position, true);
            } else {
                return (position, false);
            }
        } else if (currentByte == F) {  
            if (position + 4 >= maxPosition) {
                return (position, false);
            }
            if (
                json[position + 1] == A && json[position + 2] == L
                    && json[position + 3] == S && json[position + 4] == E
            ) {
                position = skipSpace(json, position + 5, maxPosition);
                return (position, true);
            } else {
                return (position, false);
            }
        } else if (currentByte == N) {
            if (position + 3 >= maxPosition) {
                return (position, false);
            }
            if (
                json[position + 1] == U && json[position + 2] == L
                    && json[position + 3] == L
            ) {
                position = skipSpace(json, position + 4, maxPosition);
                return (position, true);
            } else {
                return (position, false);
            }
        } else if (currentByte == MINUS || (currentByte >= ZERO && currentByte <= NINE)) {
            (position, locallyValid) = isValidNumber(json, position);
        } else {
            return (position, false);
        }
        return (position, locallyValid);
    }

    /// @notice This function validates if a json number is valid.
    /// @dev This function relies heavily on isValidDigit.  isValidDigit handles validating the strictly numeric portion of numbers 
    ///      (i.e. the digits 0-9).  This function handles validating the rest of the number (i.e. the decimal, exponent, and sign).
    /// @param json The JSON string (as a bytes array) to validate.
    /// @param position The current position in the JSON string.
    
    function isValidNumber(bytes memory json, uint256 position)
        internal
        pure
        returns (uint256, bool)
    {
        bool locallyValid = false;

        if (json[position] == MINUS) {
            position++;
        }

        if (json[position] == ZERO) {
            position++;
        } else if (json[position] >= ONE || json[position] <= NINE) {
            position++;
            if (json[position] >= ZERO && json[position] <= NINE) {
                (position, locallyValid) = isValidDigit(json, position);
                if (!locallyValid) {
                    return (position, false);
                }
            }
        } else {
            return (position, false);
        }

        if (json[position] == DECIMAL_POINT) {
            (position, locallyValid) = isValidDigit(json, position + 1);
            if (!locallyValid) {
                return (position, false);
            }
        }

        if (json[position] != E_LOWER && json[position] != E_CAPITAL) {
            return (position, true);
        }

        position++;

        if (json[position] == PLUS || json[position] == MINUS) {
            position++;
        }

        (position, locallyValid) = isValidDigit(json, position);
        return (position, locallyValid);
    }

    /// @notice Checks if a digit is valid
    /// @dev This function is used to check if a series of digits is valid.  It will check all values between the position and the next non-digit character.
    /// @param json The JSON string
    /// @param position The position of the character
    /// @return uint256 The new position in the string
    /// @return bool True if the series of digits is valid
    function isValidDigit(bytes memory json, uint256 position)
        internal
        pure
        returns (uint256, bool)
    {
        if (json[position] < ZERO || json[position] > NINE) {
            return (position, false);
        }
        position++;

        while (json[position] >= ZERO && json[position] <= NINE) {
            position++;
        }
        return (position, true);
    }

    /// @notice Checks if an escaped character is valid
    /// @param json The JSON string
    /// @param position The position of the character
    /// @param maxPosition The maximum position of the string
    /// @return uint256 The new position in the string
    /// @return bool True if the character is valid
    function isValidEscape(bytes memory json, uint256 position, uint256 maxPosition)
        internal
        pure
        returns (uint256, bool)
    {
        bytes1 currentByte = json[position];
        if (
            currentByte == QUOTE || currentByte == BACKSLASH || currentByte == FORWARD_SLASH
                || currentByte == BACKSPACE || currentByte == FORM_FEED || currentByte == NEW_LINE
                || currentByte == CARRIAGE_RETURN || currentByte == TAB
        ) {
            position = skipSpace(json, position + 1, maxPosition);
            return (position, true);
        } else if (currentByte == UNICODE) {
            if (position + 5 >= maxPosition) {
                return (position, false);
            }
            for (uint256 i = 1; i <= 4; i++) {
                currentByte = json[position + i];
                if (currentByte >= ZERO && currentByte <= NINE) {
                    continue;
                } else if (currentByte >= A && currentByte <= F) {
                    continue;
                } else if (currentByte >= A && currentByte <= F) {
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

    /// @notice This function validates if a json string is valid.
    /// @dev JSON strings are surrounded by double quotes.
    /// @param json The JSON string (as a bytes array) to validate.
    /// @param position The current position in the JSON string.
    /// @param maxPosition The length of the JSON string.
    /// @return uint256 The new position in the JSON string.
    /// @return bool Returns true if the JSON string is valid, false otherwise.
    function isValidString(bytes memory json, uint256 position, uint256 maxPosition)
        internal
        pure
        returns (uint256, bool)
    {
        if (json[position] != QUOTE) {
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
            if (json[position] == QUOTE) {
                return (position + 1, true);
            } else if (json[position] == BACKSLASH) {
                escaped = true;
            } else if (json[position] < 0x20) {
                return (position, false);
            }

            position++;
        }
        return (position, false);
    }

    /// @notice This function skips all white space in between non white space characters 
    /// @param data The JSON string (as a bytes array) to validate.
    /// @param position The current position in the JSON string.
    /// @param maxPosition The length of the JSON string.
    /// @return uint256 The new position in the JSON string.
    function skipSpace(bytes memory data, uint256 position, uint256 maxPosition) public pure returns (uint256) {
        // does this handle new lines
        while (position < maxPosition) {
            if (data[position] != SPACE) {
                return position;
            }
            position++;
        }
        return 0;
    }
}
