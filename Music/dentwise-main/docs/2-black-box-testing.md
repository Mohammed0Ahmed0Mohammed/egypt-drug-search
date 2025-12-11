# Black Box Testing - DentWise Application

## 1. Testing Approach

This document outlines the black-box testing strategy using:
- **Equivalence Partitioning (EP)**: Dividing input data into valid and invalid partitions
- **Boundary Value Analysis (BVA)**: Testing at the edges of input ranges

---

## 2. Test Cases for formatPhoneNumber Function

### 2.1 Equivalence Partitioning Analysis

| Partition | Description | Valid/Invalid | Example Input |
|-----------|-------------|---------------|---------------|
| EP1 | Empty string | Valid | "" |
| EP2 | 1-3 digits | Valid | "011" |
| EP3 | 4-6 digits | Valid | "011245" |
| EP4 | 7-9 digits | Valid | "011245552" |
| EP5 | 10-11 digits | Valid | "01124555246" |
| EP6 | More than 11 digits | Valid (truncated) | "011245552461234" |
| EP7 | Contains letters | Valid (stripped) | "011abc245" |
| EP8 | Contains special chars | Valid (stripped) | "(+2) 011-245" |

### 2.2 Boundary Value Analysis

| Boundary | Description | Input | Expected Output |
|----------|-------------|-------|-----------------|
| BVA1 | Min length (0) | "" | "" |
| BVA2 | Min+1 (1 digit) | "0" | "(+2) 0" |
| BVA3 | Partition edge (3 digits) | "011" | "(+2) 011" |
| BVA4 | Partition edge (4 digits) | "0112" | "(+2) 011 2" |
| BVA5 | Partition edge (6 digits) | "011245" | "(+2) 011 245" |
| BVA6 | Partition edge (7 digits) | "0112455" | "(+2) 011 245 5" |
| BVA7 | Partition edge (9 digits) | "011245552" | "(+2) 011 245 552" |
| BVA8 | Partition edge (10 digits) | "0112455524" | "(+2) 011 245 552 4" |
| BVA9 | Max valid (11 digits) | "01124555246" | "(+2) 011 245 552 46" |
| BVA10 | Max+1 (12 digits) | "011245552461" | "(+2) 011 245 552 46" |

---

## 3. Detailed Test Case Table

### TC-BB-01: Empty String Input
| Field | Value |
|-------|-------|
| **Test Case ID** | TC-BB-01 |
| **Description** | Verify empty string returns empty string |
| **Preconditions** | None |
| **Test Data** | Input: "" |
| **Steps** | 1. Call formatPhoneNumber("") |
| **Expected Result** | Returns "" |
| **Actual Result** | "" |
| **Status** | ✅ PASS |
| **Technique** | EP1, BVA1 |

### TC-BB-02: Single Digit Input
| Field | Value |
|-------|-------|
| **Test Case ID** | TC-BB-02 |
| **Description** | Verify single digit is formatted correctly |
| **Preconditions** | None |
| **Test Data** | Input: "0" |
| **Steps** | 1. Call formatPhoneNumber("0") |
| **Expected Result** | Returns "(+2) 0" |
| **Actual Result** | "(+2) 0" |
| **Status** | ✅ PASS |
| **Technique** | BVA2 |

### TC-BB-03: Three Digit Input
| Field | Value |
|-------|-------|
| **Test Case ID** | TC-BB-03 |
| **Description** | Verify 3-digit number is formatted with country code |
| **Preconditions** | None |
| **Test Data** | Input: "011" |
| **Steps** | 1. Call formatPhoneNumber("011") |
| **Expected Result** | Returns "(+2) 011" |
| **Actual Result** | "(+2) 011" |
| **Status** | ✅ PASS |
| **Technique** | EP2, BVA3 |

### TC-BB-04: Six Digit Input
| Field | Value |
|-------|-------|
| **Test Case ID** | TC-BB-04 |
| **Description** | Verify 6-digit number is formatted with proper spacing |
| **Preconditions** | None |
| **Test Data** | Input: "011245" |
| **Steps** | 1. Call formatPhoneNumber("011245") |
| **Expected Result** | Returns "(+2) 011 245" |
| **Actual Result** | "(+2) 011 245" |
| **Status** | ✅ PASS |
| **Technique** | EP3, BVA5 |

### TC-BB-05: Nine Digit Input
| Field | Value |
|-------|-------|
| **Test Case ID** | TC-BB-05 |
| **Description** | Verify 9-digit number is formatted correctly |
| **Preconditions** | None |
| **Test Data** | Input: "011245552" |
| **Steps** | 1. Call formatPhoneNumber("011245552") |
| **Expected Result** | Returns "(+2) 011 245 552" |
| **Actual Result** | "(+2) 011 245 552" |
| **Status** | ✅ PASS |
| **Technique** | EP4, BVA7 |

### TC-BB-06: Full Egyptian Phone Number (11 digits)
| Field | Value |
|-------|-------|
| **Test Case ID** | TC-BB-06 |
| **Description** | Verify complete Egyptian phone number formatting |
| **Preconditions** | None |
| **Test Data** | Input: "01124555246" |
| **Steps** | 1. Call formatPhoneNumber("01124555246") |
| **Expected Result** | Returns "(+2) 011 245 552 46" |
| **Actual Result** | "(+2) 011 245 552 46" |
| **Status** | ✅ PASS |
| **Technique** | EP5, BVA9 |

### TC-BB-07: Input with Special Characters
| Field | Value |
|-------|-------|
| **Test Case ID** | TC-BB-07 |
| **Description** | Verify special characters are stripped |
| **Preconditions** | None |
| **Test Data** | Input: "(+2) 011-245-5524" |
| **Steps** | 1. Call formatPhoneNumber("(+2) 011-245-5524") |
| **Expected Result** | Returns "(+2) 011 245 552 4" |
| **Actual Result** | "(+2) 011 245 552 4" |
| **Status** | ✅ PASS |
| **Technique** | EP8 |

### TC-BB-08: Input with Spaces
| Field | Value |
|-------|-------|
| **Test Case ID** | TC-BB-08 |
| **Description** | Verify spaces in input are handled |
| **Preconditions** | None |
| **Test Data** | Input: "011 245 552" |
| **Steps** | 1. Call formatPhoneNumber("011 245 552") |
| **Expected Result** | Returns "(+2) 011 245 552" |
| **Actual Result** | "(+2) 011 245 552" |
| **Status** | ✅ PASS |
| **Technique** | EP8 |

### TC-BB-09: Four Digit Input (Boundary)
| Field | Value |
|-------|-------|
| **Test Case ID** | TC-BB-09 |
| **Description** | Verify 4-digit boundary is handled |
| **Preconditions** | None |
| **Test Data** | Input: "0112" |
| **Steps** | 1. Call formatPhoneNumber("0112") |
| **Expected Result** | Returns "(+2) 011 2" |
| **Actual Result** | "(+2) 011 2" |
| **Status** | ✅ PASS |
| **Technique** | BVA4 |

### TC-BB-10: Seven Digit Input (Boundary)
| Field | Value |
|-------|-------|
| **Test Case ID** | TC-BB-10 |
| **Description** | Verify 7-digit boundary is handled |
| **Preconditions** | None |
| **Test Data** | Input: "0112455" |
| **Steps** | 1. Call formatPhoneNumber("0112455") |
| **Expected Result** | Returns "(+2) 011 245 5" |
| **Actual Result** | "(+2) 011 245 5" |
| **Status** | ✅ PASS |
| **Technique** | BVA6 |

---

## 4. Test Execution Summary

| Total Test Cases | Passed | Failed | Pass Rate |
|-----------------|--------|--------|-----------|
| 10 | 10 | 0 | 100% |

---

## 5. Additional Test Cases (Other Functions)

### getNext5Days Function

| TC ID | Description | Expected | Status |
|-------|-------------|----------|--------|
| TC-DATE-01 | Returns array of 5 dates | Array.length = 5 | ✅ PASS |
| TC-DATE-02 | Dates in ISO format | YYYY-MM-DD pattern | ✅ PASS |
| TC-DATE-03 | First date is tomorrow | Today + 1 | ✅ PASS |

### getAvailableTimeSlots Function

| TC ID | Description | Expected | Status |
|-------|-------------|----------|--------|
| TC-SLOT-01 | Returns 12 slots | Array.length = 12 | ✅ PASS |
| TC-SLOT-02 | First slot is 09:00 | "09:00" | ✅ PASS |
| TC-SLOT-03 | Last slot is 16:30 | "16:30" | ✅ PASS |
| TC-SLOT-04 | HH:MM format | Pattern match | ✅ PASS |

### generateAvatar Function

| TC ID | Description | Expected | Status |
|-------|-------------|----------|--------|
| TC-AVATAR-01 | Male avatar URL | Contains "boy" | ✅ PASS |
| TC-AVATAR-02 | Female avatar URL | Contains "girl" | ✅ PASS |
| TC-AVATAR-03 | Multiple spaces handled | Spaces removed | ✅ PASS |

---

## 6. Jira Test Case Upload Format

```
Test Case ID: TC-BB-XX
Summary: [Brief description]
Priority: Medium
Test Type: Functional
Preconditions: [Any setup needed]
Test Steps:
  1. [Step description]
Expected Result: [What should happen]
Actual Result: [What happened]
Status: Pass/Fail
Attachments: [Screenshots if needed]
```
