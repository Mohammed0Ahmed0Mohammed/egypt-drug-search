# Bug Reports - DentWise Application

## Bug Tracking Overview

| Bug ID | Summary | Severity | Priority | Status |
|--------|---------|----------|----------|--------|
| BUG-001 | Phone number formatting truncates after 11 digits | Medium | Medium | Open |
| BUG-002 | cn utility function not covered in unit tests | Low | Low | Open |

---

## Bug Report #1: BUG-001

### Bug Summary
**Title**: Phone number formatting truncates input after 11 digits without warning

### Bug Details

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-001 |
| **Component** | utils.ts - formatPhoneNumber |
| **Severity** | Medium |
| **Priority** | Medium |
| **Status** | Open |
| **Reporter** | QA Team |
| **Assignee** | Development Team |
| **Date Found** | 2024-01-15 |
| **Environment** | Production |
| **Browser** | All |

### Description
The `formatPhoneNumber` function silently truncates phone numbers longer than 11 digits. Users are not warned that their input is being modified, which could lead to data loss.

### Steps to Reproduce
1. Navigate to any page with phone input field
2. Enter a phone number with more than 11 digits: `011245552461234`
3. Observe the formatted output

### Expected Result
- Either accept all digits with proper formatting
- OR display a validation error message indicating the maximum length

### Actual Result
- Phone number is silently truncated to 11 digits
- Output: `(+2) 011 245 552 46` (only first 11 digits)
- No error or warning message displayed

### Evidence
```typescript
// Current implementation (line 29 in utils.ts)
return `(+2) ${phonenumber.slice(0,3)} ${phonenumber.slice(3,6)} ${phonenumber.slice(6,9)} ${phonenumber.slice(9,11)}`

// This only takes the first 11 digits, ignoring any additional input
```

### Test Case
```typescript
test('should handle phone numbers longer than 11 digits', () => {
  const result = formatPhoneNumber('011245552461234');
  // Currently returns "(+2) 011 245 552 46"
  // Expected: Either format all digits or throw/return error
});
```

### Screenshot/Recording
```
Input:  011245552461234 (15 digits)
Output: (+2) 011 245 552 46 (11 digits formatted)
Lost:   1234 (4 digits silently dropped)
```

### Suggested Fix
1. Add input validation to reject numbers > 11 digits
2. OR extend formatting to handle international numbers
3. Add user feedback for invalid input length

---

## Bug Report #2: BUG-002

### Bug Summary
**Title**: cn utility function has 0% test coverage

### Bug Details

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-002 |
| **Component** | utils.ts - cn function |
| **Severity** | Low |
| **Priority** | Low |
| **Status** | Open |
| **Reporter** | QA Team |
| **Assignee** | Development Team |
| **Date Found** | 2024-01-15 |
| **Environment** | Development |
| **Browser** | N/A |

### Description
The `cn` utility function (line 4-6 in utils.ts) is not covered by any unit tests, resulting in only 80% function coverage and 96.87% line coverage.

### Steps to Reproduce
1. Run `npm run test:coverage`
2. Observe coverage report
3. Note that line 5 is uncovered

### Expected Result
- 100% function coverage
- All utility functions should have unit tests

### Actual Result
- Function coverage: 80%
- Line 5 (`return twMerge(clsx(inputs));`) is uncovered

### Evidence
```
----------|---------|----------|---------|---------|-------------------
File      | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s 
----------|---------|----------|---------|---------|-------------------
All files |   97.29 |      100 |      80 |   96.87 |                   
 utils.ts |   97.29 |      100 |      80 |   96.87 | 5                 
----------|---------|----------|---------|---------|-------------------
```

### Code Location
```typescript
// Line 4-6 in src/lib/utils.ts
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));  // Line 5 - NOT COVERED
}
```

### Suggested Fix
Add unit tests for the `cn` function:

```typescript
describe('cn', () => {
  test('merges class names correctly', () => {
    expect(cn('class1', 'class2')).toBe('class1 class2');
  });

  test('handles conditional classes', () => {
    expect(cn('base', false && 'hidden', true && 'visible')).toBe('base visible');
  });

  test('merges tailwind classes correctly', () => {
    expect(cn('p-4', 'p-2')).toBe('p-2'); // tailwind-merge should use last value
  });
});
```

---

## Bug Severity Classification

| Severity | Description | Response Time |
|----------|-------------|---------------|
| Critical | System crash, data loss, security breach | Immediate |
| High | Major feature broken, no workaround | 24 hours |
| Medium | Feature partially broken, workaround exists | 1 week |
| Low | Minor issue, cosmetic, enhancement | Next sprint |

---

## Bug Priority Classification

| Priority | Description | SLA |
|----------|-------------|-----|
| Critical | Production down, affects all users | 4 hours |
| High | Affects many users, business impact | 1 day |
| Medium | Affects some users, moderate impact | 1 week |
| Low | Affects few users, minimal impact | 2 weeks |

---

## Bug Lifecycle

```
┌─────────┐     ┌─────────────┐     ┌──────────┐     ┌────────┐
│   New   │ --> │ In Progress │ --> │ Resolved │ --> │ Closed │
└─────────┘     └─────────────┘     └──────────┘     └────────┘
     │                                    │
     │          ┌─────────────┐           │
     └--------> │  Deferred   │ <---------┘
                └─────────────┘
```

---

## Jira Bug Template

```yaml
Project: DENT
Issue Type: Bug
Summary: [Brief description]
Description: |
  ## Description
  [Detailed description of the bug]
  
  ## Steps to Reproduce
  1. Step 1
  2. Step 2
  3. Step 3
  
  ## Expected Result
  [What should happen]
  
  ## Actual Result
  [What actually happens]
  
  ## Environment
  - OS: [Operating System]
  - Browser: [Browser Name and Version]
  - Version: [Application Version]

Priority: [Critical/High/Medium/Low]
Severity: [Critical/High/Medium/Low]
Labels: [bug, testing, etc.]
Attachments: [Screenshots, logs, etc.]
```

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Bugs Found | 2 |
| Critical Bugs | 0 |
| High Severity | 0 |
| Medium Severity | 1 |
| Low Severity | 1 |
| Bugs Fixed | 0 |
| Bugs Open | 2 |
