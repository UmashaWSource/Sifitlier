"""
Retrain spam classifier with combined UCI + Sri Lankan dataset.
Then evaluate on real-world Sri Lankan messages.
"""

import os
import pandas as pd
from train_spam_classifier import (
    SpamClassifier, load_dataset, print_confusion_matrix
)
from sklearn.model_selection import train_test_split


def retrain():
    print("=" * 70)
    print("  RETRAINING WITH COMBINED UCI + SRI LANKAN DATA")
    print("=" * 70)

    # Load UCI dataset
    print("\n>>> 1. Loading UCI SMS dataset...")
    df_uci = load_dataset('spam.csv')
    print(f"   UCI: {len(df_uci)} messages")

    # Load SL dataset
    print("\n>>> 2. Loading Sri Lankan SMS dataset...")
    if not os.path.exists('sri_lankan_sms.csv'):
        print("   Generating SL dataset first...")
        from sri_lankan_sms_dataset import save_dataset
        save_dataset()

    df_sl = pd.read_csv('sri_lankan_sms.csv')
    print(f"   SL:  {len(df_sl)} messages")

    # Combine
    df_combined = pd.concat([df_uci, df_sl], ignore_index=True)
    df_combined = df_combined.sample(frac=1, random_state=42).reset_index(drop=True)
    print(f"\n>>> 3. Combined dataset: {len(df_combined)} messages")
    print(f"   {df_combined['label'].value_counts().to_dict()}")

    # Split
    X_train, X_test, y_train, y_test = train_test_split(
        df_combined['message'].tolist(),
        df_combined['label'].tolist(),
        test_size=0.2,
        random_state=42,
        stratify=df_combined['label']
    )
    print(f"\n>>> 4. Split: Train={len(X_train)} | Test={len(X_test)}")

    # Cross-validate
    print("\n>>> 5. Cross-validation (5-fold)...")
    classifier = SpamClassifier()
    cv = classifier.cross_validate(
        df_combined['message'].tolist(),
        df_combined['label'].tolist(),
        k=5, model_type='logistic_regression'
    )
    print(f"   CV Accuracy:  {cv['accuracy_mean']:.4f} (+/- {cv['accuracy_std']:.4f})")
    print(f"   CV F1:        {cv['f1_mean']:.4f} (+/- {cv['f1_std']:.4f})")

    # Train
    print("\n>>> 6. Training final model...")
    metrics = classifier.train(X_train, y_train, model_type='logistic_regression')
    print(f"   Train Accuracy: {metrics['accuracy']:.4f}")
    print(f"   Train F1:       {metrics['f1']:.4f}")

    # Evaluate on test split
    print("\n>>> 7. Test set evaluation...")
    test_metrics = classifier.evaluate(X_test, y_test)
    print(f"   Test Accuracy:  {test_metrics['accuracy']:.4f}")
    print(f"   Test Precision: {test_metrics['precision']:.4f}")
    print(f"   Test Recall:    {test_metrics['recall']:.4f}")
    print(f"   Test F1:        {test_metrics['f1']:.4f}")
    print_confusion_matrix(test_metrics['confusion_matrix'], test_metrics['cm_labels'])

    # Save model
    print(">>> 8. Saving model...")
    classifier.save('spam_classifier_pipeline.pkl')

    # Real-world test
    print("\n>>> 9. Real-world Sri Lankan SMS test...")
    real_tests = [
        ("Rs.100 000 k dakwa nayak kalin anumatha kara aetha! Salli ganna: https://f1na.com/FtgcvRB", "spam"),
        ("250.000 LKR rin - wadiya honda 0.01%! Danma balanna: https://f1na.com/HxFUFwi", "spam"),
        ("Samsung A06 smartphone එකක් රු.15,160/-ක් ගෙවා අරගෙන යන්න!", "spam"),
        ("Dialog: Activate Rs.99 YouTube pack! Unlimited YouTube for 30 days. Dial #678*99#", "spam"),
        ("Mobitel: Reload Rs.200 and get 2GB bonus data FREE! Valid for 7 days.", "spam"),
        ("It's MEGA MONDAY! Buy any Large Pizza & get 50% OFF. Visit or call 0112729729. Pizza Hut", "spam"),
        ("Enjoy 50% OFF Cyber Deal at Chinese Dragon Cafe on Dolphin Rice! Order Now", "spam"),
        ("Enjoy 20% OFF on Fresh Vegetables @ Softlogic GLOMARK with SAMPATH Debit Cards", "spam"),
        ("Predict on T20 matches & Win power banks from ESOFT UNI.", "spam"),
        ("Power Up with ESOFT, Fast-Track your Career After O/Ls.", "spam"),
        ("Vegavat saha pahasu! 0.01% poliyata rupiyal 120 000 dakva naya https://f1na.com/pdoZ4c0", "spam"),
        ("Your Uber is arriving now. Driver: Kasun, Vehicle: WP-CAB-1234", "ham"),
        ("PickMe: Your ride request has been accepted. Arriving in 5 mins.", "ham"),
        ("Daraz: Your order #LK24789 has been shipped. Track: daraz.lk/track", "ham"),
        ("Keells: Your bill is Rs.3,450. You earned 34 Nexus points. Thank you!", "ham"),
        ("BOC: Your account XX1234 has been credited with Rs.50,000.00 on 18/03/2025", "ham"),
        ("Sampath Bank: Your credit card ending 9876 was charged Rs.12,500 at Dialog.", "ham"),
        ("HNB: Your fixed deposit of Rs.500,000 matures on 25/03/2025.", "ham"),
        ("oya exam eka kohomada? mage hondai", "ham"),
        ("machang 6.30 ta ena. late unoth call karanna", "ham"),
        ("Lab cancelled tomorrow. Check LMS for assignment details.", "ham"),
        ("Hey can you send me the notes from yesterday's lecture?", "ham"),
        ("Happy birthday! Hope you have an amazing day!", "ham"),
        ("Mom wants to know if you're coming for dinner Sunday", "ham"),
        ("Since the Grama Niladhari will not be visiting houses, please contact him only if there are amendments.", "ham"),
        ("Pizza Hut: Order confirmed! Delivery in 30-45 mins. Ref: PH20241234", "ham"),
        ("BOC: Your OTP is 391847. Valid for 3 mins. Do NOT share.", "ham"),
        ("NIC Office: Your new NIC is ready for collection.", "ham"),
    ]

    correct = 0
    total = len(real_tests)
    print(f"\n   Testing {total} real-world messages:\n")

    for msg, expected in real_tests:
        result = classifier.predict(msg)
        ok = result['label'] == expected
        if ok:
            correct += 1
        status = "PASS" if ok else "FAIL"
        print(f"   {status} [{result['label'].upper():4s} {result['spam_probability']*100:5.1f}%] {msg[:60]}...")
        if not ok:
            print(f"         Expected: {expected}")

    accuracy = correct / total * 100
    print(f"\n   Real-world accuracy: {correct}/{total} ({accuracy:.1f}%)")

    # Export for Flutter
    print("\n>>> 10. Exporting model for Flutter...")
    from export_model import export_model
    export_model()

    print("\n" + "=" * 70)
    print(f"  DONE! Combined model: {len(df_combined)} training messages")
    print(f"  Test accuracy: {test_metrics['accuracy']:.4f}")
    print(f"  Real-world accuracy: {accuracy:.1f}%")
    print("=" * 70)


if __name__ == '__main__':
    retrain()
