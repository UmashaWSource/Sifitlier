"""
Quick Test Script for DLP Detector
Run this to verify your DLP detector is working correctly
"""

from dlp_detector import DLPDetector

def print_separator():
    print("\n" + "="*80 + "\n")

def test_dlp_detector():
    """
    Comprehensive test suite for DLP detector
    """
    print("🔍 SIFITLIER DLP DETECTOR - TEST SUITE")
    print_separator()
    
    detector = DLPDetector()
    
    # Test cases with expected results
    test_cases = [
        {
            "name": "Credit Card Detection",
            "text": "Please charge my card 4532-1234-5678-9010 for the purchase",
            "expected_detections": ["Credit Card Number"],
            "expected_risk": "CRITICAL"
        },
        {
            "name": "Sri Lankan NIC (Old Format)",
            "text": "My NIC is 912345678V",
            "expected_detections": ["Sri Lankan National ID"],
            "expected_risk": "HIGH"
        },
        {
            "name": "Sri Lankan NIC (New Format)",
            "text": "Here is my new NIC: 199123456789",
            "expected_detections": ["Sri Lankan National ID"],
            "expected_risk": "HIGH"
        },
        {
            "name": "Phone Number",
            "text": "Call me at 0771234567 or +94771234567",
            "expected_detections": ["Phone Number"],
            "expected_risk": "MEDIUM"
        },
        {
            "name": "Email Address",
            "text": "Send it to john.doe@example.com",
            "expected_detections": ["Email Address"],
            "expected_risk": "MEDIUM"
        },
        {
            "name": "Password Detection",
            "text": "Your password: MySecretPass123! for login",
            "expected_detections": ["Password Detected"],
            "expected_risk": "CRITICAL"
        },
        {
            "name": "Bank Account",
            "text": "Transfer to account 1234567890123456",
            "expected_detections": ["Possible Bank Account Number"],
            "expected_risk": "HIGH"
        },
        {
            "name": "Confidential Content",
            "text": "This is confidential information about our salary structure",
            "expected_detections": ["Confidential Content Marker"],
            "expected_risk": "HIGH"
        },
        {
            "name": "Multiple Sensitive Data",
            "text": "My details: NIC 199512345678, phone 0771234567, email test@gmail.com, card 4532123456789010",
            "expected_detections": ["Sri Lankan National ID", "Phone Number", "Email Address", "Credit Card Number"],
            "expected_risk": "CRITICAL"
        },
        {
            "name": "Safe Message",
            "text": "Let's meet tomorrow at 3pm for coffee",
            "expected_detections": [],
            "expected_risk": "SAFE"
        }
    ]
    
    passed = 0
    failed = 0
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"Test Case {i}: {test_case['name']}")
        print("-" * 80)
        print(f"Input: {test_case['text'][:60]}{'...' if len(test_case['text']) > 60 else ''}")
        
        # Perform scan
        detections = detector.scan_text(test_case['text'])
        summary = detector.generate_summary(detections)
        
        # Check results
        detected_types = [d.pattern_name for d in detections]
        risk_level = summary['risk_level']
        
        print(f"\n✓ Risk Level: {risk_level}")
        print(f"✓ Risk Score: {summary['risk_score']}/100")
        print(f"✓ Detections: {len(detections)}")
        
        if detections:
            for detection in detections:
                print(f"  • {detection.pattern_name}: {detection.matched_text}")
        else:
            print("  • No sensitive data detected")
        
        # Verify expectations
        test_passed = True
        
        if risk_level != test_case['expected_risk']:
            print(f"\n⚠️  Expected risk: {test_case['expected_risk']}, Got: {risk_level}")
            test_passed = False
        
        # Check if we found the expected detection types
        if test_case['expected_detections']:
            found_all = all(
                any(expected in detected for detected in detected_types)
                for expected in test_case['expected_detections']
            )
            if not found_all:
                print(f"⚠️  Expected detections: {test_case['expected_detections']}")
                print(f"   Got: {detected_types}")
                test_passed = False
        
        if test_passed:
            print("\n✅ TEST PASSED")
            passed += 1
        else:
            print("\n❌ TEST FAILED")
            failed += 1
        
        print_separator()
    
    # Summary
    print("📊 TEST SUMMARY")
    print("=" * 80)
    print(f"Total Tests: {len(test_cases)}")
    print(f"✅ Passed: {passed}")
    print(f"❌ Failed: {failed}")
    print(f"Success Rate: {(passed/len(test_cases)*100):.1f}%")
    print_separator()
    
    # Performance test
    print("⚡ PERFORMANCE TEST")
    print("-" * 80)
    
    import time
    
    long_text = """
    This is a longer message with multiple sensitive elements.
    Credit card: 4532-1234-5678-9010
    NIC: 199512345678
    Phone: 0771234567
    Email: test@example.com
    Password: SecretPass123!
    Account: 1234567890123456
    This message also contains confidential salary information of Rs. 150,000
    and should be flagged as high risk.
    """ * 10  # Repeat to make it longer
    
    start_time = time.time()
    for _ in range(100):  # Scan 100 times
        detector.scan_text(long_text)
    end_time = time.time()
    
    avg_time = (end_time - start_time) / 100 * 1000  # Convert to ms
    
    print(f"Average scan time: {avg_time:.2f}ms")
    print(f"Scans per second: {1000/avg_time:.0f}")
    
    if avg_time < 50:
        print("✅ Performance: Excellent")
    elif avg_time < 100:
        print("✅ Performance: Good")
    else:
        print("⚠️  Performance: Needs optimization")
    
    print_separator()
    
    # Pattern coverage test
    print("📋 PATTERN COVERAGE")
    print("-" * 80)
    print(f"Total patterns configured: {len(detector.patterns)}")
    print("\nSupported detection types:")
    for pattern_name, config in detector.patterns.items():
        print(f"  • {config['description']} ({config['sensitivity'].value})")
    
    print_separator()
    print("✅ All tests completed!")

if __name__ == "__main__":
    test_dlp_detector()