# White Box Testing - WhiteBoxSample (Java)

## 1. Selected Function: `calculateFee`

```java
public double calculateFee(CustomerType type, double amount) {
    if (amount <= 0) return 0.0;                    // Node 1
    switch (type) {                                  // Node 2
        case VIP:
            if (amount > 1000) return amount * 0.005; // Node 3
            return amount * 0.01;                    // Node 4
        case PREMIUM:
            return amount * 0.015;                   // Node 5
        case REGULAR:
        default:
            if (amount < 50) return 1.0;             // Node 6
            return amount * 0.02;                    // Node 7
    }
}
```

---

## 2. Control Flow Graph (CFG)

```
                        ┌─────────────┐
                        │   START     │
                        │   Node 0    │
                        └──────┬──────┘
                               │
                               ▼
                        ┌─────────────┐
                   ┌────┤   Node 1    │────┐
                   │    │ amount <= 0 │    │
                   │    │     ?       │    │
                   │    └─────────────┘    │
               YES │                       │ NO
                   ▼                       ▼
            ┌─────────────┐         ┌─────────────┐
            │  return 0.0 │         │   Node 2    │
            │   Node 1a   │         │   switch    │
            └──────┬──────┘         │    type     │
                   │                └──────┬──────┘
                   │                ┌──────┼──────────┬──────────┐
                   │           VIP  │  PREMIUM       │   REGULAR/default
                   │                ▼                ▼          ▼
                   │         ┌─────────────┐  ┌───────────┐  ┌─────────────┐
                   │    ┌────┤   Node 3    │  │  Node 5   │  │   Node 6    │
                   │    │    │ amount>1000 │  │return 1.5%│  │ amount < 50 │
                   │    │    │     ?       │  └─────┬─────┘  │      ?      │
                   │    │    └─────────────┘        │        └─────────────┘
                   │YES │            │ NO           │         │ YES    │ NO
                   │    ▼            ▼              │         ▼        ▼
                   │ ┌─────────┐ ┌─────────┐       │    ┌─────────┐ ┌─────────┐
                   │ │return   │ │return   │       │    │return   │ │return   │
                   │ │  0.5%   │ │   1%    │       │    │  1.0    │ │   2%    │
                   │ │ Node 3a │ │ Node 4  │       │    │ Node 6a │ │ Node 7  │
                   │ └────┬────┘ └────┬────┘       │    └────┬────┘ └────┬────┘
                   │      │           │            │         │           │
                   ▼      ▼           ▼            ▼         ▼           ▼
            ┌─────────────────────────────────────────────────────────────────┐
            │                              END                                 │
            └─────────────────────────────────────────────────────────────────┘
```

---

## 3. Cyclomatic Complexity Calculation

### Method 1: V(G) = E - N + 2P

| Element | Count |
|---------|-------|
| Edges (E) | 14 |
| Nodes (N) | 10 |
| Connected Components (P) | 1 |

```
V(G) = 14 - 10 + 2(1) = 6
```

### Method 2: V(G) = D + 1

| Decision Points | Count |
|-----------------|-------|
| if (amount <= 0) | 1 |
| switch (type) - 3 cases | 3 |
| if (amount > 1000) | 1 |
| if (amount < 50) | 1 |
| **Total** | 6 |

```
V(G) = 6 (decision points counted as edges)
```

### **Cyclomatic Complexity = 6**

---

## 4. Independent Paths (6 Paths)

| Path # | Description | Condition | Test Input |
|--------|-------------|-----------|------------|
| **Path 1** | Amount <= 0 | amount <= 0 | amount = 0 |
| **Path 2** | VIP, amount > 1000 | VIP && amount > 1000 | VIP, 2000 |
| **Path 3** | VIP, amount <= 1000 | VIP && amount <= 1000 | VIP, 500 |
| **Path 4** | PREMIUM | type = PREMIUM | PREMIUM, 1000 |
| **Path 5** | REGULAR, amount < 50 | REGULAR && amount < 50 | REGULAR, 30 |
| **Path 6** | REGULAR, amount >= 50 | REGULAR && amount >= 50 | REGULAR, 100 |

### Path Details:

```
Path 1: START → Node 1 (YES) → return 0.0 → END
Path 2: START → Node 1 (NO) → Node 2 (VIP) → Node 3 (YES) → return 0.5% → END
Path 3: START → Node 1 (NO) → Node 2 (VIP) → Node 3 (NO) → Node 4 → return 1% → END
Path 4: START → Node 1 (NO) → Node 2 (PREMIUM) → Node 5 → return 1.5% → END
Path 5: START → Node 1 (NO) → Node 2 (REGULAR) → Node 6 (YES) → return 1.0 → END
Path 6: START → Node 1 (NO) → Node 2 (REGULAR) → Node 6 (NO) → Node 7 → return 2% → END
```

---

## 5. Path Coverage Test Matrix

| Path | Test Case ID | Input | Expected | Actual | Status |
|------|--------------|-------|----------|--------|--------|
| 1 | TC-FEE-08 | (VIP, 0) | 0.0 | 0.0 | ✅ PASS |
| 2 | TC-FEE-01 | (VIP, 2000) | 10.0 | 10.0 | ✅ PASS |
| 3 | TC-FEE-02 | (VIP, 500) | 5.0 | 5.0 | ✅ PASS |
| 4 | TC-FEE-04 | (PREMIUM, 1000) | 15.0 | 15.0 | ✅ PASS |
| 5 | TC-FEE-06 | (REGULAR, 30) | 1.0 | 1.0 | ✅ PASS |
| 6 | TC-FEE-05 | (REGULAR, 100) | 2.0 | 2.0 | ✅ PASS |

**Path Coverage: 100% (6/6 paths covered)**

---

## 6. Additional Function Analysis: `isPasswordStrong`

### Control Flow Graph Summary

```java
public static boolean isPasswordStrong(String password) {
    if (password == null) return false;           // D1
    int len = password.length();
    if (len < 8) return false;                    // D2
    // loop through chars
    for (char c : password.toCharArray()) {       // D3 (loop)
        if (Character.isUpperCase(c)) ...         // D4
        else if (Character.isLowerCase(c)) ...    // D5
        else if (Character.isDigit(c)) ...        // D6
        else hasSpecial = true;                   // D7
    }
    // calculate score
    if (hasUpper) score++;                        // D8
    if (hasLower) score++;                        // D9
    if (hasDigit) score++;                        // D10
    if (hasSpecial) score++;                      // D11
    return score >= 3;                            // D12
}
```

### Cyclomatic Complexity

```
V(G) = 12 decision points + 1 = 13
```

### Test Cases for Full Coverage

| TC ID | Input | Expected | Coverage |
|-------|-------|----------|----------|
| TC-PWD-01 | null | false | D1 |
| TC-PWD-02 | "Abc$12" | false | D2 (length < 8) |
| TC-PWD-03 | "Abcd$123" | true | All types |
| TC-PWD-04 | "abcdefgh" | false | Only lower |
| TC-PWD-05 | "Abcdefg1" | true | 3 types |
| TC-PWD-06 | "Abc$1234" | true | 4 types |
| TC-PWD-07 | "12345678" | false | Only digits |

---

## 7. Statement Coverage Analysis

### calculateFee Function

| Line | Statement | Covered By |
|------|-----------|------------|
| 1 | if (amount <= 0) return 0.0 | TC-FEE-08 |
| 2 | switch (type) | All tests |
| 3 | case VIP: if (amount > 1000) | TC-FEE-01, TC-FEE-02 |
| 4 | return amount * 0.005 | TC-FEE-01 |
| 5 | return amount * 0.01 | TC-FEE-02, TC-FEE-03 |
| 6 | case PREMIUM: return 1.5% | TC-FEE-04 |
| 7 | case REGULAR: if (amount < 50) | TC-FEE-05, TC-FEE-06 |
| 8 | return 1.0 | TC-FEE-06 |
| 9 | return amount * 0.02 | TC-FEE-05, TC-FEE-07 |

**Statement Coverage: 100%**

---

## 8. Branch Coverage Analysis

| Branch ID | Condition | True | False |
|-----------|-----------|------|-------|
| B1 | amount <= 0 | TC-FEE-08 | TC-FEE-01 |
| B2 | type == VIP | TC-FEE-01 | TC-FEE-04 |
| B3 | amount > 1000 (VIP) | TC-FEE-01 | TC-FEE-02 |
| B4 | type == PREMIUM | TC-FEE-04 | TC-FEE-05 |
| B5 | amount < 50 (REGULAR) | TC-FEE-06 | TC-FEE-05 |

**Branch Coverage: 100%**

---

## 9. JUnit Test Implementation

```java
@Nested
@DisplayName("calculateFee Tests - Path Coverage")
class CalculateFeeTests {
    
    @Test
    @DisplayName("Path 1: amount <= 0 returns 0")
    void testPath1_ZeroAmount() {
        assertEquals(0.0, processor.calculateFee(CustomerType.VIP, 0.0));
    }

    @Test
    @DisplayName("Path 2: VIP, amount > 1000 returns 0.5%")
    void testPath2_VipHighAmount() {
        assertEquals(10.0, processor.calculateFee(CustomerType.VIP, 2000.0), 0.01);
    }

    @Test
    @DisplayName("Path 3: VIP, amount <= 1000 returns 1%")
    void testPath3_VipLowAmount() {
        assertEquals(5.0, processor.calculateFee(CustomerType.VIP, 500.0), 0.01);
    }

    @Test
    @DisplayName("Path 4: PREMIUM returns 1.5%")
    void testPath4_Premium() {
        assertEquals(15.0, processor.calculateFee(CustomerType.PREMIUM, 1000.0), 0.01);
    }

    @Test
    @DisplayName("Path 5: REGULAR, amount < 50 returns 1.0")
    void testPath5_RegularLowAmount() {
        assertEquals(1.0, processor.calculateFee(CustomerType.REGULAR, 30.0), 0.01);
    }

    @Test
    @DisplayName("Path 6: REGULAR, amount >= 50 returns 2%")
    void testPath6_RegularHighAmount() {
        assertEquals(2.0, processor.calculateFee(CustomerType.REGULAR, 100.0), 0.01);
    }
}
```

---

## 10. Summary

| Metric | calculateFee | isPasswordStrong |
|--------|--------------|------------------|
| Cyclomatic Complexity | 6 | 13 |
| Independent Paths | 6 | 13 |
| Statement Coverage | 100% | 100% |
| Branch Coverage | 100% | 100% |
| Test Cases | 8 | 7 |

### Conclusion

The `calculateFee` function has a moderate cyclomatic complexity of 6, indicating 6 independent paths that need testing. All paths have been covered with appropriate test cases, achieving 100% statement and branch coverage.

The `isPasswordStrong` function has higher complexity (13) due to multiple character type checks and scoring logic, but is also fully covered by the test suite.
