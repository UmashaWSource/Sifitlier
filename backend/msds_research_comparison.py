"""
MSDS vs Traditional Metrics — Research Comparison
==================================================
This script demonstrates WHY the MSDS metric provides insights
that traditional F1/Precision/Recall cannot capture.

Key Research Finding:
    F1 treats all errors equally. MSDS does not.
    - Missing a credit card in an SMS is worse than missing an email address
    - SMS detection is harder than email detection (shorter, abbreviated text)
    - F1 gives one number. MSDS captures context, platform, and severity.

This produces the comparison table and analysis for the FYP report.

Author: Umasha Wijenayake
"""

import json
import time
from datetime import datetime
from msds_evaluator import MSDSEvaluator, TestCase, DetectionResult
from dlp_detector import DLPDetector


def create_realistic_test_sets():
    """
    Create three test sets with different difficulty levels.
    These simulate real-world conditions where messages are messy,
    abbreviated, and context-dependent.
    """

    # SET A: Clean/formal messages (easy — like email)
    set_a = [
        TestCase("Your temporary password is TempPass@2024", True, ["password"], "email", "formal"),
        TestCase("Credit card: 4532015112830366", True, ["credit_card"], "email", "formal"),
        TestCase("SSN: 123-45-6789", True, ["ssn"], "email", "formal"),
        TestCase("Account number: 12345678901234", True, ["bank_account"], "email", "formal"),
        TestCase("Your OTP is 482719", True, ["otp"], "email", "formal"),
        TestCase("NIC: 901234567V", True, ["nic"], "email", "formal"),
        TestCase("Contact: john@example.com", True, ["email"], "email", "formal"),
        TestCase("DOB: 15/03/1995", True, ["dob"], "email", "formal"),
        TestCase("The quarterly report is ready for review", False, [], "email", "formal"),
        TestCase("Please schedule a meeting for next Monday", False, [], "email", "formal"),
        TestCase("Thank you for your prompt response", False, [], "email", "formal"),
        TestCase("Attached is the project proposal document", False, [], "email", "formal"),
    ]

    # SET B: Casual SMS (medium — abbreviated, no punctuation)
    set_b = [
        TestCase("my pwd is Secret123", True, ["password"], "sms", "casual"),
        TestCase("card 4532015112830366 use this", True, ["credit_card"], "sms", "casual"),
        TestCase("my nic 901234567V send urs too", True, ["nic"], "sms", "casual"),
        TestCase("pin is 1234", True, ["pin"], "sms", "casual"),
        TestCase("otp 482719 dont share", True, ["otp"], "sms", "casual"),
        TestCase("call me 0771234567", True, ["phone"], "sms", "casual"),
        TestCase("ur pass is qwerty", True, ["password"], "sms", "casual"),
        TestCase("acc 12345678901234 transfer here", True, ["bank_account"], "sms", "casual"),
        TestCase("ok c u tmrw", False, [], "sms", "casual"),
        TestCase("bring food pls hungry", False, [], "sms", "casual"),
        TestCase("the pin on google maps shows location", False, [], "sms", "casual"),
        TestCase("need to change password on laptop", False, [], "sms", "casual"),
    ]

    # SET C: Adversarial/tricky messages (hard — ambiguous context)
    set_c = [
        # These have sensitive data buried in natural conversation
        TestCase("btw the wifi pass is netgear99 if u need it", True, ["password"], "telegram", "casual"),
        TestCase("lol my old NIC was 876543210X got new one now", True, ["nic"], "telegram", "casual"),
        # These look like they have sensitive data but don't
        TestCase("the password policy requires 8 characters minimum", False, [], "telegram", "casual"),
        TestCase("I called the credit card company about the charge", False, [], "telegram", "casual"),
        TestCase("the OTP feature is broken on the banking app", False, [], "telegram", "casual"),
        TestCase("she forgot her PIN at the ATM yesterday", False, [], "telegram", "casual"),
        # Misspellings and slang that make detection harder
        TestCase("passwrd: hunter2", True, ["password"], "telegram", "casual"),
        TestCase("my social security 987-65-4321", True, ["ssn"], "telegram", "casual"),
        # Numbers that could be sensitive but aren't
        TestCase("score was 4532015112830366 points in the game", False, [], "telegram", "casual"),
        TestCase("order 12345678901234 shipped today", False, [], "telegram", "casual"),
        TestCase("meeting at building 901234567 room V", False, [], "telegram", "casual"),
        TestCase("The temperature is 199912345678 nanokelvins lol", False, [], "telegram", "casual"),
    ]

    return {
        'email_formal': set_a,
        'sms_casual': set_b,
        'telegram_adversarial': set_c,
    }


def evaluate_set(detector, test_set, set_name):
    """Evaluate detector on a single test set and return metrics"""
    evaluator = MSDSEvaluator()

    for test_case in test_set:
        dlp_result = detector.analyze(test_case.message)
        detection = DetectionResult(
            detected_sensitive=dlp_result['has_sensitive_data'],
            detected_categories=dlp_result.get('categories', []),
            sensitivity_level=dlp_result.get('sensitivity_level', 'none')
        )
        evaluator.evaluate_single(test_case, detection)

    platform_dist = {}
    for tc in test_set:
        platform_dist[tc.platform] = platform_dist.get(tc.platform, 0) + 1

    traditional = evaluator.calculate_traditional_metrics()
    msds = evaluator.calculate_msds(platform_dist)

    return {
        'set_name': set_name,
        'total': len(test_set),
        'tp': evaluator.tp,
        'tn': evaluator.tn,
        'fp': evaluator.fp,
        'fn': evaluator.fn,
        'precision': traditional['precision'],
        'recall': traditional['recall'],
        'f1': traditional['f1_score'],
        'accuracy': traditional['accuracy'],
        'msds': msds,
        'context_weight': round(evaluator.calculate_context_weight(), 4),
        'platform_factor': round(evaluator.calculate_platform_factor(platform_dist), 4),
        'context_penalty': round(evaluator.context_penalty, 4),
    }


def run_latency_comparison(detector):
    """Compare local vs simulated cloud latency"""
    test_messages = [
        "my password is Secret123",
        "Meeting at 3pm tomorrow",
        "Card 4532015112830366 cvv 321",
        "Hey what's up?",
        "NIC 901234567V for the form",
    ] * 20  # 100 messages

    # Local DLP latency
    start = time.perf_counter()
    for msg in test_messages:
        detector.analyze(msg)
    local_total = (time.perf_counter() - start) * 1000  # ms

    local_avg = local_total / len(test_messages)

    # Simulated cloud latency (typical HTTP round-trip)
    cloud_avg = 150  # ms (conservative estimate for mobile network)

    return {
        'messages_tested': len(test_messages),
        'local_avg_ms': round(local_avg, 3),
        'cloud_avg_ms': cloud_avg,
        'speedup': round(cloud_avg / local_avg, 1),
        'local_total_ms': round(local_total, 1),
    }


def run_comparison():
    """Main comparison experiment for the FYP report"""

    print("=" * 70)
    print("  MSDS vs TRADITIONAL METRICS — RESEARCH COMPARISON")
    print("  Demonstrating why MSDS provides better evaluation for mobile DLP")
    print("=" * 70)

    detector = DLPDetector()
    test_sets = create_realistic_test_sets()

    # ============== EXPERIMENT 1: Per-Set Comparison ==============
    print("\n" + "=" * 70)
    print("  EXPERIMENT 1: Cross-Platform Detection Quality")
    print("  Same detector, different message styles")
    print("=" * 70)

    results = []
    for set_name, test_set in test_sets.items():
        result = evaluate_set(detector, test_set, set_name)
        results.append(result)

    # Print comparison table
    print(f"\n{'Set':<25} {'F1':>8} {'MSDS':>8} {'Diff':>8} {'TP':>4} {'FP':>4} {'FN':>4} {'Cw':>6} {'Pf':>6}")
    print("-" * 78)
    for r in results:
        diff = round(r['msds'] - r['f1'], 4)
        print(f"{r['set_name']:<25} {r['f1']:>8.4f} {r['msds']:>8.4f} {diff:>+8.4f} {r['tp']:>4} {r['fp']:>4} {r['fn']:>4} {r['context_weight']:>6.2f} {r['platform_factor']:>6.2f}")

    # ============== EXPERIMENT 2: Key Research Insight ==============
    print("\n" + "=" * 70)
    print("  EXPERIMENT 2: Why MSDS Differs From F1")
    print("=" * 70)

    print("""
  KEY INSIGHT:
  F1 Score treats all errors equally:
    - Missing a credit card = Missing an email address
    - SMS false negative = Email false negative
    - Wrong category = Correct category

  MSDS captures what F1 cannot:
    1. Context Weight (Cw): Penalizes wrong category detection
       (detecting "phone" when it's actually a "credit_card" is worse)

    2. Platform Factor (Pf): SMS detection is harder (score = 1.2x)
       because messages are shorter and more abbreviated

    3. Context Penalty (Cp): Missing critical data (passwords, cards)
       is penalized MORE than missing low-sensitivity data (emails)

  This means MSDS can be LOWER than F1 (system has context weaknesses)
  or HIGHER than F1 (system handles hard platforms well).
  F1 alone cannot distinguish between these scenarios.
""")

    # ============== EXPERIMENT 3: Latency Comparison ==============
    print("=" * 70)
    print("  EXPERIMENT 3: On-Device vs Cloud Inference")
    print("=" * 70)

    latency = run_latency_comparison(detector)
    print(f"""
  Messages tested:     {latency['messages_tested']}
  Local avg latency:   {latency['local_avg_ms']} ms/message
  Cloud avg latency:   {latency['cloud_avg_ms']} ms/message (estimated)
  Speedup:             {latency['speedup']}x faster locally

  Privacy benefit:     Messages NEVER leave the device
  Offline capability:  Works without internet connection
  Battery impact:      Minimal (no network radio usage)
""")

    # ============== SAVE RESULTS ==============
    import os
    os.makedirs('results', exist_ok=True)
    report = {
        'experiment_date': datetime.now().isoformat(),
        'experiment_type': 'MSDS vs Traditional Metrics Comparison',
        'per_set_results': results,
        'latency_comparison': latency,
        'research_contribution': {
            'metric_name': 'MSDS - Mobile Sensitivity Detection Score',
            'formula': 'MSDS = (TP * Cw * Pf) / (TP + FP + FN + Cp)',
            'advantages_over_f1': [
                'Captures platform-specific difficulty (SMS harder than email)',
                'Penalizes missing critical data more than missing low-sensitivity data',
                'Rewards correct category identification, not just binary detection',
                'Provides actionable insights: which platform needs improvement',
            ],
            'author': 'Umasha Wijenayake',
        }
    }

    report_path = f"results/msds_research_comparison.json"
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)
    print(f"Report saved to: {report_path}")
    print("=" * 70)

    return report


if __name__ == '__main__':
    run_comparison()
