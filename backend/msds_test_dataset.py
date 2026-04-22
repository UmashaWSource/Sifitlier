"""
Test Dataset for MSDS Evaluation
Contains labeled test cases for mobile DLP evaluation

Expanded dataset with 100+ cases covering:
- All sensitive data categories the detector supports
- Sri Lankan context (NIC, local phone numbers, Dialog/Mobitel style messages)
- Cross-platform cases (SMS, Email, Telegram)
- Edge cases and common false positive scenarios
"""

from msds_evaluator import TestCase

# Test dataset with labeled examples
TEST_DATASET = [

    # ==================================================================
    # PASSWORD TESTS
    # ==================================================================

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
    TestCase(
        message="my pass is dragon99",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="password= Test@2024",
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
    TestCase(
        message="Dear user, your new password: Xy7!mN2k. Do not share this with anyone.",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="passwd: sysadmin2024! for the server access",
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
    TestCase(
        message="the router pwd is admin1234",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="password is MySecret123",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="telegram",
        context="casual"
    ),

    # ==================================================================
    # CREDIT CARD TESTS
    # ==================================================================

    # Valid Luhn numbers
    TestCase(
        message="My card number is 4532015112830366",
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
        message="Visa ending 4539578763621486 charged for your order",
        expected_sensitive=True,
        expected_categories=["credit_card"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="MasterCard: 5425233430109903",
        expected_sensitive=True,
        expected_categories=["credit_card"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Please use card 4916338506082832 for the payment",
        expected_sensitive=True,
        expected_categories=["credit_card"],
        platform="email",
        context="formal"
    ),

    # Partial card - should NOT trigger
    TestCase(
        message="Card ending in 9012 was charged $50",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),

    # ==================================================================
    # BANK ACCOUNT TESTS
    # ==================================================================

    TestCase(
        message="Transfer to account: 9876543210123456",
        expected_sensitive=True,
        expected_categories=["bank_account"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Account number: 12345678901234",
        expected_sensitive=True,
        expected_categories=["bank_account"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="IBAN: GB82WEST12345698765432",
        expected_sensitive=True,
        expected_categories=["bank_account"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Send to acct 98765432101234",
        expected_sensitive=True,
        expected_categories=["bank_account"],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="My bank acc number is 0012345678901",
        expected_sensitive=True,
        expected_categories=["bank_account"],
        platform="sms",
        context="casual"
    ),

    # ==================================================================
    # PHONE NUMBER TESTS
    # ==================================================================

    # Sri Lankan numbers
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
    TestCase(
        message="Contact us at 0712345678",
        expected_sensitive=True,
        expected_categories=["phone"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Whatsapp me at +94771234567",
        expected_sensitive=True,
        expected_categories=["phone"],
        platform="telegram",
        context="casual"
    ),

    # US numbers
    TestCase(
        message="Call (555) 123-4567 for details",
        expected_sensitive=True,
        expected_categories=["phone"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="My cell is 555-867-5309",
        expected_sensitive=True,
        expected_categories=["phone"],
        platform="sms",
        context="casual"
    ),

    # International
    TestCase(
        message="Reach me at +44 20 7946 0958",
        expected_sensitive=True,
        expected_categories=["phone"],
        platform="email",
        context="formal"
    ),

    # ==================================================================
    # NIC / SSN TESTS
    # ==================================================================

    # Sri Lankan NIC - old format
    TestCase(
        message="My NIC is 901234567V",
        expected_sensitive=True,
        expected_categories=["nic"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="NIC: 876543210X",
        expected_sensitive=True,
        expected_categories=["nic"],
        platform="email",
        context="formal"
    ),

    # Sri Lankan NIC - new format (12 digits)
    TestCase(
        message="My NIC is 199912345678",
        expected_sensitive=True,
        expected_categories=["nic"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="National ID: 200012345678",
        expected_sensitive=True,
        expected_categories=["nic"],
        platform="email",
        context="formal"
    ),

    # US SSN
    TestCase(
        message="SSN: 123-45-6789",
        expected_sensitive=True,
        expected_categories=["ssn"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="My social security is 987-65-4321",
        expected_sensitive=True,
        expected_categories=["ssn"],
        platform="sms",
        context="casual"
    ),

    # Singapore NRIC
    TestCase(
        message="My NRIC is S1234567D",
        expected_sensitive=True,
        expected_categories=["nric"],
        platform="sms",
        context="casual"
    ),

    # ==================================================================
    # EMAIL TESTS
    # ==================================================================

    TestCase(
        message="Send it to john.doe@company.com",
        expected_sensitive=True,
        expected_categories=["email"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Contact support at help@sifitlier.com for assistance",
        expected_sensitive=True,
        expected_categories=["email"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Login with user admin@test.com and password Test@123",
        expected_sensitive=True,
        expected_categories=["email", "password"],
        platform="email",
        context="formal"
    ),

    # ==================================================================
    # OTP / VERIFICATION CODE TESTS
    # ==================================================================

    TestCase(
        message="PIN is 1234",
        expected_sensitive=True,
        expected_categories=["pin"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="OTP is 456789",
        expected_sensitive=True,
        expected_categories=["otp"],
        platform="sms",
        context="urgent"
    ),
    TestCase(
        message="Your verification code is 847291",
        expected_sensitive=True,
        expected_categories=["otp"],
        platform="sms",
        context="urgent"
    ),
    TestCase(
        message="Your one-time password is 123456. Do not share.",
        expected_sensitive=True,
        expected_categories=["otp"],
        platform="sms",
        context="urgent"
    ),
    TestCase(
        message="PIN: 5678",
        expected_sensitive=True,
        expected_categories=["pin"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Your OTP: 982134",
        expected_sensitive=True,
        expected_categories=["otp"],
        platform="sms",
        context="urgent"
    ),

    # ==================================================================
    # CVV TESTS
    # ==================================================================

    TestCase(
        message="CVV is 321",
        expected_sensitive=True,
        expected_categories=["cvv"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Security code: 4567",
        expected_sensitive=True,
        expected_categories=["cvv"],
        platform="telegram",
        context="casual"
    ),

    # ==================================================================
    # API KEY / TOKEN TESTS
    # ==================================================================

    TestCase(
        message="API key: sk-1234567890abcdefghijklmnop",
        expected_sensitive=True,
        expected_categories=["api_key"],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="Use secret_key= abcdefghijklmnopqrstuvwx for auth",
        expected_sensitive=True,
        expected_categories=["api_key"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Bearer eyJhbGciOiJIUzI1NiIsInR5c",
        expected_sensitive=True,
        expected_categories=["api_key"],
        platform="telegram",
        context="casual"
    ),

    # ==================================================================
    # DOB / ADDRESS / MEDICAL TESTS
    # ==================================================================

    TestCase(
        message="DOB: 15/03/1995",
        expected_sensitive=True,
        expected_categories=["dob"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Date of birth is 01-15-1990",
        expected_sensitive=True,
        expected_categories=["dob"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Patient ID: MRN783921 admitted today",
        expected_sensitive=True,
        expected_categories=["medical"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Diagnosis: Type 2 Diabetes",
        expected_sensitive=True,
        expected_categories=["medical"],
        platform="email",
        context="formal"
    ),

    # ==================================================================
    # IP ADDRESS TESTS
    # ==================================================================

    TestCase(
        message="Server IP is 192.168.1.100",
        expected_sensitive=True,
        expected_categories=["ip_address"],
        platform="telegram",
        context="casual"
    ),

    # ==================================================================
    # MIXED CONTENT TESTS (multiple categories in one message)
    # ==================================================================

    TestCase(
        message="Card 4532015112830366 password xyz789!",
        expected_sensitive=True,
        expected_categories=["credit_card", "password"],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="Send to john@example.com, password is Pass@2024",
        expected_sensitive=True,
        expected_categories=["email", "password"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Call +94 77 123 4567, PIN is 4321",
        expected_sensitive=True,
        expected_categories=["phone", "pin"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="NIC 901234567V, account 12345678901234",
        expected_sensitive=True,
        expected_categories=["nic", "bank_account"],
        platform="sms",
        context="casual"
    ),

    # ==================================================================
    # SAFE MESSAGES - Should NOT trigger (False Positive tests)
    # ==================================================================

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
        expected_sensitive=False,
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
        expected_sensitive=False,
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Room 1234 at the hotel",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="The meeting is at 3pm today",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Great job on the project!",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="Can you send me the report by Friday?",
        expected_sensitive=False,
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="I'll be there in 10 minutes",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Happy birthday! Hope you have a great day",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="Let's schedule a call for next week",
        expected_sensitive=False,
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="The PIN on the map marks the restaurant location",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Your reference number is REF-2024-001",
        expected_sensitive=False,
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="See you at the Dialog showroom",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Score was 4500 points in the game",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="The class starts at room B204",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Invoice total is Rs. 15000",
        expected_sensitive=False,
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="We need to change our approach to passwords in the org",
        expected_sensitive=False,
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Good morning! How are you today?",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),

    # ==================================================================
    # SRI LANKAN CONTEXT TESTS
    # ==================================================================

    # Dialog/Mobitel style promos (should NOT trigger — not sensitive)
    TestCase(
        message="Dialog: Your data balance is 2.5GB. Dial #678# to check.",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Mobitel: Reload Rs.100 and get 1GB FREE! Valid till 31/03.",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),

    # Bank OTP (should trigger)
    TestCase(
        message="BOC: Your OTP is 482719. Do not share with anyone.",
        expected_sensitive=True,
        expected_categories=["otp"],
        platform="sms",
        context="urgent"
    ),
    TestCase(
        message="Sampath Bank: Your verification code is 349821",
        expected_sensitive=True,
        expected_categories=["otp"],
        platform="sms",
        context="urgent"
    ),

    # Sharing NIC casually
    TestCase(
        message="Bro send ur NIC number. Mine is 952345678V",
        expected_sensitive=True,
        expected_categories=["nic"],
        platform="telegram",
        context="casual"
    ),

    # ==================================================================
    # PASSPORT / DRIVERS LICENSE TESTS
    # ==================================================================

    TestCase(
        message="Passport: N12345678 for the visa application",
        expected_sensitive=True,
        expected_categories=["passport"],
        platform="email",
        context="formal"
    ),

    # ==================================================================
    # ADDITIONAL TESTS — reaching 100+ for statistical significance
    # ==================================================================

    # More "is" delimiter tests (the pattern that was previously broken)
    TestCase(
        message="CVV is 321",
        expected_sensitive=True,
        expected_categories=["cvv"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Date of birth is 01-15-1990",
        expected_sensitive=True,
        expected_categories=["dob"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="My bank acc number is 0012345678901",
        expected_sensitive=True,
        expected_categories=["bank_account"],
        platform="sms",
        context="casual"
    ),

    # More cross-platform duplicates (same data, different platform)
    TestCase(
        message="Password: admin123!",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="Password: admin123!",
        expected_sensitive=True,
        expected_categories=["password"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="OTP is 456789",
        expected_sensitive=True,
        expected_categories=["otp"],
        platform="telegram",
        context="urgent"
    ),
    TestCase(
        message="OTP is 456789",
        expected_sensitive=True,
        expected_categories=["otp"],
        platform="email",
        context="urgent"
    ),
    TestCase(
        message="My NIC is 901234567V",
        expected_sensitive=True,
        expected_categories=["nic"],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="My NIC is 901234567V",
        expected_sensitive=True,
        expected_categories=["nic"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="SSN: 123-45-6789",
        expected_sensitive=True,
        expected_categories=["ssn"],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="SSN: 123-45-6789",
        expected_sensitive=True,
        expected_categories=["ssn"],
        platform="telegram",
        context="casual"
    ),

    # More Sri Lankan bank context
    TestCase(
        message="HNB: OTP 291034 for your transaction. Do not share.",
        expected_sensitive=True,
        expected_categories=["otp"],
        platform="sms",
        context="urgent"
    ),
    TestCase(
        message="Commercial Bank: Your one-time code is 583012",
        expected_sensitive=True,
        expected_categories=["otp"],
        platform="sms",
        context="urgent"
    ),

    # More safe messages — common Sri Lankan SMS patterns
    TestCase(
        message="Keells: Your bill is Rs. 3450. Thank you for shopping!",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Uber: Your trip to Colombo Fort costs Rs. 890",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="PickMe: Driver Nimal is arriving in 3 minutes",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="Lecture cancelled tomorrow. Check LMS for updates.",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="Submit your assignment by Friday 5pm",
        expected_sensitive=False,
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="The Wi-Fi is down again in the lab",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),

    # ==================================================================
    # ADVERSARIAL / HARD CASES — tests that should challenge the detector
    # ==================================================================

    # Tricky safe messages that contain trigger words but aren't sensitive
    TestCase(
        message="I need to reset my password on the website",
        expected_sensitive=False,
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Can you help me remember my PIN? I forgot it",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="The credit card machine is broken at the store",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="I changed my bank account details last week",
        expected_sensitive=False,
        expected_categories=[],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="What's your email? I'll send you the file",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="The OTP system is not working on the app",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),
    TestCase(
        message="He told me his date of birth but I forgot it",
        expected_sensitive=False,
        expected_categories=[],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="The NIC office is closed on weekends",
        expected_sensitive=False,
        expected_categories=[],
        platform="sms",
        context="casual"
    ),

    # Sensitive data embedded in longer natural messages
    TestCase(
        message="Hey can you pay for the hotel? My card is 4532015112830366 and the CVV on the back is 421",
        expected_sensitive=True,
        expected_categories=["credit_card", "cvv"],
        platform="telegram",
        context="casual"
    ),
    TestCase(
        message="For the bank transfer use account 98765432101234 and the routing number is routing: 123456789",
        expected_sensitive=True,
        expected_categories=["bank_account"],
        platform="email",
        context="formal"
    ),
    TestCase(
        message="Just got the new NIC card, my number is 200112345678. They spelled my name wrong lol",
        expected_sensitive=True,
        expected_categories=["nic"],
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

    # Count by category
    category_counts = {}
    for t in TEST_DATASET:
        for cat in t.expected_categories:
            category_counts[cat] = category_counts.get(cat, 0) + 1

    print(f"\n{'='*50}")
    print(f"MSDS Test Dataset Summary")
    print(f"{'='*50}")
    print(f"Total test cases: {total}")
    print(f"Sensitive messages: {sensitive}")
    print(f"Safe messages: {safe}")
    print(f"\nPlatform distribution:")
    for platform, count in get_platform_distribution().items():
        print(f"  - {platform}: {count}")
    print(f"\nCategory distribution:")
    for cat, count in sorted(category_counts.items()):
        print(f"  - {cat}: {count}")
    print(f"{'='*50}\n")


if __name__ == "__main__":
    print_dataset_summary()
