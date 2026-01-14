import re
from typing import Dict, List, Tuple
from dataclasses import dataclass
from enum import Enum

class SensitivityLevel(Enum):
    """Defines the severity level of detected sensitive data"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

@dataclass
class DLPDetection:
    """Represents a single DLP detection result"""
    pattern_name: str
    matched_text: str  # Partially masked version
    sensitivity: SensitivityLevel
    position: Tuple[int, int]  # Start and end position in text
    recommendation: str

class DLPDetector:
    """
    Data Loss Prevention Detector
    Scans text for sensitive information patterns
    """
    
    def __init__(self):
        # Define regex patterns for various sensitive data types
        self.patterns = {
            # Financial Information
            'credit_card': {
                'regex': r'\b(?:\d{4}[-\s]?){3}\d{4}\b',
                'sensitivity': SensitivityLevel.CRITICAL,
                'description': 'Credit Card Number',
                'recommendation': 'Never share credit card numbers via SMS, email, or messaging apps.'
            },
            
            # Sri Lankan National ID (Old: 9 digits + V/X, New: 12 digits)
            'national_id_lk': {
                'regex': r'\b\d{9}[VvXx]\b|\b\d{12}\b',
                'sensitivity': SensitivityLevel.HIGH,
                'description': 'Sri Lankan National ID',
                'recommendation': 'Avoid sharing your National ID number unless absolutely necessary.'
            },
            
            # International formats
            'ssn': {
                'regex': r'\b\d{3}-\d{2}-\d{4}\b',
                'sensitivity': SensitivityLevel.CRITICAL,
                'description': 'Social Security Number (US)',
                'recommendation': 'SSN should never be shared through unsecured channels.'
            },
            
            # Banking Information
            'iban': {
                'regex': r'\b[A-Z]{2}\d{2}[A-Z0-9]{1,30}\b',
                'sensitivity': SensitivityLevel.HIGH,
                'description': 'International Bank Account Number (IBAN)',
                'recommendation': 'Bank account numbers should only be shared through secure banking channels.'
            },
            
            'bank_account': {
                'regex': r'\b\d{8,18}\b',
                'sensitivity': SensitivityLevel.HIGH,
                'description': 'Possible Bank Account Number',
                'recommendation': 'Verify you\'re sharing this with a trusted recipient.'
            },
            
            # Personal Identifiable Information
            'email_bulk': {
                'regex': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
                'sensitivity': SensitivityLevel.MEDIUM,
                'description': 'Email Address',
                'recommendation': 'Be cautious when sharing email addresses with unknown parties.'
            },
            
            'phone_number': {
                'regex': r'\b(?:\+94|0)?[0-9]{9,10}\b',
                'sensitivity': SensitivityLevel.MEDIUM,
                'description': 'Phone Number',
                'recommendation': 'Ensure you trust the recipient before sharing phone numbers.'
            },
            
            # Authentication & Security
            'api_key': {
                'regex': r'\b[A-Za-z0-9_-]{32,}\b',
                'sensitivity': SensitivityLevel.CRITICAL,
                'description': 'Possible API Key or Token',
                'recommendation': 'API keys should NEVER be shared in messages. Revoke this key immediately if sent.'
            },
            
            'password_keyword': {
                'regex': r'\b(?:password|passwd|pwd|pass)[\s:=]+[^\s]{4,}\b',
                'sensitivity': SensitivityLevel.CRITICAL,
                'description': 'Password Detected',
                'recommendation': 'NEVER share passwords through any messaging platform!'
            },
            
            # Medical Information
            'medical_record': {
                'regex': r'\b(?:diagnosis|prescription|medical record|patient id)[\s:]+[^\s]+',
                'sensitivity': SensitivityLevel.HIGH,
                'description': 'Medical Information',
                'recommendation': 'Medical information is protected by privacy laws. Use secure healthcare portals.'
            },
            
            # Confidential Business Data
            'confidential_keyword': {
                'regex': r'\b(?:confidential|classified|secret|proprietary|internal only|do not share)\b',
                'sensitivity': SensitivityLevel.HIGH,
                'description': 'Confidential Content Marker',
                'recommendation': 'This message contains confidential markers. Verify recipient authorization.'
            },
            
            'salary_info': {
                'regex': r'\b(?:salary|compensation|pay)[\s:]+(?:Rs\.?|USD|\$|LKR)[\s]?[\d,]+',
                'sensitivity': SensitivityLevel.MEDIUM,
                'description': 'Salary/Financial Information',
                'recommendation': 'Salary information is sensitive. Ensure secure communication channel.'
            },
            
            # Date of Birth
            'dob': {
                'regex': r'\b(?:dob|date of birth|born on)[\s:]+\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b',
                'sensitivity': SensitivityLevel.MEDIUM,
                'description': 'Date of Birth',
                'recommendation': 'Date of birth combined with other info can lead to identity theft.'
            },
            
            # Passport Number
            'passport': {
                'regex': r'\b[A-Z]{1,2}\d{6,9}\b',
                'sensitivity': SensitivityLevel.HIGH,
                'description': 'Possible Passport Number',
                'recommendation': 'Passport numbers should be kept secure and shared only when necessary.'
            }
        }
    
    def mask_sensitive_data(self, text: str, start: int, end: int) -> str:
        """
        Masks sensitive data for display
        Shows first 2 and last 2 characters, masks middle
        """
        matched = text[start:end]
        if len(matched) <= 4:
            return '*' * len(matched)
        return matched[:2] + '*' * (len(matched) - 4) + matched[-2:]
    
    def scan_text(self, text: str) -> List[DLPDetection]:
        """
        Scans text for all sensitive data patterns
        Returns list of detections
        """
        detections = []
        
        for pattern_name, pattern_config in self.patterns.items():
            matches = re.finditer(pattern_config['regex'], text, re.IGNORECASE)
            
            for match in matches:
                # Create masked version for safe display
                masked_text = self.mask_sensitive_data(text, match.start(), match.end())
                
                detection = DLPDetection(
                    pattern_name=pattern_config['description'],
                    matched_text=masked_text,
                    sensitivity=pattern_config['sensitivity'],
                    position=(match.start(), match.end()),
                    recommendation=pattern_config['recommendation']
                )
                detections.append(detection)
        
        return detections
    
    def get_risk_score(self, detections: List[DLPDetection]) -> int:
        """
        Calculates overall risk score (0-100) based on detections
        """
        if not detections:
            return 0
        
        sensitivity_scores = {
            SensitivityLevel.LOW: 10,
            SensitivityLevel.MEDIUM: 25,
            SensitivityLevel.HIGH: 50,
            SensitivityLevel.CRITICAL: 100
        }
        
        # Get highest sensitivity score
        max_score = max([sensitivity_scores[d.sensitivity] for d in detections])
        
        # Add points for multiple detections
        detection_bonus = min(len(detections) * 5, 20)
        
        return min(max_score + detection_bonus, 100)
    
    def generate_summary(self, detections: List[DLPDetection]) -> Dict:
        """
        Generates a summary report of all detections
        """
        if not detections:
            return {
                'total_detections': 0,
                'risk_score': 0,
                'risk_level': 'SAFE',
                'message': 'No sensitive data detected.',
                'detections': []
            }
        
        risk_score = self.get_risk_score(detections)
        
        # Determine risk level
        if risk_score >= 75:
            risk_level = 'CRITICAL'
        elif risk_score >= 50:
            risk_level = 'HIGH'
        elif risk_score >= 25:
            risk_level = 'MEDIUM'
        else:
            risk_level = 'LOW'
        
        detection_list = []
        for detection in detections:
            detection_list.append({
                'type': detection.pattern_name,
                'masked_value': detection.matched_text,
                'sensitivity': detection.sensitivity.value,
                'recommendation': detection.recommendation
            })
        
        return {
            'total_detections': len(detections),
            'risk_score': risk_score,
            'risk_level': risk_level,
            'message': f'Warning: {len(detections)} sensitive data pattern(s) detected!',
            'detections': detection_list
        }


# Testing the DLP Detector
if __name__ == "__main__":
    detector = DLPDetector()
    
    # Test cases
    test_messages = [
        "My credit card is 4532-1234-5678-9010 please process payment",
        "Here's my account details: IBAN GB82WEST12345698765432",
        "My NIC is 199512345678 and phone is 0771234567",
        "Password: MySecretPass123! for the system",
        "This is confidential: Our salary budget is Rs. 5,000,000",
        "Contact me at john@example.com or +94771234567",
        "Just a normal message with no sensitive data",
        "My API key is fake_key_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    ]
    
    print("=" * 80)
    print("DLP DETECTOR - TEST RESULTS")
    print("=" * 80)
    
    for i, message in enumerate(test_messages, 1):
        print(f"\n--- Test Case {i} ---")
        print(f"Message: {message[:60]}{'...' if len(message) > 60 else ''}")
        
        detections = detector.scan_text(message)
        summary = detector.generate_summary(detections)
        
        print(f"\nRisk Level: {summary['risk_level']}")
        print(f"Risk Score: {summary['risk_score']}/100")
        print(f"Total Detections: {summary['total_detections']}")
        
        if detections:
            print(f"\nDetected Sensitive Data:")
            for detection in summary['detections']:
                print(f"  • {detection['type']}: {detection['masked_value']}")
                print(f"    Sensitivity: {detection['sensitivity'].upper()}")
                print(f"    ⚠️  {detection['recommendation']}\n")
        else:
            print("✓ No sensitive data detected - Safe to send!")
        
        print("-" * 80)