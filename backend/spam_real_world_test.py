"""
Real-World Spam Detection Test
================================
Tests the spam classifier against actual messages captured
from phones in Sri Lanka — including scam SMS, carrier promos,
and normal daily messages.

This validates the model works on real data, not just lab datasets.
"""

from train_spam_classifier import SpamClassifier


def run_real_world_test():
    """Test spam classifier on real Sri Lankan messages"""

    print("=" * 70)
    print("  SPAM CLASSIFIER — REAL-WORLD MESSAGE TEST")
    print("  Messages captured from actual phones in Sri Lanka")
    print("=" * 70)

    classifier = SpamClassifier()
    classifier.load('spam_classifier_pipeline.pkl')

    # (message, expected_label, description)
    test_cases = [
        # ============== REAL SCAM SMS ==============
        ("Rs.100 000 k dakwa nayak kalin anumatha kara aetha! Salli ganna: https://f1na.com/FtgcvRB",
         "spam", "Singlish loan scam with phishing URL"),

        ("250.000 LKR rin - wadiya honda 0.01%! Danma balanna: https://f1na.com/HxFUFwi",
         "spam", "Singlish loan scam - impossible interest rate"),

        # ============== REAL CARRIER PROMOS (unsolicited = spam) ==============
        ("Samsung A06 smartphone එකක් රු.15,160/-ක් ගෙවා අරගෙන යන්න! ඉතිරිය සමාන මාසික වාරික (රු. 2,123/-) 12 කින් ගෙවන්න.",
         "spam", "Mobitel device promo - Sinhala (unsolicited)"),

        ("Dialog: Activate Rs.99 YouTube pack! Unlimited YouTube for 30 days. Dial #678*99#",
         "spam", "Dialog promo - English"),

        ("Mobitel: Reload Rs.200 and get 2GB bonus data FREE! Valid for 7 days. T&C apply.",
         "spam", "Mobitel reload promo"),

        # ============== REAL LEGITIMATE MESSAGES ==============
        ("Your Uber is arriving now. Driver: Kasun, Vehicle: WP-CAB-1234",
         "ham", "Uber ride notification"),

        ("PickMe: Your ride request has been accepted. Arriving in 5 mins.",
         "ham", "PickMe notification"),

        ("Your Daraz order #LK24789 has been shipped. Track: daraz.lk/track",
         "ham", "Daraz shipping notification"),

        ("Keells: Your bill is Rs.3,450. You earned 34 Nexus points. Thank you!",
         "ham", "Keells receipt"),

        # ============== REAL BANK NOTIFICATIONS ==============
        ("BOC: Your account XX1234 has been credited with Rs.50,000.00 on 18/03/2025",
         "ham", "BOC transaction alert"),

        ("Sampath Bank: Your credit card ending 9876 was charged Rs.12,500 at Dialog.",
         "ham", "Sampath card notification"),

        ("HNB: Your fixed deposit of Rs.500,000 matures on 25/03/2025. Visit branch.",
         "ham", "HNB FD maturity notice"),

        # ============== NORMAL PERSONAL MESSAGES ==============
        ("oya exam eka kohomada? mage nam hondai",
         "ham", "Singlish casual - asking about exam"),

        ("machang 6.30 ta ena. late unoth call karanna",
         "ham", "Singlish casual - making plans"),

        ("Lab cancelled tomorrow. Check LMS for assignment details.",
         "ham", "University notification"),

        ("Hey can you send me the notes from yesterday's lecture?",
         "ham", "Student message"),

        ("Happy birthday! Hope you have an amazing day!",
         "ham", "Birthday wish"),

        ("Mom wants to know if you're coming for dinner Sunday",
         "ham", "Family message"),
    ]

    print(f"\n  Testing {len(test_cases)} real-world messages...\n")

    correct = 0
    wrong = 0
    results = []

    for msg, expected, description in test_cases:
        result = classifier.predict(msg)
        predicted = result['label']
        is_correct = predicted == expected

        if is_correct:
            correct += 1
            status = "PASS"
        else:
            wrong += 1
            status = "FAIL"

        results.append({
            'message': msg[:50],
            'expected': expected,
            'predicted': predicted,
            'probability': result['spam_probability'],
            'correct': is_correct,
            'description': description,
        })

        prob_pct = result['spam_probability'] * 100
        print(f"  {status} [{predicted.upper():4s} {prob_pct:5.1f}%] {description}")
        if not is_correct:
            print(f"         Expected: {expected} | Got: {predicted}")
            print(f"         \"{msg[:60]}...\"")

    # Summary
    accuracy = correct / len(test_cases)
    spam_cases = [r for r in results if r['expected'] == 'spam']
    ham_cases = [r for r in results if r['expected'] == 'ham']

    spam_correct = sum(1 for r in spam_cases if r['correct'])
    ham_correct = sum(1 for r in ham_cases if r['correct'])

    print(f"\n{'=' * 70}")
    print(f"  RESULTS")
    print(f"{'=' * 70}")
    print(f"  Total: {correct}/{len(test_cases)} correct ({accuracy*100:.1f}%)")
    print(f"  Spam detection:  {spam_correct}/{len(spam_cases)} ({spam_correct/len(spam_cases)*100:.0f}%)")
    print(f"  Ham detection:   {ham_correct}/{len(ham_cases)} ({ham_correct/len(ham_cases)*100:.0f}%)")

    if wrong > 0:
        print(f"\n  Misclassified ({wrong}):")
        for r in results:
            if not r['correct']:
                print(f"    - [{r['description']}] expected={r['expected']}, got={r['predicted']} ({r['probability']*100:.1f}%)")

    print(f"\n  NOTE: Model trained on English SMS dataset (UCI).")
    print(f"  Singlish/Sinhala messages are out-of-distribution.")
    print(f"  Future work: fine-tune with Sri Lankan SMS corpus.")
    print(f"{'=' * 70}")


if __name__ == '__main__':
    run_real_world_test()
