"""
Export spam classifier model to JSON for on-device inference in Flutter.
Exports TF-IDF vocabulary, IDF weights, and Logistic Regression coefficients.

Usage:
    python export_model.py

Output:
    ../flutter_app/assets/spam_model.json
"""

import json
import numpy as np
from train_spam_classifier import SpamClassifier


def export_model(model_path='spam_classifier_pipeline.pkl',
                 output_path='../flutter_app/assets/spam_model.json'):
    """Export trained model to JSON for Dart inference"""

    classifier = SpamClassifier()
    classifier.load(model_path)

    pipeline = classifier.pipeline
    tfidf = pipeline.named_steps['tfidf']
    model = pipeline.named_steps['classifier']

    # Extract TF-IDF components (convert numpy int64 keys to plain int)
    vocabulary = {k: int(v) for k, v in tfidf.vocabulary_.items()}
    idf = [float(x) for x in tfidf.idf_]

    # Extract Logistic Regression components
    # coef_ shape: (n_classes, n_features) — for binary, it's (1, n_features)
    coef = model.coef_.tolist()
    intercept = model.intercept_.tolist()
    classes = model.classes_.tolist()

    export_data = {
        'model_type': 'logistic_regression',
        'version': '1.0',
        'tfidf': {
            'vocabulary': vocabulary,
            'idf': idf,
            'max_features': tfidf.max_features,
            'ngram_range': list(tfidf.ngram_range),
            'sublinear_tf': tfidf.sublinear_tf,
        },
        'classifier': {
            'coef': coef,
            'intercept': intercept,
            'classes': classes,
        },
        'thresholds': classifier.thresholds,
    }

    with open(output_path, 'w') as f:
        json.dump(export_data, f)

    # Print stats
    size_kb = len(json.dumps(export_data)) / 1024
    print(f"Exported model to {output_path}")
    print(f"  Vocabulary size: {len(vocabulary)}")
    print(f"  Feature count: {len(idf)}")
    print(f"  Classes: {classes}")
    print(f"  File size: {size_kb:.0f} KB")

    # Verify by running a test prediction
    print("\nVerification:")
    test_msgs = [
        "Hey want to grab lunch?",
        "CONGRATULATIONS! You won $1,000,000! Click NOW!",
    ]
    for msg in test_msgs:
        result = classifier.predict(msg)
        print(f"  [{result['label']:4s}] {result['spam_probability']:.4f} | {msg[:50]}")


if __name__ == '__main__':
    export_model()
