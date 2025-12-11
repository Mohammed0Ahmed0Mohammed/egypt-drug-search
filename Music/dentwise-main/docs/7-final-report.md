# DentWise - Software Testing Project Report

## Cover Page

---

# Software Testing Assignment

## WhiteBoxSample - Java Testing Project

---

**Course**: Software Testing  
**Semester**: Fall 2024  
**Instructor**: [Instructor Name]

---

### Team Members

| # | Name | Student ID | Role |
|---|------|------------|------|
| 1 | محمد أحمد محمد | - | Team Lead |
| 2 | علي سيد | - | QA Engineer |
| 3 | حبيبه كرم | - | QA Engineer |

---

**Submission Date**: [Date]

---

## Table of Contents

1. [Test Plan](#1-test-plan)
2. [Requirements Analysis](#2-requirements-analysis)
3. [Black Box Testing](#3-black-box-testing)
4. [White Box Testing](#4-white-box-testing)
5. [Unit Testing (JUnit)](#5-unit-testing-junit)
6. [Agile Testing](#6-agile-testing)
7. [Bug Reports](#7-bug-reports)
8. [Conclusions](#8-conclusions)

---

## 1. Test Plan

### 1.1 Introduction

**Project**: WhiteBoxSample - Java Application  
**Application Type**: Java Application (Banking System Simulation)  
**Testing Period**: Sprint 1 (2 weeks)

### 1.2 Objectives

- Apply functional (black-box) and structural (white-box) testing techniques
- Automate unit tests using JUnit 5
- Manage test cases and report defects
- Simulate Agile testing environment
- Demonstrate test planning, execution, and reporting

### 1.3 Scope

#### In Scope:
- Account class (deposit, withdraw, freeze)
- TransactionProcessor (transfer, calculateFee)
- SecurityUtils (password validation, sanitization)
- DiscountCalculator (discount calculations)

#### Out of Scope:
- Database testing
- API integration testing
- Performance testing

### 1.4 Test Strategy

| Testing Type | Technique | Tools |
|--------------|-----------|-------|
| Black Box | EP, BVA | JUnit 5 |
| White Box | Path Coverage, CFG | JUnit 5, JaCoCo |
| Unit Testing | Automated | JUnit 5 |
| Agile | Scrum | Jira |

---

## 2. Requirements Analysis

### 2.1 Functional Requirements (7)

| ID | Requirement | Description |
|----|-------------|-------------|
| FR-01 | Account Creation | Create accounts with ID, balance, and type |
| FR-02 | Deposit | Add money to account with validation |
| FR-03 | Withdraw | Remove money with balance check |
| FR-04 | Transfer | Move money between accounts with fees |
| FR-05 | Fee Calculation | Calculate fees based on customer type |
| FR-06 | Password Validation | Check password strength |
| FR-07 | Discount Calculation | Calculate discounts based on customer loyalty |

### 2.2 Non-Functional Requirements

| ID | Requirement | Metric |
|----|-------------|--------|
| NFR-01 | Performance | Calculations < 10ms |
| NFR-02 | Security | Password validation enforced |
| NFR-03 | Reliability | No data loss on exceptions |

---

## 3. Black Box Testing

### 3.1 Techniques Used

1. **Equivalence Partitioning (EP)**
2. **Boundary Value Analysis (BVA)**

### 3.2 Test Cases for calculateFee

| TC ID | Input (Type, Amount) | Expected | Technique |
|-------|---------------------|----------|-----------|
| TC-01 | VIP, 2000 | 10.0 (0.5%) | EP |
| TC-02 | VIP, 500 | 5.0 (1%) | EP |
| TC-03 | VIP, 1000 | 10.0 (boundary) | BVA |
| TC-04 | VIP, 1001 | 5.005 (boundary) | BVA |
| TC-05 | PREMIUM, 1000 | 15.0 (1.5%) | EP |
| TC-06 | REGULAR, 100 | 2.0 (2%) | EP |
| TC-07 | REGULAR, 30 | 1.0 (fixed) | EP |
| TC-08 | REGULAR, 49 | 1.0 (boundary) | BVA |
| TC-09 | REGULAR, 50 | 1.0 (boundary) | BVA |
| TC-10 | ANY, 0 | 0.0 (edge) | BVA |

---

## 4. White Box Testing

### 4.1 Selected Function: calculateFee

```java
public double calculateFee(CustomerType type, double amount) {
    if (amount <= 0) return 0.0;
    switch (type) {
        case VIP:
            if (amount > 1000) return amount * 0.005;
            return amount * 0.01;
        case PREMIUM:
            return amount * 0.015;
        case REGULAR:
        default:
            if (amount < 50) return 1.0;
            return amount * 0.02;
    }
}
```

### 4.2 Cyclomatic Complexity

**V(G) = 6**

### 4.3 Control Flow Graph

```
START → [amount<=0?] → YES → return 0 → END
              ↓ NO
        [switch type]
         ↓    ↓    ↓
       VIP PREMIUM REGULAR
         ↓    ↓    ↓
    [>1000?] 1.5% [<50?]
     ↓   ↓        ↓   ↓
   0.5%  1%     1.0  2%
         ↓
        END
```

### 4.4 Independent Paths (6)

| Path | Condition | Test Case |
|------|-----------|-----------|
| 1 | amount <= 0 | TC-FEE-08 |
| 2 | VIP, amount > 1000 | TC-FEE-01 |
| 3 | VIP, amount <= 1000 | TC-FEE-02 |
| 4 | PREMIUM | TC-FEE-04 |
| 5 | REGULAR, amount < 50 | TC-FEE-06 |
| 6 | REGULAR, amount >= 50 | TC-FEE-05 |

---

## 5. Unit Testing (JUnit)

### 5.1 Framework: JUnit 5

### 5.2 Test Summary

| Class | Test Cases | Passed |
|-------|------------|--------|
| Account | 11 | 11 ✅ |
| TransactionProcessor | 9 | 9 ✅ |
| calculateFee | 8 | 8 ✅ |
| isPasswordStrong | 7 | 7 ✅ |
| sanitize | 5 | 5 ✅ |
| DiscountCalculator | 10 | 10 ✅ |
| **Total** | **50** | **50 ✅** |

### 5.3 Test Categories

| Category | Count |
|----------|-------|
| Normal | 25 |
| Exception | 10 |
| Edge | 8 |
| Boundary | 7 |

### 5.4 Running Tests

```bash
cd java-testing
mvn test
mvn test jacoco:report
```

---

## 6. Agile Testing

### 6.1 Sprint Summary

| Metric | Value |
|--------|-------|
| Sprint Duration | 2 weeks |
| Story Points | 32 |
| Completed | 32 (100%) |

### 6.2 User Stories

| ID | Story | Points |
|----|-------|--------|
| US-01 | Requirements Analysis | 5 |
| US-02 | Black-Box Testing | 8 |
| US-03 | White-Box Testing | 8 |
| US-04 | Unit Testing | 5 |
| US-05 | Documentation | 3 |
| US-06 | Bug Reporting | 3 |

### 6.3 Sprint Board (Final)

| To Do | In Progress | Done |
|-------|-------------|------|
| - | - | All 6 stories ✅ |

---

## 7. Bug Reports

### BUG-001: Phone Truncation
- **Severity**: Medium
- **Status**: Open
- **Description**: Phone numbers > 11 digits silently truncated

### BUG-002: Missing Coverage
- **Severity**: Low
- **Status**: Open
- **Description**: Some edge cases in DiscountCalculator

---

## 8. Conclusions

### 8.1 Summary

| Deliverable | Status |
|-------------|--------|
| Requirements Analysis | ✅ |
| Black Box Testing (10+ cases) | ✅ |
| White Box Testing (CFG, CC=6) | ✅ |
| Unit Testing (50 tests) | ✅ |
| Agile Documentation | ✅ |
| Bug Reports (2) | ✅ |

### 8.2 Key Metrics

| Metric | Value |
|--------|-------|
| Test Cases | 50 |
| Pass Rate | 100% |
| Cyclomatic Complexity | 6 |
| Independent Paths | 6 |
| Coverage | 97%+ |

### 8.3 Files Submitted

```
java-testing/
├── pom.xml
├── src/main/java/vv/sample/WhiteBoxSample.java
└── src/test/java/vv/sample/WhiteBoxSampleTest.java
docs/
├── 1-requirements-analysis.md
├── 2-black-box-testing.md
├── 3-white-box-testing.md
├── 4-unit-testing.md
├── 5-agile-testing.md
├── 6-bug-reports.md
└── 7-final-report.md
```

---

**End of Report**
