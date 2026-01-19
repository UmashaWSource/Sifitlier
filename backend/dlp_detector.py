"""
dlp_detector.py
===============

Data Loss Prevention (DLP) Detector for Sifitlier
Detects sensitive data in outgoing messages (SMS, Email, Telegram)

Classes:
    - SensitivityLevel: Enum for sensitivity levels
    - DLPDetector: Main detector class

Usage:
    from dlp_detector import DLPDetector, SensitivityLevel
    
    detector = DLPDetector()
    result = detector.analyze("My credit card is 4532015112830366")
    
    if result['has_sensitive_data']:
        print(f"Warning: {result['sensitivity_level']} sensitivity detected!")
        print(f"Categories: {result['categories']}")
"""

import re
from enum import Enum
from typing import Dict, Any, List, Tuple, Optional
from dataclasses import dataclass


class SensitivityLevel(str, Enum):
    """Sensitivity levels for detected data"""
    CRITICAL = "critical"   # Credit cards, SSN, passwords
    HIGH = "high"           # Bank accounts, medical info
    MEDIUM = "medium"       # Phone numbers, addresses
    LOW = "low"             # Emails, names
    NONE = "none"           # No sensitive data


@dataclass
class SensitiveMatch:
    """Represents a detected sensitive data match"""
    category: str
    pattern_name: str
    matched_text: str
    masked_text: str
    sensitivity: SensitivityLevel
    start_pos: int
    end_pos: int
    confidence: float


class DLPDetector:
    """
    Data Loss Prevention Detector.
    
    Analyzes text for sensitive information and provides:
    - Detection of multiple sensitive data types
    - Sensitivity level classification
    - Masked/redacted text output
    - Recommendations for users
    
    Sensitive Data Categories:
    - Financial: Credit cards, bank accounts, IBAN
    - Identity: SSN, NRIC, passport numbers
    - Authentication: Passwords, PINs, API keys
    - Personal: Phone numbers, email addresses
    - Medical: Medical record numbers, health info
    """
    
    def __init__(self):
        self._init_patterns()
    
    def _init_patterns(self):
        """Initialize all detection patterns"""
        
        # Pattern format: (regex, description, sensitivity, confidence)
        self.patterns: Dict[str, List[Tuple[str, str, SensitivityLevel, float]]] = {
            
            # ============== FINANCIAL ==============
            "credit_card": [
                # Visa
                (r'\b4[0-9]{3}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}\b',
                 "Visa card", SensitivityLevel.CRITICAL, 0.95),
                # MasterCard
                (r'\b5[1-5][0-9]{2}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}\b',
                 "MasterCard", SensitivityLevel.CRITICAL, 0.95),
                # American Express
                (r'\b3[47][0-9]{2}[-\s]?[0-9]{6}[-\s]?[0-9]{5}\b',
                 "American Express", SensitivityLevel.CRITICAL, 0.95),
                # Discover
                (r'\b6(?:011|5[0-9]{2})[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}\b',
                 "Discover card", SensitivityLevel.CRITICAL, 0.95),
                # Generic 16-digit
                (r'\b[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}\b',
                 "Credit card number", SensitivityLevel.CRITICAL, 0.70),
            ],
            
            "bank_account": [
                # IBAN (International)
                (r'\b[A-Z]{2}[0-9]{2}[A-Z0-9]{4}[0-9]{7}([A-Z0-9]?){0,16}\b',
                 "IBAN", SensitivityLevel.HIGH, 0.95),
                # Account with context
                (r'(?i)(?:account|acct|a/c)[\s:#]*([0-9]{8,17})',
                 "Bank account number", SensitivityLevel.HIGH, 0.85),
                # Routing number with context
                (r'(?i)(?:routing|rtg|aba)[\s:#]*([0-9]{9})',
                 "Bank routing number", SensitivityLevel.HIGH, 0.90),
                # SWIFT/BIC code
                (r'\b[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?\b',
                 "SWIFT/BIC code", SensitivityLevel.HIGH, 0.80),
            ],
            
            "cvv": [
                # CVV with context
                (r'(?i)(?:cvv|cvc|cvv2|cvc2|security\s*code)[\s:]*([0-9]{3,4})',
                 "Card security code (CVV)", SensitivityLevel.CRITICAL, 0.95),
            ],
            
            # ============== IDENTITY ==============
            "ssn": [
                # US Social Security Number
                (r'\b[0-9]{3}[-\s][0-9]{2}[-\s][0-9]{4}\b',
                 "Social Security Number", SensitivityLevel.CRITICAL, 0.95),
                # SSN with context
                (r'(?i)(?:ssn|social\s*security)[\s:#]*([0-9]{3}[-\s]?[0-9]{2}[-\s]?[0-9]{4})',
                 "SSN", SensitivityLevel.CRITICAL, 0.98),
            ],
            
            "nric": [
                # Singapore NRIC/FIN
                (r'\b[STFGM][0-9]{7}[A-Z]\b',
                 "Singapore NRIC/FIN", SensitivityLevel.CRITICAL, 0.95),
                # Malaysia IC
                (r'\b[0-9]{6}[-\s]?[0-9]{2}[-\s]?[0-9]{4}\b',
                 "Malaysia IC", SensitivityLevel.CRITICAL, 0.80),
            ],
            
            "passport": [
                # Generic passport with context
                (r'(?i)passport[\s:#]*([A-Z]{1,2}[0-9]{6,9})',
                 "Passport number", SensitivityLevel.HIGH, 0.85),
            ],
            
            "drivers_license": [
                # With context
                (r'(?i)(?:driver\'?s?\s*license|dl|license\s*#?)[\s:#]*([A-Z0-9]{5,15})',
                 "Driver's license", SensitivityLevel.HIGH, 0.80),
            ],
            
            # ============== AUTHENTICATION ==============
            "password": [
                # Password with context
                (r'(?i)password[\s:=]+\S+',
                 "Password", SensitivityLevel.CRITICAL, 0.95),
                (r'(?i)(?:pwd|passwd)[\s:=]+\S+',
                 "Password", SensitivityLevel.CRITICAL, 0.90),
                (r'(?i)pass[\s:=]+\S{6,}',
                 "Password", SensitivityLevel.CRITICAL, 0.80),
            ],
            
            "pin": [
                # PIN with context
                (r'(?i)(?:pin|pin\s*code|pin\s*number)[\s:=]+[0-9]{4,6}',
                 "PIN code", SensitivityLevel.CRITICAL, 0.95),
            ],
            
            "api_key": [
                # API keys
                (r'(?i)api[_-]?key[\s:=]+[A-Za-z0-9_\-]{20,}',
                 "API Key", SensitivityLevel.CRITICAL, 0.95),
                (r'(?i)secret[_-]?key[\s:=]+[A-Za-z0-9_\-]{20,}',
                 "Secret Key", SensitivityLevel.CRITICAL, 0.95),
                (r'(?i)access[_-]?token[\s:=]+[A-Za-z0-9_\-]{20,}',
                 "Access Token", SensitivityLevel.CRITICAL, 0.95),
                # Bearer tokens
                (r'(?i)bearer[\s]+[A-Za-z0-9_\-\.]{20,}',
                 "Bearer Token", SensitivityLevel.CRITICAL, 0.90),
                # AWS keys
                (r'AKIA[0-9A-Z]{16}',
                 "AWS Access Key", SensitivityLevel.CRITICAL, 0.98),
            ],
            
            # ============== PERSONAL ==============
            "phone": [
                # International format
                (r'\+[1-9][0-9]{0,2}[-\s]?[0-9]{8,14}',
                 "Phone number (international)", SensitivityLevel.MEDIUM, 0.85),
                # US format
                (r'\b\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b',
                 "Phone number (US)", SensitivityLevel.MEDIUM, 0.80),
                # Generic 10+ digits
                (r'(?i)(?:phone|mobile|cell|tel)[\s:#]*([0-9\-\s]{10,})',
                 "Phone number", SensitivityLevel.MEDIUM, 0.85),
            ],
            
            "email": [
                # Standard email
                (r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
                 "Email address", SensitivityLevel.LOW, 0.95),
            ],
            
            "address": [
                # Street address with context
                (r'(?i)(?:address|street|avenue|road|blvd|lane)[\s:#]*[0-9]+\s+[A-Za-z\s]+',
                 "Physical address", SensitivityLevel.MEDIUM, 0.70),
            ],
            
            "dob": [
                # Date of birth with context
                (r'(?i)(?:dob|date\s*of\s*birth|born|birthday)[\s:]+[0-9]{1,2}[/\-][0-9]{1,2}[/\-][0-9]{2,4}',
                 "Date of birth", SensitivityLevel.MEDIUM, 0.90),
            ],
            
            # ============== MEDICAL ==============
            "medical": [
                # Medical record number
                (r'(?i)(?:mrn|medical\s*record|patient\s*id)[\s:#]*[A-Z0-9]{6,}',
                 "Medical record number", SensitivityLevel.HIGH, 0.90),
                # Health information keywords
                (r'(?i)(?:diagnosis|prescription|medication)[\s:]+[A-Za-z\s]+',
                 "Health information", SensitivityLevel.HIGH, 0.70),
            ],
            
            # ============== IP/NETWORK ==============
            "ip_address": [
                # IPv4
                (r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b',
                 "IP Address (IPv4)", SensitivityLevel.MEDIUM, 0.90),
                # IPv6 (simplified)
                (r'\b(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\b',
                 "IP Address (IPv6)", SensitivityLevel.MEDIUM, 0.90),
            ],
        }
        
        # Category to sensitivity mapping for summary
        self.category_sensitivity = {
            "credit_card": SensitivityLevel.CRITICAL,
            "cvv": SensitivityLevel.CRITICAL,
            "ssn": SensitivityLevel.CRITICAL,
            "nric": SensitivityLevel.CRITICAL,
            "password": SensitivityLevel.CRITICAL,
            "pin": SensitivityLevel.CRITICAL,
            "api_key": SensitivityLevel.CRITICAL,
            "bank_account": SensitivityLevel.HIGH,
            "passport": SensitivityLevel.HIGH,
            "drivers_license": SensitivityLevel.HIGH,
            "medical": SensitivityLevel.HIGH,
            "phone": SensitivityLevel.MEDIUM,
            "address": SensitivityLevel.MEDIUM,
            "dob": SensitivityLevel.MEDIUM,
            "ip_address": SensitivityLevel.MEDIUM,
            "email": SensitivityLevel.LOW,
        }
    
    def analyze(self, text: str) -> Dict[str, Any]:
        """
        Analyze text for sensitive data.
        
        Args:
            text: The text to analyze
            
        Returns:
            Dictionary containing:
            - has_sensitive_data: bool
            - sensitivity_level: str (overall)
            - total_matches: int
            - categories: list of category names
            - matches: list of match details
            - recommendation: str
        """
        matches: List[Dict[str, Any]] = []
        categories_found: set = set()
        highest_sensitivity = SensitivityLevel.NONE
        
        for category, patterns in self.patterns.items():
            for pattern, description, sensitivity, confidence in patterns:
                for match in re.finditer(pattern, text, re.IGNORECASE):
                    matched_text = match.group()
                    
                    # Additional validation for credit cards
                    if category == "credit_card" and not self._validate_luhn(matched_text):
                        confidence *= 0.5
                        if confidence < 0.5:
                            continue
                    
                    # Create masked version
                    masked = self._mask_text(matched_text, category)
                    
                    matches.append({
                        "category": category,
                        "description": description,
                        "matched_text": matched_text,
                        "masked_text": masked,
                        "sensitivity": sensitivity.value,
                        "confidence": round(confidence, 2),
                        "position": {
                            "start": match.start(),
                            "end": match.end()
                        }
                    })
                    
                    categories_found.add(category)
                    
                    # Track highest sensitivity
                    if self._sensitivity_rank(sensitivity) > self._sensitivity_rank(highest_sensitivity):
                        highest_sensitivity = sensitivity
        
        # Remove duplicates (same position)
        matches = self._deduplicate_matches(matches)
        
        # Generate recommendation
        recommendation = self._generate_recommendation(highest_sensitivity, list(categories_found))
        
        return {
            "has_sensitive_data": len(matches) > 0,
            "sensitivity_level": highest_sensitivity.value,
            "total_matches": len(matches),
            "categories": list(categories_found),
            "matches": matches,
            "recommendation": recommendation
        }
    
    def _validate_luhn(self, card_number: str) -> bool:
        """Validate credit card using Luhn algorithm"""
        digits = re.sub(r'[-\s]', '', card_number)
        
        if not digits.isdigit() or len(digits) < 13:
            return False
        
        total = 0
        reverse = digits[::-1]
        
        for i, digit in enumerate(reverse):
            n = int(digit)
            if i % 2 == 1:
                n *= 2
                if n > 9:
                    n -= 9
            total += n
        
        return total % 10 == 0
    
    def _mask_text(self, text: str, category: str) -> str:
        """Create masked version of sensitive data"""
        
        clean = re.sub(r'[-\s]', '', text)
        
        if category in ["credit_card"]:
            # Show last 4 digits: ****-****-****-1234
            return f"****-****-****-{clean[-4:]}"
        
        elif category in ["phone"]:
            # Show last 4: ***-***-1234
            return f"***-***-{clean[-4:]}"
        
        elif category in ["ssn"]:
            # Show last 4: ***-**-1234
            return f"***-**-{clean[-4:]}"
        
        elif category in ["email"]:
            # Show first char and domain
            parts = text.split('@')
            if len(parts) == 2:
                return f"{parts[0][0]}***@{parts[1]}"
        
        elif category in ["password", "pin", "api_key", "cvv"]:
            # Fully mask
            return "*" * min(len(text), 12)
        
        # Default: show first 2 and last 2
        if len(text) > 4:
            return text[:2] + "*" * (len(text) - 4) + text[-2:]
        return "*" * len(text)
    
    def _deduplicate_matches(self, matches: List[Dict]) -> List[Dict]:
        """Remove duplicate matches at same position"""
        seen = set()
        unique = []
        
        # Sort by confidence (highest first)
        matches.sort(key=lambda x: x["confidence"], reverse=True)
        
        for match in matches:
            key = (match["position"]["start"], match["position"]["end"])
            if key not in seen:
                seen.add(key)
                unique.append(match)
        
        return unique
    
    def _sensitivity_rank(self, level: SensitivityLevel) -> int:
        """Get numeric rank for sensitivity level"""
        ranks = {
            SensitivityLevel.NONE: 0,
            SensitivityLevel.LOW: 1,
            SensitivityLevel.MEDIUM: 2,
            SensitivityLevel.HIGH: 3,
            SensitivityLevel.CRITICAL: 4,
        }
        return ranks.get(level, 0)
    
    def _generate_recommendation(self, sensitivity: SensitivityLevel, categories: List[str]) -> str:
        """Generate user-friendly recommendation"""
        
        if sensitivity == SensitivityLevel.NONE:
            return "✅ No sensitive data detected. Safe to send."
        
        elif sensitivity == SensitivityLevel.LOW:
            return "ℹ️ Low sensitivity data detected. Consider if the recipient needs this information."
        
        elif sensitivity == SensitivityLevel.MEDIUM:
            return "⚠️ Medium sensitivity data detected. Verify you trust the recipient before sending."
        
        elif sensitivity == SensitivityLevel.HIGH:
            return "🔶 High sensitivity data detected! Only send if absolutely necessary and to trusted recipients."
        
        else:  # CRITICAL
            cat_str = ", ".join(categories[:3])
            return f"🛑 CRITICAL: Highly sensitive data detected ({cat_str})! Strongly recommend NOT sending this information via this channel."


# ============================================================
# STANDALONE TESTING
# ============================================================

def test_dlp_detector():
    """Test the DLP detector"""
    
    print("="*60)
    print("🛡️ DLP DETECTOR - TEST SUITE")
    print("="*60)
    
    detector = DLPDetector()
    
    test_cases = [
        # Critical
        ("My credit card is 4532015112830366", SensitivityLevel.CRITICAL),
        ("Password: secretPass123", SensitivityLevel.CRITICAL),
        ("My SSN is 123-45-6789", SensitivityLevel.CRITICAL),
        ("API key: sk-1234567890abcdefghijklmnop", SensitivityLevel.CRITICAL),
        ("PIN: 1234", SensitivityLevel.CRITICAL),
        ("My NRIC is S1234567D", SensitivityLevel.CRITICAL),
        
        # High
        ("Account number: 12345678901234", SensitivityLevel.HIGH),
        ("IBAN: GB82WEST12345698765432", SensitivityLevel.HIGH),
        
        # Medium
        ("Call me at +1-555-123-4567", SensitivityLevel.MEDIUM),
        ("DOB: 01/15/1990", SensitivityLevel.MEDIUM),
        
        # Low
        ("Email me at john@example.com", SensitivityLevel.LOW),
        
        # None
        ("Hey, how are you doing today?", SensitivityLevel.NONE),
        ("Meeting at 3pm tomorrow", SensitivityLevel.NONE),
    ]
    
    passed = 0
    failed = 0
    
    for text, expected_level in test_cases:
        result = detector.analyze(text)
        actual_level = SensitivityLevel(result["sensitivity_level"])
        
        # Check if sensitivity matches or exceeds expected
        if detector._sensitivity_rank(actual_level) >= detector._sensitivity_rank(expected_level):
            status = "✅"
            passed += 1
        else:
            status = "❌"
            failed += 1
        
        print(f"\n{status} Text: {text[:40]}...")
        print(f"   Expected: {expected_level.value} | Got: {actual_level.value}")
        if result["has_sensitive_data"]:
            print(f"   Categories: {result['categories']}")
            print(f"   Matches: {len(result['matches'])}")
    
    print("\n" + "="*60)
    print(f"Results: {passed} passed, {failed} failed")
    print("="*60)


if __name__ == "__main__":
    test_dlp_detector()