import pandas as pd
import numpy as np
import string
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from nltk.stem import WordNetLemmatizer

from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC  # <-- Only importing LinearSVC
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

import joblib # Used for saving and loading the model

def download_nltk_data():
    """Downloads necessary NLTK datasets for preprocessing."""
    try:
        nltk.data.find('tokenizers/punkt')
    except LookupError:
        print("Downloading 'punkt' tokenizer...")
        nltk.download('punkt', quiet=True)
        
    try:
        nltk.data.find('corpora/stopwords')
    except LookupError:
        print("Downloading 'stopwords'...")
        nltk.download('stopwords', quiet=True)
        
    try:
        nltk.data.find('corpora/wordnet')
    except LookupError:
        print("Downloading 'wordnet' lemmatizer...")
        nltk.download('wordnet', quiet=True)

def preprocess_text(text):
    """
    Cleans and preprocesses a single text message.
    1. Lowercase
    2. Remove punctuation
    3. Tokenize
    4. Remove stopwords
    5. Lemmatize
    """
    # 1. Lowercase
    text = text.lower()
    
    # 2. Remove punctuation
    text = "".join([char for char in text if char not in string.punctuation])
    
    # 3. Tokenize
    tokens = word_tokenize(text)
    
    # 4. Remove stopwords
    stop_words = set(stopwords.words('english'))
    filtered_tokens = [word for word in tokens if word not in stop_words]
    
    # 5. Lemmatize
    lemmatizer = WordNetLemmatizer()
    lemmatized_tokens = [lemmatizer.lemmatize(token) for token in filtered_tokens]
    
    # Join tokens back into a string
    return " ".join(lemmatized_tokens)

def main():
    """Main function to run the full training pipeline."""
    
    # Ensure NLTK data is available
    download_nltk_data()
    print("NLTK data is ready.")

    # --- 1. Load Data ---
    # We use the direct URL for the UCI SMS Spam Collection dataset
    data_url = "https://raw.githubusercontent.com/uciml/sms-spam-collection-dataset/main/SMSSpamCollection"
    
    try:
        # The file is tab-separated and has no header
        df = pd.read_csv(data_url, sep='\t', header=None, names=['label', 'message'], on_bad_lines='skip')
    except Exception as e:
        print(f"Error loading dataset: {e}")
        print("Please check your internet connection or the dataset URL.")
        return

    print(f"Dataset loaded. Total messages: {len(df)}")
    print(df.head())

    # --- 2. Preprocessing ---
    print("\nStarting text preprocessing...")
    # Apply the preprocessing function to every message
    # This might take a minute or two
    df['processed_message'] = df['message'].apply(preprocess_text)
    print("Text preprocessing complete.")
    print(df[['message', 'processed_message']].head())

    # Map labels to numbers
    df['label_num'] = df['label'].map({'ham': 0, 'spam': 1})
    
    # --- 3. Train-Test Split ---
    X = df['processed_message']
    y = df['label_num']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
    
    print(f"\nData split: {len(X_train)} training, {len(X_test)} test samples")

    # --- 4. Feature Extraction (TF-IDF) ---
    print("Vectorizing text using TF-IDF...")
    # We only fit the vectorizer ONCE on the training data
    tfidf_vectorizer = TfidfVectorizer(max_features=5000) # Limit to top 5000 features
    
    # Fit and transform the training data
    X_train_tfidf = tfidf_vectorizer.fit_transform(X_train)
    
    # Only transform the test data (using the vocab from training)
    X_test_tfidf = tfidf_vectorizer.transform(X_test)
    
    print(f"Text vectorized. Feature shape: {X_train_tfidf.shape}")

    # --- 5. Model Training (LinearSVC) ---
    # We are training only the LinearSVC (Support Vector Machine) model,
    # as it's a consistent top performer for this task.
    print("\n--- Model Training ---")
    
    model = LinearSVC()
    print(f"Training LinearSVC model...")
    model.fit(X_train_tfidf, y_train)
    print("Model training complete.")
        
    # --- 6. Model Evaluation ---
    print(f"\n--- Evaluation for LinearSVC ---")
    y_pred = model.predict(X_test_tfidf)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"Accuracy: {accuracy * 100:.2f}%")
    
    print(f"\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=['ham', 'spam']))
    
    print(f"Confusion Matrix:")
    print(confusion_matrix(y_test, y_pred))

    # --- 7. Save the Model and Vectorizer ---
    print(f"\n--- Saving Model ---")

    # We must save BOTH the model and the vectorizer
    model_filename = 'spam_detector_model.joblib'
    vectorizer_filename = 'tfidf_vectorizer.joblib'
    
    joblib.dump(model, model_filename)
    joblib.dump(tfidf_vectorizer, vectorizer_filename)
    
    print(f"\nModel saved to {model_filename}")
    print(f"Vectorizer saved to {vectorizer_filename}")

    # --- 8. Example Prediction on New Data (using the saved model) ---
    print("\n--- Testing with new messages (using the saved model) ---")
    print(f"\n--- Best Model Selection ---")
    print(f"The best performing model is: {best_model_name} with {best_accuracy * 100:.2f}% accuracy.")

    # We must save BOTH the best model and the vectorizer
    model_filename = 'spam_detector_model.joblib'
    vectorizer_filename = 'tfidf_vectorizer.joblib'
    
    joblib.dump(best_model, model_filename)
    joblib.dump(tfidf_vectorizer, vectorizer_filename)
    
    print(f"\nBest model saved to {model_filename}")
    print(f"Vectorizer saved to {vectorizer_filename}")

    # --- 8. Example Prediction on New Data (using the best model) ---
    print("\n--- Testing with new messages (using the best model) ---")
    
    # Load the saved (best) model and vectorizer
    loaded_model = joblib.load(model_filename)
    loaded_vectorizer = joblib.load(vectorizer_filename)
    
    test_messages = [
        "Congratulations! You've won a $1000 gift card. Click here to claim: www.fake.com",
        "Hey mom, are you free for dinner tonight? Let me know.",
        "URGENT: Your account has been suspended. Please verify your details at http://security-update-scam.net",
        "See you at 8pm."
    ]
    
    for msg in test_messages:
        # Preprocess the message
        processed_msg = preprocess_text(msg)
        
        # Vectorize the message
        vectorized_msg = loaded_vectorizer.transform([processed_msg])
        
        # Predict
        prediction = loaded_model.predict(vectorized_msg)
        
        # Interpret prediction
        result = 'Spam' if prediction[0] == 1 else 'Ham'
        print(f"Message: '{msg}'\nPrediction: -> {result}\n")

if __name__ == "__main__":
    main()