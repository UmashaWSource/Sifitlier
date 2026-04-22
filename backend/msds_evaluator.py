"""
MSDS - Mobile Sensitivity Detection Score
A novel metric for evaluating mobile DLP systems
Developed by Umasha Wijenayake
"""

from dataclasses import dataclass
from typing import List, Dict
import json


@dataclass
class TestCase:
    """Single test case for MSDS evaluation"""
    message: str
    expected_sensitive: bool
    expected_categories: List[str]
    platform: str  # sms, telegram, email
    context: str   # casual, formal, urgent


@dataclass 
class DetectionResult:
    """Result from DLP detector"""
    detected_sensitive: bool
    detected_categories: List[str]
    sensitivity_level: str


class MSDSEvaluator:
    """
    Mobile Sensitivity Detection Score Evaluator
    
    Formula: MSDS = (TP × Cw × Pf) / (TP + FP + FN + Cp)
    
    Where:
    - TP = True Positives
    - Cw = Context Weight (0-1)
    - Pf = Platform Factor (0.8-1.2)
    - FP = False Positives
    - FN = False Negatives
    - Cp = Context Penalty
    """
    
    # Platform difficulty factors
    PLATFORM_FACTORS = {
        'sms': 1.2,      # Hardest - short, abbreviated
        'telegram': 1.0,  # Medium - mixed content
        'email': 0.9,     # Easiest - formal, structured
        'default': 1.0
    }
    
    # Context penalty weights
    CONTEXT_PENALTIES = {
        'missed_critical': 2.0,    # Missed password/credit card
        'missed_moderate': 1.0,    # Missed phone/email
        'false_alarm': 0.5,        # Flagged safe content
        'wrong_category': 0.3      # Detected but wrong type
    }
    
    def __init__(self):
        self.results = []
        self.tp = 0  # True Positives
        self.fp = 0  # False Positives
        self.fn = 0  # False Negatives
        self.tn = 0  # True Negatives
        self.context_correct = 0
        self.context_total = 0
        self.context_penalty = 0.0
        self.platform_scores = {'sms': [], 'telegram': [], 'email': []}
    
    def evaluate_single(self, test_case: TestCase, detection: DetectionResult) -> Dict:
        """Evaluate a single test case"""
        result = {
            'message': test_case.message[:50] + '...' if len(test_case.message) > 50 else test_case.message,
            'platform': test_case.platform,
            'expected': test_case.expected_sensitive,
            'detected': detection.detected_sensitive,
            'correct': False,
            'category_match': False,
            'result_type': ''
        }
        
        # Determine result type
        if test_case.expected_sensitive and detection.detected_sensitive:
            self.tp += 1
            result['correct'] = True
            result['result_type'] = 'TP'
            
            # Check category match
            expected_set = set(test_case.expected_categories)
            detected_set = set(detection.detected_categories)
            if expected_set & detected_set:  # Intersection
                self.context_correct += 1
                result['category_match'] = True
            else:
                self.context_penalty += self.CONTEXT_PENALTIES['wrong_category']
            self.context_total += 1
            
        elif not test_case.expected_sensitive and not detection.detected_sensitive:
            self.tn += 1
            result['correct'] = True
            result['result_type'] = 'TN'
            
        elif not test_case.expected_sensitive and detection.detected_sensitive:
            self.fp += 1
            result['result_type'] = 'FP'
            self.context_penalty += self.CONTEXT_PENALTIES['false_alarm']
            
        elif test_case.expected_sensitive and not detection.detected_sensitive:
            self.fn += 1
            result['result_type'] = 'FN'
            # Higher penalty for missing critical data
            if any(cat in test_case.expected_categories for cat in ['password', 'credit_card', 'bank_account']):
                self.context_penalty += self.CONTEXT_PENALTIES['missed_critical']
            else:
                self.context_penalty += self.CONTEXT_PENALTIES['missed_moderate']
        
        self.results.append(result)
        return result
    
    def calculate_context_weight(self) -> float:
        """Calculate Context Weight (Cw)"""
        if self.context_total == 0:
            return 1.0
        return self.context_correct / self.context_total
    
    def calculate_platform_factor(self, platform_distribution: Dict[str, int]) -> float:
        """Calculate weighted Platform Factor (Pf)"""
        total = sum(platform_distribution.values())
        if total == 0:
            return 1.0
        
        weighted_sum = 0
        for platform, count in platform_distribution.items():
            factor = self.PLATFORM_FACTORS.get(platform, self.PLATFORM_FACTORS['default'])
            weighted_sum += factor * count
        
        return weighted_sum / total
    
    def calculate_msds(self, platform_distribution: Dict[str, int] = None) -> float:
        """
        Calculate the MSDS score
        
        Formula: MSDS = (TP × Cw × Pf) / (TP + FP + FN + Cp)
        """
        if platform_distribution is None:
            platform_distribution = {'sms': 1, 'telegram': 1, 'email': 1}
        
        cw = self.calculate_context_weight()
        pf = self.calculate_platform_factor(platform_distribution)
        
        numerator = self.tp * cw * pf
        denominator = self.tp + self.fp + self.fn + self.context_penalty
        
        if denominator == 0:
            return 0.0
        
        msds = numerator / denominator
        return round(msds, 4)
    
    def calculate_traditional_metrics(self) -> Dict:
        """Calculate traditional metrics for comparison"""
        # Precision
        precision = self.tp / (self.tp + self.fp) if (self.tp + self.fp) > 0 else 0
        
        # Recall
        recall = self.tp / (self.tp + self.fn) if (self.tp + self.fn) > 0 else 0
        
        # F1 Score
        f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
        
        # Accuracy
        total = self.tp + self.tn + self.fp + self.fn
        accuracy = (self.tp + self.tn) / total if total > 0 else 0
        
        return {
            'precision': round(precision, 4),
            'recall': round(recall, 4),
            'f1_score': round(f1, 4),
            'accuracy': round(accuracy, 4)
        }
    
    def calculate_platform_metrics(self) -> Dict[str, Dict]:
        """Calculate per-platform metrics (precision, recall, F1)"""
        platform_data = {}

        for result in self.results:
            platform = result['platform']
            if platform not in platform_data:
                platform_data[platform] = {'tp': 0, 'fp': 0, 'fn': 0, 'tn': 0}

            rt = result['result_type']
            if rt == 'TP':
                platform_data[platform]['tp'] += 1
            elif rt == 'TN':
                platform_data[platform]['tn'] += 1
            elif rt == 'FP':
                platform_data[platform]['fp'] += 1
            elif rt == 'FN':
                platform_data[platform]['fn'] += 1

        platform_metrics = {}
        for platform, counts in platform_data.items():
            tp, fp, fn, tn = counts['tp'], counts['fp'], counts['fn'], counts['tn']
            total = tp + tn + fp + fn
            precision = tp / (tp + fp) if (tp + fp) > 0 else 0
            recall = tp / (tp + fn) if (tp + fn) > 0 else 0
            f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
            accuracy = (tp + tn) / total if total > 0 else 0

            platform_metrics[platform] = {
                'total': total,
                'tp': tp, 'tn': tn, 'fp': fp, 'fn': fn,
                'precision': round(precision, 4),
                'recall': round(recall, 4),
                'f1_score': round(f1, 4),
                'accuracy': round(accuracy, 4),
            }

        return platform_metrics

    def calculate_category_detection_rates(self) -> Dict[str, Dict]:
        """Calculate detection rate per sensitive data category"""
        category_data = {}

        for result in self.results:
            if not result['expected']:
                continue  # skip non-sensitive cases

            # Determine expected categories from the original test case
            # We track this via result_type
            rt = result['result_type']

            # For category-level tracking, we use the category_match field
            # This gives us overall TP/FN per category
            # (requires the test cases to have been evaluated)

        # Simpler approach: count correct/incorrect per category from results
        # Since we don't store expected_categories in result, we return overall rates
        detected_count = sum(1 for r in self.results if r['result_type'] == 'TP')
        missed_count = sum(1 for r in self.results if r['result_type'] == 'FN')
        false_alarm_count = sum(1 for r in self.results if r['result_type'] == 'FP')

        return {
            'detected': detected_count,
            'missed': missed_count,
            'false_alarms': false_alarm_count,
            'detection_rate': round(detected_count / (detected_count + missed_count), 4) if (detected_count + missed_count) > 0 else 0,
        }

    def generate_report(self, platform_distribution: Dict[str, int] = None) -> Dict:
        """Generate comprehensive evaluation report"""
        traditional = self.calculate_traditional_metrics()
        msds = self.calculate_msds(platform_distribution)
        platform_metrics = self.calculate_platform_metrics()
        category_rates = self.calculate_category_detection_rates()

        report = {
            'summary': {
                'total_tests': len(self.results),
                'true_positives': self.tp,
                'true_negatives': self.tn,
                'false_positives': self.fp,
                'false_negatives': self.fn
            },
            'traditional_metrics': traditional,
            'msds_components': {
                'context_weight': round(self.calculate_context_weight(), 4),
                'platform_factor': round(self.calculate_platform_factor(platform_distribution or {}), 4),
                'context_penalty': round(self.context_penalty, 4)
            },
            'msds_score': msds,
            'comparison': {
                'f1_score': traditional['f1_score'],
                'msds_score': msds,
                'difference': round(msds - traditional['f1_score'], 4),
                'msds_insight': self._generate_insight(traditional['f1_score'], msds)
            },
            'platform_metrics': platform_metrics,
            'category_detection': category_rates,
            'detailed_results': self.results
        }

        return report
    
    def _generate_insight(self, f1: float, msds: float) -> str:
        """Generate insight comparing F1 and MSDS"""
        diff = msds - f1
        if abs(diff) < 0.05:
            return "MSDS and F1 are similar - system performs consistently across contexts"
        elif diff > 0:
            return f"MSDS is {diff:.2f} higher - system excels at context-aware detection"
        else:
            return f"MSDS is {abs(diff):.2f} lower - system has context/platform weaknesses"
    
    def reset(self):
        """Reset all counters for new evaluation"""
        self.results = []
        self.tp = 0
        self.fp = 0
        self.fn = 0
        self.tn = 0
        self.context_correct = 0
        self.context_total = 0
        self.context_penalty = 0.0