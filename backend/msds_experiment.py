"""
MSDS Experiment Runner
Compares MSDS vs Traditional Metrics
"""

import json
import os
from datetime import datetime

from msds_evaluator import MSDSEvaluator, DetectionResult
from msds_test_dataset import get_test_dataset, get_platform_distribution, print_dataset_summary
from dlp_detector import DLPDetector


def run_experiment():
    """Run MSDS evaluation experiment"""
    
    print("\n" + "="*60)
    print("🔬 MSDS EVALUATION EXPERIMENT")
    print("="*60)
    
    # Initialize
    evaluator = MSDSEvaluator()
    dlp_detector = DLPDetector()
    test_dataset = get_test_dataset()
    
    # Print dataset info
    print_dataset_summary()
    
    # Run evaluation
    print("Running DLP detection on test cases...\n")
    
    for i, test_case in enumerate(test_dataset, 1):
        # Get DLP detection result
        dlp_result = dlp_detector.analyze(test_case.message)
        
        # Convert to DetectionResult
        detection = DetectionResult(
            detected_sensitive=dlp_result['has_sensitive_data'],
            detected_categories=dlp_result.get('categories', []),
            sensitivity_level=dlp_result.get('sensitivity_level', 'none')
        )
        
        # Evaluate
        result = evaluator.evaluate_single(test_case, detection)
        
        # Print progress
        status = "✅" if result['correct'] else "❌"
        print(f"  [{i:02d}] {status} {result['result_type']:3} | {test_case.platform:8} | {test_case.message[:40]}...")
    
    # Generate report
    platform_dist = get_platform_distribution()
    report = evaluator.generate_report(platform_dist)
    
    # Print results
    print("\n" + "="*60)
    print("📊 RESULTS")
    print("="*60)
    
    print(f"\n📈 Summary:")
    print(f"   Total Tests:      {report['summary']['total_tests']}")
    print(f"   True Positives:   {report['summary']['true_positives']}")
    print(f"   True Negatives:   {report['summary']['true_negatives']}")
    print(f"   False Positives:  {report['summary']['false_positives']}")
    print(f"   False Negatives:  {report['summary']['false_negatives']}")
    
    print(f"\n📉 Traditional Metrics:")
    print(f"   Precision:  {report['traditional_metrics']['precision']}")
    print(f"   Recall:     {report['traditional_metrics']['recall']}")
    print(f"   F1 Score:   {report['traditional_metrics']['f1_score']}")
    print(f"   Accuracy:   {report['traditional_metrics']['accuracy']}")
    
    print(f"\n🎯 MSDS Components:")
    print(f"   Context Weight (Cw):   {report['msds_components']['context_weight']}")
    print(f"   Platform Factor (Pf):  {report['msds_components']['platform_factor']}")
    print(f"   Context Penalty (Cp):  {report['msds_components']['context_penalty']}")

    # Per-platform breakdown
    print(f"\n📱 Per-Platform Metrics:")
    print(f"   {'Platform':<12} {'Accuracy':>10} {'Precision':>10} {'Recall':>10} {'F1':>10} {'Tests':>6}")
    print(f"   {'-'*60}")
    for platform, metrics in report.get('platform_metrics', {}).items():
        print(f"   {platform:<12} "
              f"{metrics['accuracy']:>8.4f}  "
              f"{metrics['precision']:>8.4f}  "
              f"{metrics['recall']:>8.4f}  "
              f"{metrics['f1_score']:>8.4f}  "
              f"{metrics['total']:>4}")

    print(f"\n" + "="*60)
    print(f"🏆 FINAL SCORES")
    print(f"="*60)
    print(f"   F1 Score:    {report['comparison']['f1_score']}")
    print(f"   MSDS Score:  {report['comparison']['msds_score']}")
    print(f"   Difference:  {report['comparison']['difference']}")
    print(f"\n   💡 Insight: {report['comparison']['msds_insight']}")
    print("="*60)
    
    # Save report to file
    os.makedirs('results', exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = f"results/msds_report_{timestamp}.json"
    
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f"\n📁 Report saved to: {report_path}")
    
    return report


if __name__ == "__main__":
    run_experiment()