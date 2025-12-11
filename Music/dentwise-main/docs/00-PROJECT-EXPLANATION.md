# شرح شامل لمشروع اختبار البرمجيات
# Software Testing Project - Complete Walkthrough

---

## 📋 ملخص المشروع

تم إنشاء مشروع اختبار برمجيات كامل يطبق جميع تقنيات الاختبار المطلوبة على كود Java يسمى `WhiteBoxSample.java`.

---

## 1. 📄 Requirements Analysis (تحليل المتطلبات)

### ماذا فعلنا؟
حللنا التطبيق واستخرجنا المتطلبات الوظيفية وغير الوظيفية.

### الملف: `docs/1-requirements-analysis.md`

### المتطلبات الوظيفية (7 متطلبات):

| # | المتطلب | الوصف |
|---|---------|-------|
| FR-01 | Account Creation | إنشاء حسابات بـ ID و رصيد ونوع |
| FR-02 | Deposit | إيداع أموال مع التحقق |
| FR-03 | Withdraw | سحب أموال مع فحص الرصيد |
| FR-04 | Transfer | تحويل أموال بين حسابين مع رسوم |
| FR-05 | Fee Calculation | حساب الرسوم حسب نوع العميل |
| FR-06 | Password Validation | التحقق من قوة كلمة المرور |
| FR-07 | Discount Calculation | حساب الخصومات حسب الولاء |

### المتطلبات غير الوظيفية (3):
- **Performance**: العمليات < 10ms
- **Security**: تشفير كلمات المرور
- **Reliability**: لا فقدان بيانات عند الأخطاء

---

## 2. 🔲 Black Box Testing (اختبار الصندوق الأسود)

### ماذا فعلنا؟
طبقنا تقنيتين:
1. **Equivalence Partitioning (EP)** - تقسيم المدخلات لمجموعات متكافئة
2. **Boundary Value Analysis (BVA)** - اختبار القيم الحدية

### الملف: `docs/2-black-box-testing.md`

### مثال على دالة `calculateFee`:

**Equivalence Partitions:**
```
EP1: amount <= 0        → العائد 0
EP2: VIP + amount > 1000   → 0.5%
EP3: VIP + amount <= 1000  → 1%
EP4: PREMIUM             → 1.5%
EP5: REGULAR + amount >= 50 → 2%
EP6: REGULAR + amount < 50  → 1.0 ثابت
```

**Boundary Values:**
```
BVA1: amount = 0 (حد)
BVA2: amount = 1000 (حد VIP)
BVA3: amount = 1001 (فوق حد VIP)
BVA4: amount = 49 (تحت حد REGULAR)
BVA5: amount = 50 (حد REGULAR)
```

### حالات الاختبار (10):

| TC | Input | Expected | Technique |
|----|-------|----------|-----------|
| TC-01 | VIP, 2000 | 10.0 | EP |
| TC-02 | VIP, 500 | 5.0 | EP |
| TC-03 | VIP, 1000 | 10.0 | BVA |
| TC-04 | PREMIUM, 1000 | 15.0 | EP |
| TC-05 | REGULAR, 100 | 2.0 | EP |
| ... | ... | ... | ... |

---

## 3. ⬜ White Box Testing (اختبار الصندوق الأبيض)

### ماذا فعلنا؟
حللنا البنية الداخلية للكود باستخدام:

### الملف: `docs/3-white-box-testing.md`

### الدالة المختارة: `calculateFee`

```java
public double calculateFee(CustomerType type, double amount) {
    if (amount <= 0) return 0.0;           // القرار 1
    switch (type) {                        // القرار 2
        case VIP:
            if (amount > 1000)              // القرار 3
                return amount * 0.005;
            return amount * 0.01;
        case PREMIUM:
            return amount * 0.015;
        case REGULAR:
        default:
            if (amount < 50)                // القرار 4
                return 1.0;
            return amount * 0.02;
    }
}
```

### أ. Control Flow Graph (رسم التدفق):

```
       START
          │
          ▼
    ┌──────────┐
    │amount<=0?│──YES──► return 0
    └────┬─────┘
         │ NO
         ▼
    ┌──────────┐
    │  switch  │
    │   type   │
    └────┬─────┘
    ┌────┼────┬────┐
    VIP  │ PREM  REG
    │    │    │    │
    ▼    │    ▼    ▼
 >1000?  │  1.5%  <50?
  │  │   │        │  │
 YES NO  │       YES NO
  │  │   │        │  │
0.5% 1%  │       1.0 2%
    └────┴────────┴───► END
```

### ب. Cyclomatic Complexity (التعقيد الدوري):

**الصيغة:** `V(G) = E - N + 2P`

- E (الحواف) = 14
- N (العقد) = 10
- P (المكونات) = 1

```
V(G) = 14 - 10 + 2(1) = 6
```

**التعقيد الدوري = 6** (يعني نحتاج 6 مسارات مستقلة)

### ج. Independent Paths (المسارات المستقلة):

| المسار | الشرط | Input | Output |
|--------|-------|-------|--------|
| Path 1 | amount <= 0 | (VIP, 0) | 0.0 |
| Path 2 | VIP, amount > 1000 | (VIP, 2000) | 10.0 |
| Path 3 | VIP, amount <= 1000 | (VIP, 500) | 5.0 |
| Path 4 | PREMIUM | (PREMIUM, 1000) | 15.0 |
| Path 5 | REGULAR, amount < 50 | (REGULAR, 30) | 1.0 |
| Path 6 | REGULAR, amount >= 50 | (REGULAR, 100) | 2.0 |

---

## 4. 🧪 Unit Testing with JUnit 5

### ماذا فعلنا؟
كتبنا 50 اختبار وحدة يغطي جميع الحالات.

### الملفات:
- `java-testing/src/main/java/vv/sample/WhiteBoxSample.java`
- `java-testing/src/test/java/vv/sample/WhiteBoxSampleTest.java`

### توزيع الاختبارات:

| الفئة | عدد الاختبارات | الوصف |
|-------|----------------|-------|
| AccountTests | 11 | إنشاء، إيداع، سحب، تجميد |
| TransactionProcessorTests | 9 | تحويل، أخطاء |
| CalculateFeeTests | 8 | حساب الرسوم |
| PasswordStrengthTests | 7 | قوة كلمة المرور |
| SanitizeTests | 5 | تنظيف المدخلات |
| DiscountCalculatorTests | 10 | حساب الخصومات |
| **المجموع** | **50** | |

### أنواع حالات الاختبار:

1. **Normal Cases** (عادية): المدخلات الصحيحة المتوقعة
2. **Edge Cases** (حدية): القيم الطرفية
3. **Boundary Cases** (حدودية): على حدود التقسيمات
4. **Exception Cases** (استثنائية): المدخلات الخاطئة

### مثال على اختبار:

```java
@Test
@DisplayName("TC-FEE-01: VIP fee for amount > 1000 is 0.5%")
void testVipFeeHighAmount() {
    double fee = processor.calculateFee(CustomerType.VIP, 2000.0);
    assertEquals(10.0, fee, 0.01); // 2000 * 0.005 = 10
}
```

### نتائج التشغيل:

```
Tests run: 50, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

### تغطية الكود (Code Coverage):

| الفئة | Instructions | Branches | Lines |
|-------|--------------|----------|-------|
| Account | 91% | 87% | 100% |
| TransactionProcessor | 91% | 100% | 87% |
| SecurityUtils | 97% | 100% | 94% |
| DiscountCalculator | 96% | 88% | 100% |

---

## 5. 🏃 Agile Testing

### ماذا فعلنا؟
وثقنا العملية بمنهجية Scrum.

### الملف: `docs/5-agile-testing.md`

### Sprint Backlog:

| User Story | Story Points | Status |
|------------|--------------|--------|
| US-01: Requirements Analysis | 5 | ✅ Done |
| US-02: Black-Box Testing | 8 | ✅ Done |
| US-03: White-Box Testing | 8 | ✅ Done |
| US-04: Unit Testing | 5 | ✅ Done |
| US-05: Documentation | 3 | ✅ Done |
| US-06: Bug Reporting | 3 | ✅ Done |
| **Total** | **32** | **100%** |

### Sprint Board:

```
┌──────────┬─────────────┬──────────┬─────────┐
│  TO DO   │ IN PROGRESS │ TESTING  │  DONE   │
├──────────┼─────────────┼──────────┼─────────┤
│          │             │          │ US-01 ✅│
│          │             │          │ US-02 ✅│
│          │             │          │ US-03 ✅│
│          │             │          │ US-04 ✅│
│          │             │          │ US-05 ✅│
│          │             │          │ US-06 ✅│
└──────────┴─────────────┴──────────┴─────────┘
```

---

## 6. 🐛 Bug Reports

### ماذا فعلنا؟
وثقنا الأخطاء المكتشفة.

### الملف: `docs/6-bug-reports.md`

### Bug #1: Phone Truncation
```
ID:          BUG-001
Severity:    Medium
Priority:    Medium
Description: أرقام الهاتف > 11 رقم يتم قطعها بدون تحذير
```

### Bug #2: Missing Coverage
```
ID:          BUG-002
Severity:    Low
Priority:    Low
Description: دالة cn غير مغطاة بالاختبارات
```

---

## 7. 📁 الملفات المنشأة

### هيكل المشروع:

```
dentwise-main/
├── docs/
│   ├── 1-requirements-analysis.md   ← تحليل المتطلبات
│   ├── 2-black-box-testing.md       ← اختبار الصندوق الأسود
│   ├── 3-white-box-testing.md       ← اختبار الصندوق الأبيض
│   ├── 4-unit-testing.md            ← توثيق اختبارات الوحدة
│   ├── 5-agile-testing.md           ← توثيق Agile
│   ├── 6-bug-reports.md             ← تقارير الأخطاء
│   ├── 7-final-report.md            ← التقرير النهائي
│   ├── Final-Report.pdf             ← PDF
│   ├── White-Box-Testing.pdf        ← PDF
│   ├── Unit-Testing.pdf             ← PDF
│   ├── Black-Box-Testing.pdf        ← PDF
│   ├── Agile-Testing.pdf            ← PDF
│   ├── Bug-Reports.pdf              ← PDF
│   └── *.txt                        ← نسخ نصية
│
└── java-testing/
    ├── pom.xml                      ← Maven configuration
    ├── src/main/java/vv/sample/
    │   └── WhiteBoxSample.java      ← الكود الأصلي
    └── src/test/java/vv/sample/
        └── WhiteBoxSampleTest.java  ← 50 اختبار JUnit
```

---

## 8. 🔧 الأوامر المستخدمة

### تشغيل الاختبارات:
```bash
cd java-testing
mvn test
```

### تقرير التغطية:
```bash
mvn test jacoco:report
# ثم افتح: target/site/jacoco/index.html
```

### تحويل Markdown إلى PDF:
```bash
pandoc file.md -o file.pdf --pdf-engine=xelatex
```

### تحويل PDF إلى TXT:
```bash
pdftotext file.pdf file.txt
```

---

## 9. 📊 ملخص النتائج النهائية

| المقياس | القيمة |
|---------|--------|
| متطلبات وظيفية | 7 |
| متطلبات غير وظيفية | 3 |
| حالات اختبار Black Box | 10 |
| Cyclomatic Complexity | 6 |
| Independent Paths | 6 |
| Unit Tests | 50 |
| Tests Passed | 50 (100%) |
| Code Coverage | 90%+ |
| Bugs Found | 2 |
| PDFs Created | 6 |

---

## 10. 👥 فريق العمل

| الاسم | الدور |
|-------|-------|
| محمد أحمد محمد | Team Lead |
| علي سيد | QA Engineer |
| حبيبه كرم | QA Engineer |

---

## ✅ الخلاصة

تم إنجاز مشروع اختبار برمجيات شامل يغطي:
- ✅ تحليل المتطلبات
- ✅ اختبار الصندوق الأسود (EP + BVA)
- ✅ اختبار الصندوق الأبيض (CFG + CC + Paths)
- ✅ اختبارات الوحدة (50 اختبار JUnit)
- ✅ منهجية Agile
- ✅ تقارير الأخطاء
- ✅ ملفات PDF للتسليم

**المشروع جاهز للتسليم! 🎉**
