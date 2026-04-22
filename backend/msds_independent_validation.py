"""
MSDS Independent Validation Dataset
====================================
Completely separate dataset from the training/tuning set.
Used to validate that MSDS findings hold on unseen data.

This dataset simulates REAL messages a Sri Lankan university student
might encounter across SMS, Email, and Telegram — including:
- Bank OTPs from local banks (BOC, Sampath, HNB, Commercial Bank)
- Dialog/Mobitel service messages
- University-related messages
- Casual Sinhala-English (Singlish) messaging patterns
- Scam/spam messages common in Sri Lanka
- Real edge cases that challenge the detector

Author: Independent validation — not used during development
"""

from msds_evaluator import MSDSEvaluator, TestCase, DetectionResult
from dlp_detector import DLPDetector
import json
import os
from datetime import datetime


VALIDATION_DATASET = [

    # ==================================================================
    # CATEGORY 1: BANK / FINANCIAL OTPs (Sri Lankan banks)
    # ==================================================================
    TestCase(
        message="BOC: Your OTP for online banking is 391847. Valid for 3 mins.",
        expected_sensitive=True, expected_categories=["otp"],
        platform="sms", context="urgent"
    ),
    TestCase(
        message="Sampath Bank: Use code 284619 to confirm your transfer of Rs.25000",
        expected_sensitive=True, expected_categories=["otp"],
        platform="sms", context="urgent"
    ),
    TestCase(
        message="HNB: OTP 583201 for your credit card payment. Do NOT share.",
        expected_sensitive=True, expected_categories=["otp"],
        platform="sms", context="urgent"
    ),
    TestCase(
        message="NTB: Your verification code is 947283",
        expected_sensitive=True, expected_categories=["otp"],
        platform="sms", context="urgent"
    ),
    TestCase(
        message="Cargills Bank: OTP 127394 for login. Expires in 5 minutes.",
        expected_sensitive=True, expected_categories=["otp"],
        platform="sms", context="urgent"
    ),

    # ==================================================================
    # CATEGORY 2: PASSWORDS (various styles)
    # ==================================================================
    TestCase(
        message="bro the server password is Gr33nLantern!",
        expected_sensitive=True, expected_categories=["password"],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="wifi pwd: ColomboNet#2024",
        expected_sensitive=True, expected_categories=["password"],
        platform="sms", context="casual"
    ),
    TestCase(
        message="Dear student, your LMS password is StudentTemp2024. Please change immediately.",
        expected_sensitive=True, expected_categories=["password"],
        platform="email", context="formal"
    ),
    TestCase(
        message="passwd= rootAccess99!",
        expected_sensitive=True, expected_categories=["password"],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="your new email password: xK9#mPqR2v",
        expected_sensitive=True, expected_categories=["password"],
        platform="email", context="formal"
    ),
    TestCase(
        message="my pass is dragon2024",
        expected_sensitive=True, expected_categories=["password"],
        platform="sms", context="casual"
    ),

    # ==================================================================
    # CATEGORY 3: CREDIT CARDS (valid Luhn)
    # ==================================================================
    TestCase(
        message="Pay with my Visa 4539578763621486 exp 08/27",
        expected_sensitive=True, expected_categories=["credit_card"],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="Card number for booking: 5425233430109903",
        expected_sensitive=True, expected_categories=["credit_card"],
        platform="email", context="formal"
    ),
    TestCase(
        message="use my mastercard 5425233430109903 cvv 847",
        expected_sensitive=True, expected_categories=["credit_card", "cvv"],
        platform="sms", context="casual"
    ),

    # ==================================================================
    # CATEGORY 4: SRI LANKAN NIC
    # ==================================================================
    TestCase(
        message="my NIC 982345671V need it for the form",
        expected_sensitive=True, expected_categories=["nic"],
        platform="sms", context="casual"
    ),
    TestCase(
        message="NIC number: 200198765432",
        expected_sensitive=True, expected_categories=["nic"],
        platform="email", context="formal"
    ),
    TestCase(
        message="ane machang NIC eka 951234567X kiyla daganna",
        expected_sensitive=True, expected_categories=["nic"],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="For the university registration: NIC 199845678901",
        expected_sensitive=True, expected_categories=["nic"],
        platform="email", context="formal"
    ),

    # ==================================================================
    # CATEGORY 5: PHONE NUMBERS (Sri Lankan)
    # ==================================================================
    TestCase(
        message="call my dialog number 0776543210",
        expected_sensitive=True, expected_categories=["phone"],
        platform="sms", context="casual"
    ),
    TestCase(
        message="Reach me at +94 71 234 5678",
        expected_sensitive=True, expected_categories=["phone"],
        platform="email", context="formal"
    ),
    TestCase(
        message="mobitel num 0701234567 eken call karanna",
        expected_sensitive=True, expected_categories=["phone"],
        platform="telegram", context="casual"
    ),

    # ==================================================================
    # CATEGORY 6: EMAIL ADDRESSES
    # ==================================================================
    TestCase(
        message="send the assignment to lecturer@sjp.ac.lk",
        expected_sensitive=True, expected_categories=["email"],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="My personal email is kasun.perera@gmail.com",
        expected_sensitive=True, expected_categories=["email"],
        platform="sms", context="casual"
    ),

    # ==================================================================
    # CATEGORY 7: BANK ACCOUNTS
    # ==================================================================
    TestCase(
        message="Transfer to my BOC account 8012345678901",
        expected_sensitive=True, expected_categories=["bank_account"],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="Savings acct: 10987654321234",
        expected_sensitive=True, expected_categories=["bank_account"],
        platform="sms", context="casual"
    ),

    # ==================================================================
    # CATEGORY 8: PINs
    # ==================================================================
    TestCase(
        message="ATM pin is 4523",
        expected_sensitive=True, expected_categories=["pin"],
        platform="sms", context="casual"
    ),
    TestCase(
        message="Your new PIN code: 8817",
        expected_sensitive=True, expected_categories=["pin"],
        platform="email", context="formal"
    ),

    # ==================================================================
    # CATEGORY 9: SSN (international users)
    # ==================================================================
    TestCase(
        message="social security number is 456-78-9012",
        expected_sensitive=True, expected_categories=["ssn"],
        platform="email", context="formal"
    ),

    # ==================================================================
    # CATEGORY 10: MIXED CONTENT
    # ==================================================================
    TestCase(
        message="Login: admin@portal.lk password is Portal@2024",
        expected_sensitive=True, expected_categories=["email", "password"],
        platform="email", context="formal"
    ),
    TestCase(
        message="NIC 982345671V phone 0776543210 eken register karanna",
        expected_sensitive=True, expected_categories=["nic", "phone"],
        platform="sms", context="casual"
    ),

    # ==================================================================
    # SAFE MESSAGES — Dialog/Mobitel/Carrier (should NOT trigger)
    # ==================================================================
    TestCase(
        message="Dialog: You have used 3.2GB of your 5GB data plan. Dial #678#",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
    TestCase(
        message="Mobitel: Happy New Year! Enjoy DOUBLE data all weekend!",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
    TestCase(
        message="Dialog TV: Your subscription renews on 01/04/2025. Rs.599",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
    TestCase(
        message="Hutch: Reload Rs.200 and get 2GB bonus valid for 7 days",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),

    # ==================================================================
    # SAFE MESSAGES — University context
    # ==================================================================
    TestCase(
        message="Assignment deadline extended to next Friday 5pm",
        expected_sensitive=False, expected_categories=[],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="FYP presentation scheduled for March 25th at 2pm",
        expected_sensitive=False, expected_categories=[],
        platform="email", context="formal"
    ),
    TestCase(
        message="Lab is closed tomorrow. Use the library computers instead.",
        expected_sensitive=False, expected_categories=[],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="Please submit your research proposal by end of week",
        expected_sensitive=False, expected_categories=[],
        platform="email", context="formal"
    ),
    TestCase(
        message="Group project meeting at canteen 12pm dont be late",
        expected_sensitive=False, expected_categories=[],
        platform="telegram", context="casual"
    ),

    # ==================================================================
    # SAFE MESSAGES — Daily life (Sri Lankan context)
    # ==================================================================
    TestCase(
        message="Keells Super: Your bill Rs.4250. Points earned: 42",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
    TestCase(
        message="PickMe: Your ride is arriving. Driver: Mahesh. Vehicle: WP CAB 1234",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
    TestCase(
        message="Daraz: Your order #LK78234 has been shipped! Track at daraz.lk",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
    TestCase(
        message="Pizza Hut: Order confirmed! Delivery in 30-45 mins. Ref: PH20241234",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
    TestCase(
        message="Traffic is really bad on Galle Road today. Take the highway instead.",
        expected_sensitive=False, expected_categories=[],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="oya exam eka kohomada? mage hondai. API kiyla eka gahanna baruyi",
        expected_sensitive=False, expected_categories=[],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="Match eka balanna dialog tv eken set karamu",
        expected_sensitive=False, expected_categories=[],
        platform="telegram", context="casual"
    ),

    # ==================================================================
    # SAFE MESSAGES — Tricky (contain keywords but not actual sensitive data)
    # ==================================================================
    TestCase(
        message="Remember to update your password regularly for security",
        expected_sensitive=False, expected_categories=[],
        platform="email", context="formal"
    ),
    TestCase(
        message="The ATM PIN pad was damaged so I couldn't withdraw",
        expected_sensitive=False, expected_categories=[],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="NIC office eke queue eka ithin yanna baa today",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
    TestCase(
        message="I forgot my OTP because the SMS came late",
        expected_sensitive=False, expected_categories=[],
        platform="telegram", context="casual"
    ),
    TestCase(
        message="Can someone share their credit card terminal receipt format?",
        expected_sensitive=False, expected_categories=[],
        platform="email", context="formal"
    ),
    TestCase(
        message="The bank account opening process takes 3 working days",
        expected_sensitive=False, expected_categories=[],
        platform="email", context="formal"
    ),
    TestCase(
        message="Your OTP feature has been enabled successfully",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
    TestCase(
        message="We need to discuss the password policy for the new system",
        expected_sensitive=False, expected_categories=[],
        platform="email", context="formal"
    ),

    # ==================================================================
    # REAL-WORLD SMS (captured from actual phones in Sri Lanka)
    # ==================================================================

    # Real scam SMS — no sensitive data, just phishing links
    TestCase(
        message="Rs.100 000 k dakwa nayak kalin anumatha kara aetha! Salli ganna: https://f1na.com/FtgcvRB",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
    TestCase(
        message="250.000 LKR rin - wadiya honda 0.01%! Danma balanna: https://f1na.com/HxFUFwi",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),

    # Real carrier promo — unsolicited but no sensitive data
    TestCase(
        message="Samsung A06 smartphone එකක් රු.15,160/-ක් ගෙවා අරගෙන යන්න! ඉතිරිය සමාන මාසික වාරික (රු. 2,123/-) 12 කින් ගෙවන්න. වසර 2ක වගකීමක් සහ නොමිලේ 25W Adapter එකක් සමඟ ලබාගැනීමට අදම ළඟම ඇති MOBITEL ශාඛාව වෙත පිවිසෙන්නෙ.",
        expected_sensitive=False, expected_categories=[],
        platform="sms", context="casual"
    ),
]


def run_validation():
    """Run independent validation experiment"""

    print("=" * 70)
    print("  MSDS INDEPENDENT VALIDATION")
    print("  Testing with completely separate dataset (not used in development)")
    print("=" * 70)

    detector = DLPDetector()
    evaluator = MSDSEvaluator()

    total = len(VALIDATION_DATASET)
    sensitive = sum(1 for t in VALIDATION_DATASET if t.expected_sensitive)
    safe = total - sensitive

    # Platform distribution
    platform_dist = {}
    for tc in VALIDATION_DATASET:
        platform_dist[tc.platform] = platform_dist.get(tc.platform, 0) + 1

    print(f"\n  Dataset: {total} cases ({sensitive} sensitive, {safe} safe)")
    print(f"  Platforms: {platform_dist}")

    # Run evaluation
    print(f"\n  Running detection...\n")

    failures = []
    for i, test_case in enumerate(VALIDATION_DATASET, 1):
        dlp_result = detector.analyze(test_case.message)
        detection = DetectionResult(
            detected_sensitive=dlp_result['has_sensitive_data'],
            detected_categories=dlp_result.get('categories', []),
            sensitivity_level=dlp_result.get('sensitivity_level', 'none')
        )
        result = evaluator.evaluate_single(test_case, detection)

        status = "PASS" if result['correct'] else "FAIL"
        if not result['correct']:
            failures.append({
                'index': i,
                'message': test_case.message[:60],
                'expected': test_case.expected_sensitive,
                'got': detection.detected_sensitive,
                'type': result['result_type'],
                'platform': test_case.platform,
                'detected_cats': detection.detected_categories,
                'expected_cats': test_case.expected_categories,
            })

        print(f"  [{i:3d}] {status} {result['result_type']:3} | {test_case.platform:8} | {test_case.message[:55]}...")

    # Results
    traditional = evaluator.calculate_traditional_metrics()
    msds = evaluator.calculate_msds(platform_dist)
    platform_metrics = evaluator.calculate_platform_metrics()

    print(f"\n{'=' * 70}")
    print(f"  VALIDATION RESULTS")
    print(f"{'=' * 70}")

    print(f"\n  Confusion Matrix:")
    print(f"    TP: {evaluator.tp}  |  FP: {evaluator.fp}")
    print(f"    FN: {evaluator.fn}  |  TN: {evaluator.tn}")

    print(f"\n  Traditional Metrics:")
    print(f"    Precision: {traditional['precision']}")
    print(f"    Recall:    {traditional['recall']}")
    print(f"    F1 Score:  {traditional['f1_score']}")
    print(f"    Accuracy:  {traditional['accuracy']}")

    print(f"\n  MSDS Score:  {msds}")
    print(f"    Cw: {evaluator.calculate_context_weight():.4f}")
    print(f"    Pf: {evaluator.calculate_platform_factor(platform_dist):.4f}")
    print(f"    Cp: {evaluator.context_penalty:.4f}")

    print(f"\n  Per-Platform Breakdown:")
    print(f"    {'Platform':<12} {'Acc':>8} {'Prec':>8} {'Recall':>8} {'F1':>8} {'N':>4}")
    print(f"    {'-'*48}")
    for platform, metrics in platform_metrics.items():
        print(f"    {platform:<12} {metrics['accuracy']:>8.4f} {metrics['precision']:>8.4f} {metrics['recall']:>8.4f} {metrics['f1_score']:>8.4f} {metrics['total']:>4}")

    if failures:
        print(f"\n  FAILURES ({len(failures)}):")
        for f in failures:
            print(f"    [{f['index']}] {f['type']} | {f['platform']} | Expected sensitive={f['expected']}, "
                  f"Got sensitive={f['got']}")
            print(f"         Expected: {f['expected_cats']} | Detected: {f['detected_cats']}")
            print(f"         \"{f['message']}\"")

    # Save
    os.makedirs('results', exist_ok=True)
    report = {
        'experiment': 'Independent Validation',
        'date': datetime.now().isoformat(),
        'dataset_size': total,
        'sensitive': sensitive,
        'safe': safe,
        'platform_distribution': platform_dist,
        'confusion_matrix': {
            'tp': evaluator.tp, 'fp': evaluator.fp,
            'fn': evaluator.fn, 'tn': evaluator.tn
        },
        'traditional_metrics': traditional,
        'msds_score': msds,
        'msds_components': {
            'context_weight': round(evaluator.calculate_context_weight(), 4),
            'platform_factor': round(evaluator.calculate_platform_factor(platform_dist), 4),
            'context_penalty': round(evaluator.context_penalty, 4),
        },
        'platform_metrics': platform_metrics,
        'failures': failures,
    }

    with open('results/msds_independent_validation.json', 'w') as f:
        json.dump(report, f, indent=2)

    print(f"\n  Report saved to: results/msds_independent_validation.json")
    print(f"{'=' * 70}")

    return report


if __name__ == '__main__':
    run_validation()
