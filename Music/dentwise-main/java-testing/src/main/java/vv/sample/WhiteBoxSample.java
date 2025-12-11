package vv.sample;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class WhiteBoxSample {

    
    public enum CustomerType { REGULAR, PREMIUM, VIP }

    // Account model
    public static class Account {
        private final String id;
        private double balance;
        private final CustomerType type;
        private boolean frozen = false;

        public Account(String id, double initialBalance, CustomerType type) {
            if (id == null || id.isBlank()) throw new IllegalArgumentException("Account id required");
            if (initialBalance < 0) throw new IllegalArgumentException("Negative initial balance");
            this.id = id;
            this.balance = initialBalance;
            this.type = Objects.requireNonNull(type);
        }

        public String getId() { return id; }
        public double getBalance() { return balance; }
        public CustomerType getType() { return type; }
        public boolean isFrozen() { return frozen; }

        public void freeze() { frozen = true; }
        public void unfreeze() { frozen = false; }

        public void deposit(double amount) {
            if (amount <= 0) throw new IllegalArgumentException("Deposit amount must be positive");
            if (frozen) throw new IllegalStateException("Account is frozen");
            balance += amount;
        }

        public void withdraw(double amount) {
            if (amount <= 0) throw new IllegalArgumentException("Withdraw amount must be positive");
            if (frozen) throw new IllegalStateException("Account is frozen");
            if (amount > balance) throw new IllegalArgumentException("Insufficient funds");
            balance -= amount;
        }
    }


    // Transaction processor 
    public static class TransactionProcessor {
        private final List<String> log = new ArrayList<>();

        public String transfer(Account from, Account to, double amount) {
            // Basic validations
            if (from == null || to == null) return "ERROR: account null";
            if (from.isFrozen() || to.isFrozen()) return "ERROR: account frozen";
            if (amount <= 0) return "ERROR: invalid amount";

            // Fee rules based on customer type
            double fee = calculateFee(from.getType(), amount);
            double total = amount + fee;

            try {
                if (total > from.getBalance()) return "ERROR: insufficient funds after fee";
                from.withdraw(total);
                to.deposit(amount);
                String record = String.format("TRANSFER OK: %s -> %s : %.2f (fee=%.2f)", from.getId(), to.getId(), amount, fee);
                log.add(record);
                return record;
            } catch (IllegalArgumentException | IllegalStateException e) {
                log.add("TRANSFER FAIL: " + e.getMessage());
                return "ERROR: " + e.getMessage();
            }
        }

        public double calculateFee(CustomerType type, double amount) {
            if (amount <= 0) return 0.0;
            switch (type) {
                case VIP:
                    if (amount > 1000) return amount * 0.005; // 0.5%
                    return amount * 0.01; // 1%
                case PREMIUM:
                    return amount * 0.015; // 1.5%
                case REGULAR:
                default:
                    if (amount < 50) return 1.0; // small fixed fee
                    return amount * 0.02; // 2%
            }
        }

        public List<String> getLog() { return List.copyOf(log); }
    }


    // Password strength and validation
    public static class SecurityUtils {

        public static boolean isPasswordStrong(String password) {
            if (password == null) return false;
            int len = password.length();
            if (len < 8) return false;
            boolean hasUpper = false, hasLower = false, hasDigit = false, hasSpecial = false;
            for (char c : password.toCharArray()) {
                if (Character.isUpperCase(c)) hasUpper = true;
                else if (Character.isLowerCase(c)) hasLower = true;
                else if (Character.isDigit(c)) hasDigit = true;
                else hasSpecial = true;
            }
            
            int score = 0;
            if (hasUpper) score++;
            if (hasLower) score++;
            if (hasDigit) score++;
            if (hasSpecial) score++;
            return score >= 3;
        }

        public static String sanitize(String input) {
            if (input == null) return null;
            // simplistic sanitizer for demo purposes
            return input.replaceAll("<", "&lt;").replaceAll(">", "&gt;").trim();
        }
    }


    // Discount calculator
    public static class DiscountCalculator {

        public double calculateDiscount(double price, CustomerType type, int purchaseCountLastYear) {
            if (price < 0) throw new IllegalArgumentException("Price cannot be negative");
            double discount = 0.0;

            // base discounts
            if (type == CustomerType.VIP) discount += 0.10;
            else if (type == CustomerType.PREMIUM) discount += 0.05;

            // loyalty bonus
            if (purchaseCountLastYear > 20) discount += 0.03;
            else if (purchaseCountLastYear > 10) discount += 0.01;

            // seasonal special
            if (price > 1000) {
                for (int i = 0; i < 3; i++) {
                    if (i == 2 && type == CustomerType.VIP) {
                        discount += 0.02;
                    } else if (i == 1) {
                        discount += 0.005;
                    }
                }
            } else {
                if (price > 500) discount += 0.01;
            }

            // cap discount between 0 and 0.25
            if (discount < 0) discount = 0;
            if (discount > 0.25) discount = 0.25;

            return Math.round(discount * 10000.0) / 10000.0; // 4 decimal rounding
        }
    }


    public static void main(String[] args) {
        Account a1 = new Account("A100", 2000.0, CustomerType.VIP);
        Account a2 = new Account("B200", 1500.0, CustomerType.REGULAR);

        TransactionProcessor tp = new TransactionProcessor();
        String result = tp.transfer(a1, a2, 1200.0);
        System.out.println(result);
        System.out.println("Fee calculated: " + tp.calculateFee(a1.getType(), 1200.0));

        System.out.println("Password strong? " + SecurityUtils.isPasswordStrong("Abc$1234"));
        DiscountCalculator dc = new DiscountCalculator();
        System.out.println("Discount: " + dc.calculateDiscount(1200.0, CustomerType.VIP, 25));
    }
}
