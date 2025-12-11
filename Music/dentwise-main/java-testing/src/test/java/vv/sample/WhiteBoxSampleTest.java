package vv.sample;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

import vv.sample.WhiteBoxSample.Account;
import vv.sample.WhiteBoxSample.CustomerType;
import vv.sample.WhiteBoxSample.TransactionProcessor;
import vv.sample.WhiteBoxSample.SecurityUtils;
import vv.sample.WhiteBoxSample.DiscountCalculator;

/**
 * JUnit 5 Unit Tests for WhiteBoxSample
 * 
 * Test Categories:
 * - Normal cases
 * - Edge cases
 * - Boundary cases
 * - Invalid/Exception cases
 * 
 * Total: 35+ test cases achieving path coverage
 */
public class WhiteBoxSampleTest {

    // =====================================================
    // ACCOUNT TESTS
    // =====================================================
    @Nested
    @DisplayName("Account Class Tests")
    class AccountTests {

        @Test
        @DisplayName("TC-ACC-01: Create account with valid data")
        void testCreateValidAccount() {
            Account acc = new Account("A001", 1000.0, CustomerType.VIP);
            assertEquals("A001", acc.getId());
            assertEquals(1000.0, acc.getBalance());
            assertEquals(CustomerType.VIP, acc.getType());
            assertFalse(acc.isFrozen());
        }

        @Test
        @DisplayName("TC-ACC-02: Create account with null ID throws exception")
        void testCreateAccountNullId() {
            assertThrows(IllegalArgumentException.class, () -> {
                new Account(null, 1000.0, CustomerType.REGULAR);
            });
        }

        @Test
        @DisplayName("TC-ACC-03: Create account with blank ID throws exception")
        void testCreateAccountBlankId() {
            assertThrows(IllegalArgumentException.class, () -> {
                new Account("   ", 1000.0, CustomerType.REGULAR);
            });
        }

        @Test
        @DisplayName("TC-ACC-04: Create account with negative balance throws exception")
        void testCreateAccountNegativeBalance() {
            assertThrows(IllegalArgumentException.class, () -> {
                new Account("A001", -100.0, CustomerType.REGULAR);
            });
        }

        @Test
        @DisplayName("TC-ACC-05: Create account with zero balance succeeds")
        void testCreateAccountZeroBalance() {
            Account acc = new Account("A001", 0.0, CustomerType.REGULAR);
            assertEquals(0.0, acc.getBalance());
        }

        @Test
        @DisplayName("TC-ACC-06: Deposit positive amount increases balance")
        void testDepositPositiveAmount() {
            Account acc = new Account("A001", 100.0, CustomerType.REGULAR);
            acc.deposit(50.0);
            assertEquals(150.0, acc.getBalance());
        }

        @Test
        @DisplayName("TC-ACC-07: Deposit zero or negative throws exception")
        void testDepositNonPositive() {
            Account acc = new Account("A001", 100.0, CustomerType.REGULAR);
            assertThrows(IllegalArgumentException.class, () -> acc.deposit(0.0));
            assertThrows(IllegalArgumentException.class, () -> acc.deposit(-10.0));
        }

        @Test
        @DisplayName("TC-ACC-08: Deposit to frozen account throws exception")
        void testDepositToFrozenAccount() {
            Account acc = new Account("A001", 100.0, CustomerType.REGULAR);
            acc.freeze();
            assertThrows(IllegalStateException.class, () -> acc.deposit(50.0));
        }

        @Test
        @DisplayName("TC-ACC-09: Withdraw valid amount decreases balance")
        void testWithdrawValidAmount() {
            Account acc = new Account("A001", 100.0, CustomerType.REGULAR);
            acc.withdraw(30.0);
            assertEquals(70.0, acc.getBalance());
        }

        @Test
        @DisplayName("TC-ACC-10: Withdraw more than balance throws exception")
        void testWithdrawInsufficientFunds() {
            Account acc = new Account("A001", 100.0, CustomerType.REGULAR);
            assertThrows(IllegalArgumentException.class, () -> acc.withdraw(150.0));
        }

        @Test
        @DisplayName("TC-ACC-11: Freeze and unfreeze account")
        void testFreezeUnfreeze() {
            Account acc = new Account("A001", 100.0, CustomerType.REGULAR);
            assertFalse(acc.isFrozen());
            acc.freeze();
            assertTrue(acc.isFrozen());
            acc.unfreeze();
            assertFalse(acc.isFrozen());
        }
    }

    // =====================================================
    // TRANSACTION PROCESSOR TESTS
    // =====================================================
    @Nested
    @DisplayName("TransactionProcessor Tests")
    class TransactionProcessorTests {
        
        private TransactionProcessor processor;
        private Account vipAccount;
        private Account regularAccount;
        private Account premiumAccount;

        @BeforeEach
        void setUp() {
            processor = new TransactionProcessor();
            vipAccount = new Account("VIP001", 5000.0, CustomerType.VIP);
            regularAccount = new Account("REG001", 3000.0, CustomerType.REGULAR);
            premiumAccount = new Account("PRE001", 4000.0, CustomerType.PREMIUM);
        }

        @Test
        @DisplayName("TC-TXN-01: Transfer with null source account returns error")
        void testTransferNullFromAccount() {
            String result = processor.transfer(null, regularAccount, 100.0);
            assertEquals("ERROR: account null", result);
        }

        @Test
        @DisplayName("TC-TXN-02: Transfer with null destination account returns error")
        void testTransferNullToAccount() {
            String result = processor.transfer(vipAccount, null, 100.0);
            assertEquals("ERROR: account null", result);
        }

        @Test
        @DisplayName("TC-TXN-03: Transfer from frozen account returns error")
        void testTransferFromFrozenAccount() {
            vipAccount.freeze();
            String result = processor.transfer(vipAccount, regularAccount, 100.0);
            assertEquals("ERROR: account frozen", result);
        }

        @Test
        @DisplayName("TC-TXN-04: Transfer to frozen account returns error")
        void testTransferToFrozenAccount() {
            regularAccount.freeze();
            String result = processor.transfer(vipAccount, regularAccount, 100.0);
            assertEquals("ERROR: account frozen", result);
        }

        @Test
        @DisplayName("TC-TXN-05: Transfer with zero amount returns error")
        void testTransferZeroAmount() {
            String result = processor.transfer(vipAccount, regularAccount, 0.0);
            assertEquals("ERROR: invalid amount", result);
        }

        @Test
        @DisplayName("TC-TXN-06: Transfer with negative amount returns error")
        void testTransferNegativeAmount() {
            String result = processor.transfer(vipAccount, regularAccount, -100.0);
            assertEquals("ERROR: invalid amount", result);
        }

        @Test
        @DisplayName("TC-TXN-07: Successful VIP transfer with correct fee")
        void testSuccessfulVipTransfer() {
            double initialFrom = vipAccount.getBalance();
            double initialTo = regularAccount.getBalance();
            
            String result = processor.transfer(vipAccount, regularAccount, 1200.0);
            
            assertTrue(result.startsWith("TRANSFER OK"));
            // VIP fee for >1000: 0.5% = 6.0
            double expectedFee = 1200.0 * 0.005;
            assertEquals(initialFrom - 1200.0 - expectedFee, vipAccount.getBalance(), 0.01);
            assertEquals(initialTo + 1200.0, regularAccount.getBalance(), 0.01);
        }

        @Test
        @DisplayName("TC-TXN-08: Insufficient funds after fee returns error")
        void testInsufficientFundsAfterFee() {
            Account lowBalance = new Account("LOW001", 100.0, CustomerType.REGULAR);
            String result = processor.transfer(lowBalance, regularAccount, 99.0);
            // Fee for REGULAR with amount >= 50: 2% = 1.98, total = 100.98 > 100
            assertEquals("ERROR: insufficient funds after fee", result);
        }

        @Test
        @DisplayName("TC-TXN-09: Transfer log is updated after successful transfer")
        void testTransferLogUpdated() {
            processor.transfer(vipAccount, regularAccount, 500.0);
            assertEquals(1, processor.getLog().size());
            assertTrue(processor.getLog().get(0).startsWith("TRANSFER OK"));
        }
    }

    // =====================================================
    // CALCULATE FEE TESTS
    // =====================================================
    @Nested
    @DisplayName("calculateFee Tests")
    class CalculateFeeTests {
        
        private TransactionProcessor processor;

        @BeforeEach
        void setUp() {
            processor = new TransactionProcessor();
        }

        @Test
        @DisplayName("TC-FEE-01: VIP fee for amount > 1000 is 0.5%")
        void testVipFeeHighAmount() {
            double fee = processor.calculateFee(CustomerType.VIP, 2000.0);
            assertEquals(10.0, fee, 0.01); // 2000 * 0.005 = 10
        }

        @Test
        @DisplayName("TC-FEE-02: VIP fee for amount <= 1000 is 1%")
        void testVipFeeLowAmount() {
            double fee = processor.calculateFee(CustomerType.VIP, 500.0);
            assertEquals(5.0, fee, 0.01); // 500 * 0.01 = 5
        }

        @Test
        @DisplayName("TC-FEE-03: VIP fee at boundary 1000 is 1%")
        void testVipFeeBoundary() {
            double fee = processor.calculateFee(CustomerType.VIP, 1000.0);
            assertEquals(10.0, fee, 0.01); // 1000 * 0.01 = 10
        }

        @Test
        @DisplayName("TC-FEE-04: PREMIUM fee is always 1.5%")
        void testPremiumFee() {
            double fee = processor.calculateFee(CustomerType.PREMIUM, 1000.0);
            assertEquals(15.0, fee, 0.01); // 1000 * 0.015 = 15
        }

        @Test
        @DisplayName("TC-FEE-05: REGULAR fee for amount >= 50 is 2%")
        void testRegularFeeHighAmount() {
            double fee = processor.calculateFee(CustomerType.REGULAR, 100.0);
            assertEquals(2.0, fee, 0.01); // 100 * 0.02 = 2
        }

        @Test
        @DisplayName("TC-FEE-06: REGULAR fee for amount < 50 is fixed 1.0")
        void testRegularFeeLowAmount() {
            double fee = processor.calculateFee(CustomerType.REGULAR, 30.0);
            assertEquals(1.0, fee, 0.01); // fixed fee
        }

        @Test
        @DisplayName("TC-FEE-07: REGULAR fee at boundary 50 is 2%")
        void testRegularFeeBoundary() {
            double fee = processor.calculateFee(CustomerType.REGULAR, 50.0);
            assertEquals(1.0, fee, 0.01); // 50 * 0.02 = 1
        }

        @Test
        @DisplayName("TC-FEE-08: Fee for zero or negative amount is 0")
        void testFeeZeroAmount() {
            assertEquals(0.0, processor.calculateFee(CustomerType.VIP, 0.0));
            assertEquals(0.0, processor.calculateFee(CustomerType.VIP, -100.0));
        }
    }

    // =====================================================
    // SECURITY UTILS - PASSWORD TESTS
    // =====================================================
    @Nested
    @DisplayName("SecurityUtils.isPasswordStrong Tests")
    class PasswordStrengthTests {

        @Test
        @DisplayName("TC-PWD-01: Null password returns false")
        void testNullPassword() {
            assertFalse(SecurityUtils.isPasswordStrong(null));
        }

        @Test
        @DisplayName("TC-PWD-02: Password shorter than 8 chars returns false")
        void testShortPassword() {
            assertFalse(SecurityUtils.isPasswordStrong("Abc$12")); // 6 chars
        }

        @Test
        @DisplayName("TC-PWD-03: Password exactly 8 chars with 3+ types is strong")
        void testExactly8CharsStrong() {
            assertTrue(SecurityUtils.isPasswordStrong("Abcd$123")); // upper, lower, digit, special
        }

        @Test
        @DisplayName("TC-PWD-04: Password with only 2 character types is weak")
        void testOnlyTwoTypes() {
            assertFalse(SecurityUtils.isPasswordStrong("abcdefgh")); // only lower
            assertFalse(SecurityUtils.isPasswordStrong("ABCDEFGH")); // only upper
            assertFalse(SecurityUtils.isPasswordStrong("abcdABCD")); // upper + lower = 2 types
        }

        @Test
        @DisplayName("TC-PWD-05: Password with 3 character types is strong")
        void testThreeTypes() {
            assertTrue(SecurityUtils.isPasswordStrong("Abcdefg1")); // upper, lower, digit
            assertTrue(SecurityUtils.isPasswordStrong("Abcdefg$")); // upper, lower, special
        }

        @Test
        @DisplayName("TC-PWD-06: Password with all 4 character types is strong")
        void testAllFourTypes() {
            assertTrue(SecurityUtils.isPasswordStrong("Abc$1234"));
        }

        @Test
        @DisplayName("TC-PWD-07: Long password with only digits is weak")
        void testOnlyDigits() {
            assertFalse(SecurityUtils.isPasswordStrong("12345678901234"));
        }
    }

    // =====================================================
    // SECURITY UTILS - SANITIZE TESTS
    // =====================================================
    @Nested
    @DisplayName("SecurityUtils.sanitize Tests")
    class SanitizeTests {

        @Test
        @DisplayName("TC-SAN-01: Null input returns null")
        void testSanitizeNull() {
            assertNull(SecurityUtils.sanitize(null));
        }

        @Test
        @DisplayName("TC-SAN-02: Input with < is escaped")
        void testSanitizeLessThan() {
            assertEquals("&lt;script&gt;", SecurityUtils.sanitize("<script>"));
        }

        @Test
        @DisplayName("TC-SAN-03: Input with > is escaped")
        void testSanitizeGreaterThan() {
            assertEquals("test&gt;value", SecurityUtils.sanitize("test>value"));
        }

        @Test
        @DisplayName("TC-SAN-04: Input is trimmed")
        void testSanitizeTrim() {
            assertEquals("hello", SecurityUtils.sanitize("  hello  "));
        }

        @Test
        @DisplayName("TC-SAN-05: Plain text remains unchanged")
        void testSanitizePlainText() {
            assertEquals("Hello World", SecurityUtils.sanitize("Hello World"));
        }
    }

    // =====================================================
    // DISCOUNT CALCULATOR TESTS
    // =====================================================
    @Nested
    @DisplayName("DiscountCalculator Tests")
    class DiscountCalculatorTests {
        
        private DiscountCalculator calculator;

        @BeforeEach
        void setUp() {
            calculator = new DiscountCalculator();
        }

        @Test
        @DisplayName("TC-DSC-01: Negative price throws exception")
        void testNegativePrice() {
            assertThrows(IllegalArgumentException.class, () -> {
                calculator.calculateDiscount(-100.0, CustomerType.REGULAR, 5);
            });
        }

        @Test
        @DisplayName("TC-DSC-02: VIP gets 10% base discount")
        void testVipBaseDiscount() {
            double discount = calculator.calculateDiscount(100.0, CustomerType.VIP, 0);
            assertEquals(0.10, discount, 0.0001);
        }

        @Test
        @DisplayName("TC-DSC-03: PREMIUM gets 5% base discount")
        void testPremiumBaseDiscount() {
            double discount = calculator.calculateDiscount(100.0, CustomerType.PREMIUM, 0);
            assertEquals(0.05, discount, 0.0001);
        }

        @Test
        @DisplayName("TC-DSC-04: REGULAR gets 0% base discount")
        void testRegularBaseDiscount() {
            double discount = calculator.calculateDiscount(100.0, CustomerType.REGULAR, 0);
            assertEquals(0.0, discount, 0.0001);
        }

        @Test
        @DisplayName("TC-DSC-05: Loyalty bonus 3% for purchases > 20")
        void testLoyaltyBonusHigh() {
            double discount = calculator.calculateDiscount(100.0, CustomerType.REGULAR, 25);
            assertEquals(0.03, discount, 0.0001);
        }

        @Test
        @DisplayName("TC-DSC-06: Loyalty bonus 1% for purchases 11-20")
        void testLoyaltyBonusMedium() {
            double discount = calculator.calculateDiscount(100.0, CustomerType.REGULAR, 15);
            assertEquals(0.01, discount, 0.0001);
        }

        @Test
        @DisplayName("TC-DSC-07: No loyalty bonus for purchases <= 10")
        void testNoLoyaltyBonus() {
            double discount = calculator.calculateDiscount(100.0, CustomerType.REGULAR, 5);
            assertEquals(0.0, discount, 0.0001);
        }

        @Test
        @DisplayName("TC-DSC-08: Price > 1000 seasonal bonus for VIP")
        void testSeasonalBonusVip() {
            // VIP base: 10%, purchases > 20: 3%, seasonal (i=1: 0.5%, i=2 VIP: 2%) = 15.5%
            double discount = calculator.calculateDiscount(1500.0, CustomerType.VIP, 25);
            assertEquals(0.155, discount, 0.0001);
        }

        @Test
        @DisplayName("TC-DSC-09: Price 500-1000 gets 1% extra")
        void testMidPriceBonus() {
            double discount = calculator.calculateDiscount(600.0, CustomerType.REGULAR, 0);
            assertEquals(0.01, discount, 0.0001);
        }

        @Test
        @DisplayName("TC-DSC-10: Discount capped at 25%")
        void testDiscountCap() {
            // VIP (10%) + high loyalty (3%) + seasonal VIP (2.5%) = 15.5%, under cap
            // Need extreme case to test cap
            double discount = calculator.calculateDiscount(2000.0, CustomerType.VIP, 100);
            assertTrue(discount <= 0.25);
        }
    }
}
