"""
train_spam_classifier.py
========================

Spam Classifier for Sifitlier
- Trains on SMS/Email spam datasets
- Provides SpamClassifier class for main.py to import

Classes:
    - TextPreprocessor: Cleans and prepares text for ML
    - SpamClassifier: ML model for spam detection

Usage:
    # Training (run this file directly):
    python train_spam_classifier.py
    
    # In main.py:
    from train_spam_classifier import SpamClassifier, TextPreprocessor
    classifier = SpamClassifier()
    classifier.load("spam_classifier_pipeline.pkl")
    result = classifier.predict("Your message here")
"""

import re
import string
import os
from typing import Dict, Any, Optional, List
import warnings
warnings.filterwarnings('ignore')

# ML Libraries
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, classification_report
import joblib


class TextPreprocessor:
    """
    Text preprocessing for spam detection.
    
    Handles:
    - Lowercase conversion
    - URL removal/replacement
    - Number normalization
    - Punctuation handling
    - Whitespace normalization
    """
    
    def __init__(self):
        # Common spam indicators to preserve
        self.spam_indicators = [
            'free', 'winner', 'cash', 'prize', 'urgent', 'click',
            'subscribe', 'congratulations', 'selected', 'claim'
        ]
    
    def preprocess(self, text: str) -> str:
        """
        Preprocess a single text message.
        
        Args:
            text: Raw message text
            
        Returns:
            Cleaned text ready for ML
        """
        if not isinstance(text, str):
            return ""
        
        # Convert to lowercase
        text = text.lower()
        
        # Replace URLs with placeholder (URLs are spam indicators)
        text = re.sub(r'http\S+|www\.\S+', ' urllink ', text)
        
        # Replace email addresses
        text = re.sub(r'\S+@\S+', ' emailaddr ', text)
        
        # Replace phone numbers
        text = re.sub(r'\b\d{10,}\b', ' phonenumber ', text)
        text = re.sub(r'\+\d{1,3}[-.\s]?\d+', ' phonenumber ', text)
        
        # Replace currency amounts
        text = re.sub(r'[$£€]\s*\d+[,.]?\d*', ' moneysymbol ', text)
        text = re.sub(r'\d+\s*(?:dollars?|pounds?|euros?)', ' moneysymbol ', text)
        
        # Replace numbers with placeholder
        text = re.sub(r'\b\d+\b', ' number ', text)
        
        # Remove extra punctuation but keep some for context
        text = re.sub(r'[!]{2,}', ' multiplebang ', text)
        text = re.sub(r'[?]{2,}', ' multiplequestion ', text)
        text = re.sub(r'[.]{2,}', ' ellipsis ', text)
        
        # Remove remaining punctuation
        text = text.translate(str.maketrans('', '', string.punctuation))
        
        # Normalize whitespace
        text = re.sub(r'\s+', ' ', text).strip()
        
        return text
    
    def preprocess_batch(self, texts: List[str]) -> List[str]:
        """Preprocess multiple texts"""
        return [self.preprocess(t) for t in texts]


class SpamClassifier:
    """
    Spam Detection Classifier for Sifitlier.
    
    Uses TF-IDF vectorization with Multinomial Naive Bayes.
    Supports training, saving, loading, and prediction.
    
    Usage:
        # Train new model
        classifier = SpamClassifier()
        classifier.train(X_train, y_train)
        classifier.save("model.pkl")
        
        # Load and predict
        classifier = SpamClassifier()
        classifier.load("model.pkl")
        result = classifier.predict("Free prize! Click now!")
    """
    
    def __init__(self):
        self.preprocessor = TextPreprocessor()
        self.pipeline: Optional[Pipeline] = None
        self.is_trained = False
        
        # Risk level thresholds
        self.thresholds = {
            'high': 0.8,
            'medium': 0.5,
            'low': 0.3
        }
    
    def create_pipeline(self) -> Pipeline:
        """Create the ML pipeline"""
        return Pipeline([
            ('tfidf', TfidfVectorizer(
                max_features=5000,
                ngram_range=(1, 2),
                min_df=2,
                max_df=0.95,
                sublinear_tf=True
            )),
            ('classifier', MultinomialNB(alpha=0.1))
        ])
    
    def train(self, X: List[str], y: List[str], preprocess: bool = True) -> Dict[str, float]:
        """
        Train the spam classifier.
        
        Args:
            X: List of message texts
            y: List of labels ('spam' or 'ham')
            preprocess: Whether to preprocess texts
            
        Returns:
            Dictionary with training metrics
        """
        # Preprocess if requested
        if preprocess:
            X = self.preprocessor.preprocess_batch(X)
        
        # Create and train pipeline
        self.pipeline = self.create_pipeline()
        self.pipeline.fit(X, y)
        self.is_trained = True
        
        # Calculate training metrics
        y_pred = self.pipeline.predict(X)
        
        return {
            'accuracy': accuracy_score(y, y_pred),
            'precision': precision_score(y, y_pred, pos_label='spam'),
            'recall': recall_score(y, y_pred, pos_label='spam'),
            'f1': f1_score(y, y_pred, pos_label='spam')
        }
    
    def predict(self, text: str) -> Dict[str, Any]:
        """
        Predict if a message is spam.
        
        Args:
            text: Message to classify
            
        Returns:
            Dictionary with prediction results:
            - is_spam: bool
            - label: 'spam' or 'ham'
            - confidence: float (0-1)
            - spam_probability: float (0-1)
            - risk_level: 'high', 'medium', 'low', or 'safe'
        """
        if not self.pipeline:
            raise RuntimeError("Model not loaded. Call load() or train() first.")
        
        # Preprocess
        processed_text = self.preprocessor.preprocess(text)
        
        # Get prediction
        prediction = self.pipeline.predict([processed_text])[0]
        
        # Get probability scores
        probabilities = self.pipeline.predict_proba([processed_text])[0]
        
        # Get spam probability (assuming 'spam' is one of the classes)
        classes = list(self.pipeline.classes_)
        if 'spam' in classes:
            spam_idx = classes.index('spam')
            spam_probability = float(probabilities[spam_idx])
        else:
            # If classes are 0/1, assume 1 is spam
            spam_probability = float(probabilities[1]) if len(probabilities) > 1 else float(probabilities[0])
        
        # Determine if spam
        is_spam = prediction == 'spam' or prediction == 1
        
        # Calculate confidence (how sure we are about our prediction)
        confidence = float(max(probabilities))
        
        # Determine risk level
        if spam_probability >= self.thresholds['high']:
            risk_level = 'high'
        elif spam_probability >= self.thresholds['medium']:
            risk_level = 'medium'
        elif spam_probability >= self.thresholds['low']:
            risk_level = 'low'
        else:
            risk_level = 'safe'
        
        return {
            'is_spam': is_spam,
            'label': 'spam' if is_spam else 'ham',
            'confidence': round(confidence, 4),
            'spam_probability': round(spam_probability, 4),
            'risk_level': risk_level
        }
    
    def predict_batch(self, texts: List[str]) -> List[Dict[str, Any]]:
        """Predict multiple messages"""
        return [self.predict(text) for text in texts]
    
    def save(self, filepath: str):
        """Save the trained model to file"""
        if not self.pipeline:
            raise RuntimeError("No model to save. Train first.")
        
        joblib.dump({
            'pipeline': self.pipeline,
            'thresholds': self.thresholds,
            'version': '1.0'
        }, filepath)
        print(f"✅ Model saved to {filepath}")
    
    def load(self, filepath: str):
        """Load a trained model from file"""
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"Model file not found: {filepath}")
        
        data = joblib.load(filepath)
        
        if isinstance(data, dict):
            self.pipeline = data['pipeline']
            self.thresholds = data.get('thresholds', self.thresholds)
        else:
            # Legacy format: just the pipeline
            self.pipeline = data
        
        self.is_trained = True
        print(f"✅ Model loaded from {filepath}")
    
    def evaluate(self, X: List[str], y: List[str], preprocess: bool = True) -> Dict[str, Any]:
        """
        Evaluate model on test data.
        
        Returns detailed metrics and classification report.
        """
        if not self.pipeline:
            raise RuntimeError("Model not loaded.")
        
        if preprocess:
            X = self.preprocessor.preprocess_batch(X)
        
        y_pred = self.pipeline.predict(X)
        
        return {
            'accuracy': accuracy_score(y, y_pred),
            'precision': precision_score(y, y_pred, pos_label='spam'),
            'recall': recall_score(y, y_pred, pos_label='spam'),
            'f1': f1_score(y, y_pred, pos_label='spam'),
            'classification_report': classification_report(y, y_pred)
        }


# ============================================================
# TRAINING SCRIPT
# ============================================================

def load_dataset(filepath: str = 'spam.csv') -> pd.DataFrame:
    """Load and prepare the spam dataset with robust encoding support"""
    
    if not os.path.exists(filepath):
        print(f"⚠️ Dataset not found at {filepath}")
        print("Creating sample dataset for demonstration...")
        return create_sample_dataset()
    
    # Try different encodings to avoid "Could not read" errors
    encodings = ['utf-8', 'latin-1', 'ISO-8859-1', 'cp1252']
    df = None
    
    for encoding in encodings:
        try:
            print(f"📄 Trying to read with encoding: {encoding}...")
            df = pd.read_csv(filepath, encoding=encoding)
            print(f"✅ Successfully loaded {filepath}")
            break
        except Exception as e:
            continue
            
    if df is None:
        raise ValueError(f"Could not read {filepath} with any of the attempted encodings.")
    
    # Standardize column names
    if 'v1' in df.columns and 'v2' in df.columns:
        df = df.rename(columns={'v1': 'label', 'v2': 'message'})
    elif 'Category' in df.columns and 'Message' in df.columns:
        df = df.rename(columns={'Category': 'label', 'Message': 'message'})
    
    # Check if necessary columns exist
    if 'label' not in df.columns or 'message' not in df.columns:
        # Fallback: check if it's a 2-column CSV without headers
        if len(df.columns) >= 2:
            print("⚠️ Headers not found, assuming first column is label and second is message")
            df = df.iloc[:, :2]
            df.columns = ['label', 'message']
    
    # Keep only needed columns
    df = df[['label', 'message']].dropna()
    
    # Standardize labels
    df['label'] = df['label'].str.lower().str.strip()
    
    print(f"✅ Loaded {len(df)} messages")
    print(f"   Distribution: {df['label'].value_counts().to_dict()}")
    
    return df


def create_sample_dataset() -> pd.DataFrame:
    """Create a sample dataset for testing"""
    
    ham_messages = [
        "Hey, are you coming to the party tonight?",
        "Can we reschedule our meeting to 3pm?",
        "Thanks for sending the report!",
        "Happy birthday! Hope you have a great day",
        "Don't forget to pick up groceries",
        "The weather is beautiful today",
        "See you at the office tomorrow",
        "Great job on the presentation!",
        "Can you call me when you're free?",
        "Dinner at 7pm sounds perfect",
    ] * 100
    
    spam_messages = [
        "CONGRATULATIONS! You've won $1,000,000! Claim NOW!",
        "FREE iPhone! Click here immediately!",
        "URGENT: Your bank account needs verification",
        "You're our lucky winner! Call now to claim prize",
        "Limited time offer! Act NOW!",
        "Your account will be suspended! Verify immediately",
        "Win a FREE vacation! Click this link",
        "Exclusive deal just for you! Don't miss out!",
        "ALERT: Suspicious activity on your account",
        "Claim your FREE gift card NOW!!!",
    ] * 50
    
    df = pd.DataFrame({
        'label': ['ham'] * len(ham_messages) + ['spam'] * len(spam_messages),
        'message': ham_messages + spam_messages
    })
    
    return df.sample(frac=1).reset_index(drop=True)  # Shuffle


def train_and_save_model(data_path: str = 'spam.csv', model_path: str = 'spam_classifier_pipeline.pkl'):
    """Main training function"""
    
    print("="*60)
    print("🤖 SIFITLIER - Spam Classifier Training")
    print("="*60)
    
    # Load data
    print("\n📁 Loading dataset...")
    df = load_dataset(data_path)
    
    # Split data
    print("\n📊 Splitting data...")
    X_train, X_test, y_train, y_test = train_test_split(
        df['message'].tolist(),
        df['label'].tolist(),
        test_size=0.2,
        random_state=42,
        stratify=df['label']
    )
    print(f"   Training: {len(X_train)} | Test: {len(X_test)}")
    
    # Train model
    print("\n🎯 Training model...")
    classifier = SpamClassifier()
    train_metrics = classifier.train(X_train, y_train)
    
    print(f"\n   Training Metrics:")
    print(f"   ├── Accuracy:  {train_metrics['accuracy']:.4f}")
    print(f"   ├── Precision: {train_metrics['precision']:.4f}")
    print(f"   ├── Recall:    {train_metrics['recall']:.4f}")
    print(f"   └── F1 Score:  {train_metrics['f1']:.4f}")
    
    # Evaluate on test set
    print("\n📈 Evaluating on test set...")
    test_metrics = classifier.evaluate(X_test, y_test)
    
    print(f"\n   Test Metrics:")
    print(f"   ├── Accuracy:  {test_metrics['accuracy']:.4f}")
    print(f"   ├── Precision: {test_metrics['precision']:.4f}")
    print(f"   ├── Recall:    {test_metrics['recall']:.4f}")
    print(f"   └── F1 Score:  {test_metrics['f1']:.4f}")
    
    # Save model
    print(f"\n💾 Saving model to {model_path}...")
    classifier.save(model_path)
    
    # Test predictions
    print("\n🧪 Testing predictions...")
    test_messages = [
        "Hey, want to grab lunch tomorrow?",
        "CONGRATULATIONS! You won $1,000,000!",
        "Meeting at 3pm in conference room",
        "URGENT: Verify your account NOW!",
    ]
    
    print("\n   Sample Predictions:")
    for msg in test_messages:
        result = classifier.predict(msg)
        emoji = "🚨" if result['is_spam'] else "✅"
        print(f"   {emoji} [{result['label'].upper():4s}] {result['spam_probability']*100:5.1f}% | {msg[:40]}...")
    
    print("\n" + "="*60)
    print("✅ Training Complete!")
    print("="*60)
    
    return classifier

if __name__ == "__main__":
    train_and_save_model()