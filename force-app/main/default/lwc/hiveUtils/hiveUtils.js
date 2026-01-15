/*
 * author: Anujit
 * hiveUtils.js
 * Place to keep common functions
 * 
 ---------------------------------------------------------------------------------------------------------------------------------------------
 @ Change history: 11.12.2024 / Sothea Horn / US-0015300 - Generic LWC Exception handling & Application to program participation component
 *********************************************************************************************************************************************/

import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 

const month = ["January","February","March","April","May","June","July","August","September","October","November","December"];


/**
 * 
* @returns - returns the previous month
 */
export function getPreviousMonth(){
    const d = new Date();
    return month[d.getMonth()-1];
}
/**
 * 
 * @returns - returns the month
 */
export function getCurrentMonth(){
    const d = new Date();
    return month[d.getMonth()];
}


/**
 * 
 * @param value 
 * @returns if the value is null or undefined or zero
 */
export function isNullorUndefinedorZero(value){
    return value === null || value === undefined || value === 0 || value === '';
}

/**
 * 
 * @param myNumber 
 * @returns positive or negative sign
 */
export function displayPositiveorNegativeSign(myNumber){
    return new Intl.NumberFormat("en-US", {
        signDisplay: "exceptZero"
    }).format(myNumber);
}

/**
 * 
 * @param {*} stringToFormat 
 * @param  {...any} formattingArguments 
 * @returns formatted string
 */
export function formatLabel(stringToFormat, ...formattingArguments) {
    if (typeof stringToFormat !== 'string') throw new Error('\'stringToFormat\' must be a String');
    return stringToFormat.replace(/{(\d+)}/gm, (match, index) =>
        (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));     
}
/**
 * 
 * @param {*} stringValue 
 * @param {*} str 
 * @returns string after removing the last occurance of the string
 */
export function removeString(stringValue,str){
    if(!stringValue.includes(str)){
        return stringValue;
    }
    let lastIndex = stringValue.lastIndexOf(str);
    stringValue = stringValue.substring(0, lastIndex);
    return stringValue;
}

/**
 * 
 * @param {*} originalStr 
 * @param {*} textToReplace 
 * @param {*} replaceText 
 * @returns replaced string
 */
export function replaceString(originalStr,textToReplace,replaceText){
    if(!originalStr.includes(val)){
        return originalStr;
    }
    let replacedString = originalStr.replace(textToReplace,replaceText);
    return replacedString;
}

/**
 * Name: showToastEvent
 * Purpose: show the toast message
 * @param cmp
 * @param attr
 */
export function showToastMessage(cmp, attr){
    let event = new ShowToastEvent(attr);
    cmp.dispatchEvent(event);
}

/**
 * Reduces one or more LDS errors into a string[] of error messages.
 * @param errors    Object of Error thrown
 * @return an array of error message
 * 
 ------------------------------------------------------------------------------------------------------------------------------
 * @ Change history: 11.12.2024 / Sothea Horn / Create method
 *                   US-0015300 - Generic LWC Exception handling & Application to program participation component
 ------------------------------------------------------------------------------------------------------------------------------*/
export function reduceErrors(errors) {
    if (!Array.isArray(errors)) {
        errors = [errors];
    }
    return (
        errors
            // Remove null/undefined items
            .filter((error) => !!error)
            // Extract an error message
            .map((error) => {
                // UI API read errors
                if (Array.isArray(error.body)) {
                    return error.body.map((e) => e.message);
                }
                // Page level errors
                else if (
                    error?.body?.pageErrors &&
                    error.body.pageErrors.length > 0
                ) {
                    return error.body.pageErrors.map((e) => e.message);
                }
                // Field level errors
                else if (
                    error?.body?.fieldErrors &&
                    Object.keys(error.body.fieldErrors).length > 0
                ) {
                    const fieldErrors = [];
                    Object.values(error.body.fieldErrors).forEach(
                        (errorArray) => {
                            fieldErrors.push(
                                ...errorArray.map((e) => e.message)
                            );
                        }
                    );
                    return fieldErrors;
                }
                // UI API DML page level errors
                else if (
                    error?.body?.output?.errors &&
                    error.body.output.errors.length > 0
                ) {
                    return error.body.output.errors.map((e) => e.message);
                }
                // UI API DML field level errors
                else if (
                    error?.body?.output?.fieldErrors &&
                    Object.keys(error.body.output.fieldErrors).length > 0
                ) {
                    const fieldErrors = [];
                    Object.values(error.body.output.fieldErrors).forEach(
                        (errorArray) => {
                            fieldErrors.push(
                                ...errorArray.map((e) => e.message)
                            );
                        }
                    );
                    return fieldErrors;
                }
                // UI API DML, Apex and network errors
                else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                }
                // JS errors
                else if (typeof error.message === 'string') {
                    return error.message;
                }
                // Unknown error shape so try HTTP status text
                return error.statusText;
            })
            // Flatten
            .reduce((prev, curr) => prev.concat(curr), [])
            // Remove empty strings
            .filter((message) => !!message)
    );

   
}

//NK:21/02/2025
// Example usage
// console.log(validateTimeString("12:34")); // true
// console.log(validateTimeString("23:59")); // true
// console.log(validateTimeString("0:0"));   // true
// console.log(validateTimeString("24:00")); // false
// console.log(validateTimeString("12:60")); // false
// console.log(validateTimeString("12:5"));  // true
// console.log(validateTimeString("5:59"));  // true
// console.log(validateTimeString("05:59")); // true
// console.log(validateTimeString("5:9"));   // true
export function validateTimeString(timeString) {
    // Regular expression to match the pattern "0-23:0-59"
    const timePattern = /^(?:[01]?\d|2[0-3]):[0-5]?\d$/;

    // Test the timeString against the regular expression
    return timePattern.test(timeString);
}
//NK:21/02/2025
// Example usage
// console.log(validateDateString("02/29/2024", "MM/DD/YYYY")); // true (2024 is a leap year)
// console.log(validateDateString("2/9/2024", "MM/DD/YYYY"));   // true
// console.log(validateDateString("29/02/2024", "DD/MM/YYYY")); // true (2024 is a leap year)
// console.log(validateDateString("2/9/2024", "DD/MM/YYYY"));   // false (Invalid day/month combination for DD/MM/YYYY)
// console.log(validateDateString("2024/02/29", "YYYY/MM/DD")); // true
// console.log(validateDateString("2024/2/9", "YYYY/MM/DD"));   // true
// console.log(validateDateString("12/31/2025", "MM/DD/YYYY")); // true
// console.log(validateDateString("31/12/2025", "DD/MM/YYYY")); // true
// console.log(validateDateString("2025/12/31", "YYYY/MM/DD")); // true
export function validateDateString(dateString, validFormat) {
    // Generate the regular expression based on the validFormat
    let datePattern;
    switch (validFormat) {
        case 'MM/DD/YYYY':
            datePattern = /^(0?[1-9]|1[0-2])\/(0?[1-9]|[12]\d|3[01])\/(\d{4})$/;
            break;
        case 'DD/MM/YYYY':
            datePattern = /^(0?[1-9]|[12]\d|3[01])\/(0?[1-9]|1[0-2])\/(\d{4})$/;
            break;
        case 'YYYY/MM/DD':
            datePattern = /^(\d{4})\/(0?[1-9]|1[0-2])\/(0?[1-9]|[12]\d|3[01])$/;
            break;
        default:
            throw new Error('Unsupported date format');
    }

    // Test the dateString against the regular expression
    if (!datePattern.test(dateString)) {
        return false;
    }

    // Parse the date parts based on the format
    let parts, month1, day, year;
    switch (validFormat) {
        case 'MM/DD/YYYY':
            parts = dateString.split('/');
            month1 = parseInt(parts[0], 10);
            day = parseInt(parts[1], 10);
            year = parseInt(parts[2], 10);
            break;
        case 'DD/MM/YYYY':
            parts = dateString.split('/');
            day = parseInt(parts[0], 10);
            month1 = parseInt(parts[1], 10);
            year = parseInt(parts[2], 10);
            break;
        case 'YYYY/MM/DD':
            parts = dateString.split('/');
            year = parseInt(parts[0], 10);
            month1 = parseInt(parts[1], 10);
            day = parseInt(parts[2], 10);
            break;
        default:
            return false; // This case should never be reached due to the earlier error throw
    }

    // Check if the date is valid
    const date = new Date(year, month1 - 1, day);
    return date.getFullYear() === year && date.getMonth() === month1 - 1 && date.getDate() === day;
}

//NK:21/02/2025
// Example usage - to SFDC system date format
// console.log(convertToStandardDateFormat("02/29/2024", "MM/DD/YYYY")); // "2024-02-29"
// console.log(convertToStandardDateFormat("2/9/2024", "MM/DD/YYYY"));   // "2024-02-09"
// console.log(convertToStandardDateFormat("29/02/2024", "DD/MM/YYYY")); // "2024-02-29"
// console.log(convertToStandardDateFormat("2/9/2024", "DD/MM/YYYY"));   // "2024-09-02"
// console.log(convertToStandardDateFormat("2024/02/29", "YYYY/MM/DD")); // "2024-02-29"
// console.log(convertToStandardDateFormat("2024/2/9", "YYYY/MM/DD"));   // "2024-02-09"
// console.log(convertToStandardDateFormat("12/31/2025", "MM/DD/YYYY")); // "2025-12-31"
// console.log(convertToStandardDateFormat("31/12/2025", "DD/MM/YYYY")); // "2025-12-31"
// console.log(convertToStandardDateFormat("2025/12/31", "YYYY/MM/DD")); // "2025-12-31"
export function convertToStandardDateFormat(dateString, validFormat) {
    // Generate the regular expression based on the validFormat
    let datePattern;
    switch (validFormat) {
        case 'MM/DD/YYYY':
            datePattern = /^(0?[1-9]|1[0-2])\/(0?[1-9]|[12]\d|3[01])\/(\d{4})$/;
            break;
        case 'DD/MM/YYYY':
            datePattern = /^(0?[1-9]|[12]\d|3[01])\/(0?[1-9]|1[0-2])\/(\d{4})$/;
            break;
        case 'YYYY/MM/DD':
            datePattern = /^(\d{4})\/(0?[1-9]|1[0-2])\/(0?[1-9]|[12]\d|3[01])$/;
            break;
        default:
            throw new Error('Unsupported date format');
    }

    // Test the dateString against the regular expression
    if (!datePattern.test(dateString)) {
        throw new Error('Invalid date string');
    }

    // Parse the date parts based on the format
    let parts, month1, day, year;
    switch (validFormat) {
        case 'MM/DD/YYYY':
            parts = dateString.split('/');
            month1 = parts[0].padStart(2, '0');
            day = parts[1].padStart(2, '0');
            year = parts[2];
            break;
        case 'DD/MM/YYYY':
            parts = dateString.split('/');
            day = parts[0].padStart(2, '0');
            month1 = parts[1].padStart(2, '0');
            year = parts[2];
            break;
        case 'YYYY/MM/DD':
            parts = dateString.split('/');
            year = parts[0];
            month1 = parts[1].padStart(2, '0');
            day = parts[2].padStart(2, '0');
            break;
        default:
            throw new Error('Unsupported date format');
    }

    // Return the date in "YYYY-MM-DD" format
    return `${year}-${month1}-${day}`;
}
//NK:21/02/2025
// Example usage
// console.log(convertTimeFormat("0:00")); // Output: "00:00"
// console.log(convertTimeFormat("0:0"));  // Output: "00:00"
// console.log(convertTimeFormat("1:5"));  // Output: "01:05"
// console.log(convertTimeFormat("12:30")); // Output: "12:30"
export function convertTimeFormat(timeString) {
    // Split the time string into hours and minutes
    let [hours, minutes] = timeString.split(':');

    // Pad the hours and minutes with leading zeros if necessary
    hours = hours.padStart(2, '0');
    minutes = minutes.padStart(2, '0');

    // Combine the hours and minutes back into the desired format
    return `${hours}:${minutes}`;
}
//NK:21/02/2025
export function parseDateString(dateString, format) {
    let parts;
    switch (format) {
        case 'MM/DD/YYYY':
            parts = dateString.split('/');
            return new Date(parts[2], parts[0] - 1, parts[1]);
        case 'DD/MM/YYYY':
            parts = dateString.split('/');
            return new Date(parts[2], parts[1] - 1, parts[0]);
        case 'YYYY/MM/DD':
            parts = dateString.split('/');
            return new Date(parts[0], parts[1] - 1, parts[2]);
        default:
            throw new Error('Unsupported date format');
    }
}
//NK:21/02/2025
// Example usage
// const dateString1 = '02/20/2025';
// const dateString2 = '02/25/2025';
// const format = 'MM/DD/YYYY';

// const result = compareDates(dateString1, dateString2, format);
// console.log(result); // Output: 1 (Earlier)
export function compareDates(dateString1, dateString2, format) {
    const date1 = parseDateString(dateString1, format);
    const date2 = parseDateString(dateString2, format);

    if (date1.getTime() === date2.getTime()) {
        return 0; // Same day
    } else if (date1.getTime() < date2.getTime()) {
        return 1; // Earlier
    }  
    return 2; // Later
     
}
//NK:21/02/2025
// Example usage
// const todayDateString = getTodayDateString('MM/DD/YYYY');
// console.log(todayDateString); // Output: "02/24/2025" (or the current date)
export function getTodayDateString(format) {
    const today = new Date();
    let day = today.getDate();
    let month1 = today.getMonth() + 1; // Months are zero-based
    const year = today.getFullYear();

    // Pad day and month with leading zeros if necessary
    day = day < 10 ? '0' + day : day;
    month1 = month1 < 10 ? '0' + month1 : month1;

    switch (format) {
        case 'MM/DD/YYYY':
            return `${month1}/${day}/${year}`;
        case 'DD/MM/YYYY':
            return `${day}/${month1}/${year}`;
        case 'YYYY/MM/DD':
            return `${year}/${month1}/${day}`;
        default:
            throw new Error('Unsupported date format');
    }   
}
//NK:31/03/2025
export function safeParseFloat(value) {
    // Check if the value is a valid number
    if (!/^-?\d+(\.\d+)?$/.test(value)) {
        return NaN; // Return NaN for invalid numbers
    }
    return parseFloat(value);
}
//NK:31/03/2025
export function safeParseInt(value) {
    // Check if the value is a valid integer
    if (!/^-?\d+$/.test(value)) {
        return NaN; // Return NaN for invalid integers
    }
    return parseInt(value, 10);
}