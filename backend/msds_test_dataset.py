"""
Test Dataset for MSDS Evaluation
Contains labeled test cases for mobile DLP evaluation
"""

from msds_evaluator import TestCase

# Test dataset with labeled examples
TEST_DATASET = [
    # ============== PASSWORD TESTS ==============
    # SMS - Casual
    TestCase(
        message="my pwd is Secret123",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="password: admin123!",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="ur pass is qwerty",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="sms",
        context="casual"
    ),
    
    # Email - Formal
    TestCase(
        message="Your temporary password is TempPass@2024. Please change it after login.",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="email",
        context="formal"
    ),
    
    # Telegram
    TestCase(
        message="wifi password is HomeNetwork99",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="telegram",
        context="casual"
    ),
    
    # ============== CREDIT CARD TESTS ==============
    TestCase(
        message="My card number is 4532-1234-5678-9012",
        expected_sensitive=True,
        expected_categories=["credit_card"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Use this card: 4532015112830366 exp 12/25 cvv 123",
        expected_sensitive=True,
        expected_categories=["credit_card"],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="Card ending in 9012 was charged $50",
        expected_sensitive=False,  # Partial card is not sensitive
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    
    # ============== BANK ACCOUNT TESTS ==============
    TestCase(
        message="my bank acc is 1234567890",
        expected_sensitive=True,
        expected_categories=["bank_account"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Transfer to account: 9876543210123456",
        expected_sensitive=True,
        expected_categories=["bank_account"],
        platform="email",
        context="formal"
    ),
    
    # ============== PHONE NUMBER TESTS ==============
    TestCase(
        message="Call me on 0771234567",
        expected_sensitive=True,
        expected_categories=["phone"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="My number is +94 77 123 4567",
        expected_sensitive=True,
        expected_categories=["phone"],
        platform="telegram",
        context="casual"
    ),
    
    # ============== NIC/SSN TESTS ==============
    TestCase(
        message="My NIC is 199912345678",
        expected_sensitive=True,
        expected_categories=["nic"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="SSN: 123-45-6789",
        expected_sensitive=True,
        expected_categories=["ssn"],
        platform="email",
        context="formal"
    ),
    
    # ============== EMAIL TESTS ==============
    TestCase(
        message="Send it to john.doe@company.com",
        expected_sensitive=True,
        expected_categories=["email"],
        platform="sms",
        context="casual"
    ),
    
    # ============== SAFE MESSAGES (Should NOT trigger) ==============
    TestCase(
        message="Hey, what's up?",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Meeting at 5pm tomorrow",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="The password to success is hard work",
        expected_sensitive=False,  # Metaphorical use
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Call me when you're free",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Your order number is 123456",
        expected_sensitive=False,  # Order number, not sensitive
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    
    # ============== EDGE CASES ==============
    TestCase(
        message="PIN is 1234",
        expected_sensitive=True,
        expected_categories=["password", "pin"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Room 1234 at the hotel",
        expected_sensitive=False,  # Room number, not PIN
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="OTP is 456789",
        expected_sensitive=True,
        expected_categories=["otp", "password"],
        platform="sms",
        context="urgent"
    ),
    
    # ============== MIXED CONTENT ==============
    TestCase(
        message="Login with user admin@test.com and password Test@123",
        expected_sensitive=True,
        expected_categories=["email", "password"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Card 4532111122223333 password xyz789",
        expected_sensitive=True,
        expected_categories=["credit_card", "password"],
        platform="telegram",
        context="casual"
    ),
]


def get_test_dataset():
    """Return the test dataset"""
    return TEST_DATASET


def get_platform_distribution():
    """Get distribution of platforms in test dataset"""
    distribution = {'sms': 0, 'telegram': 0, 'email': 0}
    for test in TEST_DATASET:
        if test.platform in distribution:
            distribution[test.platform] += 1
    return distribution


def print_dataset_summary():
    """Print summary of the test dataset"""
    total = len(TEST_DATASET)
    sensitive = sum(1 for t in TEST_DATASET if t.expected_sensitive)
    safe = total - sensitive
    
    print(f"\n{'='*50}")
    print(f"MSDS Test Dataset Summary")
    print(f"{'='*50}")
    print(f"Total test cases: {total}")
    print(f"Sensitive messages: {sensitive}")
    print(f"Safe messages: {safe}")
    print(f"\nPlatform distribution:")
    for platform, count in get_platform_distribution().items():
        print(f"  - {platform}: {count}")
    print(f"{'='*50}\n")


if __name__ == "__main__":
    print_dataset_summary()