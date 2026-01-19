"""
Sifitlier Backend API
FastAPI server for spam detection, DLP, push notifications, and activity logging
"""

import os
import sys
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from enum import Enum
import json
import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import uvicorn

# Firebase Admin SDK for push notifications
import firebase_admin
from firebase_admin import credentials, messaging

# Database (using SQLite for simplicity, can be swapped for PostgreSQL)
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Text, Float, Enum as SQLEnum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session

# Import our ML modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from train_spam_classifier import SpamClassifier, TextPreprocessor
from dlp_detector import DLPDetector, SensitivityLevel


# ============== Database Setup ==============
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./sifitlier.db")
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class AlertType(str, Enum):
    SPAM = "spam"
    DLP = "dlp"


class MessageSource(str, Enum):
    SMS = "sms"
    EMAIL = "email"
    TELEGRAM = "telegram"


class Alert(Base):
    """Database model for storing alerts/logs"""
    __tablename__ = "alerts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    device_token = Column(String, nullable=True)
    alert_type = Column(String)  # spam or dlp
    source = Column(String)  # sms, email, telegram
    direction = Column(String)  # inbound or outbound
    message_preview = Column(Text)
    full_message = Column(Text)
    
    # Spam detection results
    is_spam = Column(Boolean, nullable=True)
    spam_confidence = Column(Float, nullable=True)
    spam_risk_level = Column(String, nullable=True)
    
    # DLP results
    has_sensitive_data = Column(Boolean, nullable=True)
    dlp_sensitivity_level = Column(String, nullable=True)
    dlp_categories = Column(Text, nullable=True)  # JSON string
    dlp_matches = Column(Text, nullable=True)  # JSON string
    
    # Metadata
    sender = Column(String, nullable=True)
    recipient = Column(String, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    notification_sent = Column(Boolean, default=False)
    user_action = Column(String, nullable=True)  # allowed, blocked, reported


class UserDevice(Base):
    """Store user devices for push notifications"""
    __tablename__ = "user_devices"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    device_token = Column(String, unique=True)
    platform = Column(String)  # ios, android
    created_at = Column(DateTime, default=datetime.utcnow)
    last_active = Column(DateTime, default=datetime.utcnow)


# Create tables
Base.metadata.create_all(bind=engine)


# ============== Pydantic Models ==============

class SpamCheckRequest(BaseModel):
    user_id: str
    message: str
    source: MessageSource
    sender: Optional[str] = None
    device_token: Optional[str] = None


class SpamCheckResponse(BaseModel):
    is_spam: bool
    label: str
    confidence: float
    spam_probability: float
    risk_level: str
    alert_id: Optional[int] = None


class DLPCheckRequest(BaseModel):
    user_id: str
    message: str
    source: MessageSource
    recipient: Optional[str] = None
    device_token: Optional[str] = None


class DLPCheckResponse(BaseModel):
    has_sensitive_data: bool
    sensitivity_level: str
    total_matches: int
    categories: List[str]
    matches: List[Dict]
    recommendation: str
    alert_id: Optional[int] = None


class DeviceRegistration(BaseModel):
    user_id: str
    device_token: str
    platform: str = "android"


class AlertResponse(BaseModel):
    id: int
    alert_type: str
    source: str
    direction: str
    message_preview: str
    timestamp: datetime
    is_spam: Optional[bool]
    spam_risk_level: Optional[str]
    has_sensitive_data: Optional[bool]
    dlp_sensitivity_level: Optional[str]


class AlertDetailResponse(AlertResponse):
    full_message: str
    spam_confidence: Optional[float]
    dlp_categories: Optional[List[str]]
    dlp_matches: Optional[List[Dict]]
    sender: Optional[str]
    recipient: Optional[str]
    user_action: Optional[str]


class AlertUpdateRequest(BaseModel):
    action: str  # allowed, blocked, reported


# ============== Initialize ML Models & Firebase ==============

spam_classifier: Optional[SpamClassifier] = None
dlp_detector: Optional[DLPDetector] = None
firebase_initialized = False


def initialize_firebase():
    """Initialize Firebase Admin SDK for push notifications"""
    global firebase_initialized
    
    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
    
    if os.path.exists(cred_path):
        try:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            firebase_initialized = True
            print("✅ Firebase initialized successfully")
        except Exception as e:
            print(f"⚠️ Firebase initialization failed: {e}")
    else:
        print("⚠️ Firebase credentials not found. Push notifications disabled.")


def load_ml_models():
    """Load ML models on startup"""
    global spam_classifier, dlp_detector
    
    # Initialize spam classifier
    model_path = os.getenv("SPAM_MODEL_PATH", "spam_classifier_pipeline.pkl")
    spam_classifier = SpamClassifier()
    
    if os.path.exists(model_path):
        try:
            spam_classifier.load(model_path)
            print("✅ Spam classifier loaded successfully")
        except Exception as e:
            print(f"⚠️ Failed to load spam classifier: {e}")
            # Use default/untrained classifier for demo
    else:
        print("⚠️ Spam model not found. Using untrained classifier.")
    
    # Initialize DLP detector
    dlp_detector = DLPDetector()
    print("✅ DLP detector initialized")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    # Startup
    load_ml_models()
    initialize_firebase()
    yield
    # Shutdown
    pass


# ============== FastAPI App ==============

app = FastAPI(
    title="Sifitlier API",
    description="AI-powered spam detection and data loss prevention API",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ============== Push Notification Service ==============

async def send_push_notification(device_token: str, title: str, body: str, data: Dict = None):
    """Send push notification via Firebase"""
    if not firebase_initialized:
        print("Push notifications disabled - Firebase not initialized")
        return False
    
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=device_token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="sifitlier_alerts",
                    priority="high",
                    default_sound=True,
                    default_vibrate_timings=True,
                )
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        alert=messaging.ApsAlert(
                            title=title,
                            body=body,
                        ),
                        sound="default",
                        badge=1,
                    )
                )
            )
        )
        
        response = messaging.send(message)
        print(f"✅ Push notification sent: {response}")
        return True
    except Exception as e:
        print(f"❌ Failed to send push notification: {e}")
        return False


# ============== API Endpoints ==============

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "service": "Sifitlier API",
        "status": "running",
        "version": "1.0.0",
        "models": {
            "spam_classifier": spam_classifier is not None,
            "dlp_detector": dlp_detector is not None,
        },
        "firebase": firebase_initialized
    }


@app.post("/api/v1/spam/check", response_model=SpamCheckResponse)
async def check_spam(
    request: SpamCheckRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Check a message for spam/phishing
    
    This endpoint analyzes incoming messages (SMS, Email, Telegram)
    and returns spam detection results.
    """
    if not spam_classifier or not spam_classifier.pipeline:
        # Fallback to basic detection if model not loaded
        raise HTTPException(status_code=503, detail="Spam classifier not available")
    
    # Perform spam detection
    result = spam_classifier.predict(request.message)
    
    # Create alert log
    alert = Alert(
        user_id=request.user_id,
        device_token=request.device_token,
        alert_type=AlertType.SPAM.value,
        source=request.source.value,
        direction="inbound",
        message_preview=request.message[:100] + ("..." if len(request.message) > 100 else ""),
        full_message=request.message,
        sender=request.sender,
        is_spam=result['is_spam'],
        spam_confidence=result['confidence'],
        spam_risk_level=result['risk_level'],
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)
    
    # Send push notification if spam detected
    if result['is_spam'] and request.device_token:
        background_tasks.add_task(
            send_push_notification,
            request.device_token,
            "⚠️ Spam Alert",
            f"Suspicious {request.source.value.upper()} detected from {request.sender or 'unknown'}",
            {
                "alert_id": str(alert.id),
                "alert_type": "spam",
                "risk_level": result['risk_level']
            }
        )
        alert.notification_sent = True
        db.commit()
    
    return SpamCheckResponse(
        is_spam=result['is_spam'],
        label=result['label'],
        confidence=result['confidence'],
        spam_probability=result['spam_probability'],
        risk_level=result['risk_level'],
        alert_id=alert.id
    )


@app.post("/api/v1/dlp/check", response_model=DLPCheckResponse)
async def check_dlp(
    request: DLPCheckRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Check outgoing message for sensitive data
    
    This endpoint analyzes outgoing messages before they're sent
    and warns users about potential data leaks.
    """
    if not dlp_detector:
        raise HTTPException(status_code=503, detail="DLP detector not available")
    
    # Perform DLP analysis
    result = dlp_detector.analyze(request.message)
    
    # Create alert log
    alert = Alert(
        user_id=request.user_id,
        device_token=request.device_token,
        alert_type=AlertType.DLP.value,
        source=request.source.value,
        direction="outbound",
        message_preview=request.message[:100] + ("..." if len(request.message) > 100 else ""),
        full_message=request.message,
        recipient=request.recipient,
        has_sensitive_data=result['has_sensitive_data'],
        dlp_sensitivity_level=result['sensitivity_level'],
        dlp_categories=json.dumps(result['categories']),
        dlp_matches=json.dumps(result['matches']),
    )
    db.add(alert)
    db.commit()
    db.refresh(alert)
    
    # Send push notification if sensitive data detected
    if result['has_sensitive_data'] and request.device_token:
        severity = "⚠️" if result['sensitivity_level'] in ['high', 'critical'] else "⚡"
        background_tasks.add_task(
            send_push_notification,
            request.device_token,
            f"{severity} Sensitive Data Warning",
            f"Your {request.source.value.upper()} contains {result['sensitivity_level']} sensitivity data",
            {
                "alert_id": str(alert.id),
                "alert_type": "dlp",
                "sensitivity_level": result['sensitivity_level']
            }
        )
        alert.notification_sent = True
        db.commit()
    
    return DLPCheckResponse(
        has_sensitive_data=result['has_sensitive_data'],
        sensitivity_level=result['sensitivity_level'],
        total_matches=result['total_matches'],
        categories=result['categories'],
        matches=result['matches'],
        recommendation=result['recommendation'],
        alert_id=alert.id
    )


@app.post("/api/v1/device/register")
async def register_device(
    registration: DeviceRegistration,
    db: Session = Depends(get_db)
):
    """Register device for push notifications"""
    
    # Check if device already exists
    existing = db.query(UserDevice).filter(
        UserDevice.device_token == registration.device_token
    ).first()
    
    if existing:
        existing.user_id = registration.user_id
        existing.last_active = datetime.utcnow()
    else:
        device = UserDevice(
            user_id=registration.user_id,
            device_token=registration.device_token,
            platform=registration.platform
        )
        db.add(device)
    
    db.commit()
    
    return {"status": "success", "message": "Device registered"}


@app.get("/api/v1/alerts", response_model=List[AlertResponse])
async def get_alerts(
    user_id: str,
    alert_type: Optional[str] = None,
    source: Optional[str] = None,
    limit: int = Query(default=50, le=100),
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """Get alert history for a user"""
    
    query = db.query(Alert).filter(Alert.user_id == user_id)
    
    if alert_type:
        query = query.filter(Alert.alert_type == alert_type)
    if source:
        query = query.filter(Alert.source == source)
    
    alerts = query.order_by(Alert.timestamp.desc()).offset(offset).limit(limit).all()
    
    return [
        AlertResponse(
            id=a.id,
            alert_type=a.alert_type,
            source=a.source,
            direction=a.direction,
            message_preview=a.message_preview,
            timestamp=a.timestamp,
            is_spam=a.is_spam,
            spam_risk_level=a.spam_risk_level,
            has_sensitive_data=a.has_sensitive_data,
            dlp_sensitivity_level=a.dlp_sensitivity_level,
        )
        for a in alerts
    ]


@app.get("/api/v1/alerts/{alert_id}", response_model=AlertDetailResponse)
async def get_alert_detail(
    alert_id: int,
    user_id: str,
    db: Session = Depends(get_db)
):
    """Get detailed information about a specific alert"""
    
    alert = db.query(Alert).filter(
        Alert.id == alert_id,
        Alert.user_id == user_id
    ).first()
    
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    return AlertDetailResponse(
        id=alert.id,
        alert_type=alert.alert_type,
        source=alert.source,
        direction=alert.direction,
        message_preview=alert.message_preview,
        full_message=alert.full_message,
        timestamp=alert.timestamp,
        is_spam=alert.is_spam,
        spam_confidence=alert.spam_confidence,
        spam_risk_level=alert.spam_risk_level,
        has_sensitive_data=alert.has_sensitive_data,
        dlp_sensitivity_level=alert.dlp_sensitivity_level,
        dlp_categories=json.loads(alert.dlp_categories) if alert.dlp_categories else None,
        dlp_matches=json.loads(alert.dlp_matches) if alert.dlp_matches else None,
        sender=alert.sender,
        recipient=alert.recipient,
        user_action=alert.user_action,
    )


@app.put("/api/v1/alerts/{alert_id}")
async def update_alert_action(
    alert_id: int,
    user_id: str,
    update: AlertUpdateRequest,
    db: Session = Depends(get_db)
):
    """Update user action on an alert (allow, block, report)"""
    
    alert = db.query(Alert).filter(
        Alert.id == alert_id,
        Alert.user_id == user_id
    ).first()
    
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    if update.action not in ['allowed', 'blocked', 'reported']:
        raise HTTPException(status_code=400, detail="Invalid action")
    
    alert.user_action = update.action
    db.commit()
    
    return {"status": "success", "action": update.action}


@app.get("/api/v1/stats/{user_id}")
async def get_user_stats(
    user_id: str,
    days: int = Query(default=30, le=365),
    db: Session = Depends(get_db)
):
    """Get statistics for a user's alerts"""
    
    since = datetime.utcnow() - timedelta(days=days)
    
    alerts = db.query(Alert).filter(
        Alert.user_id == user_id,
        Alert.timestamp >= since
    ).all()
    
    spam_alerts = [a for a in alerts if a.alert_type == AlertType.SPAM.value]
    dlp_alerts = [a for a in alerts if a.alert_type == AlertType.DLP.value]
    
    return {
        "period_days": days,
        "total_alerts": len(alerts),
        "spam": {
            "total": len(spam_alerts),
            "detected": len([a for a in spam_alerts if a.is_spam]),
            "by_source": {
                "sms": len([a for a in spam_alerts if a.source == "sms"]),
                "email": len([a for a in spam_alerts if a.source == "email"]),
                "telegram": len([a for a in spam_alerts if a.source == "telegram"]),
            },
            "by_risk_level": {
                "high": len([a for a in spam_alerts if a.spam_risk_level == "high"]),
                "medium": len([a for a in spam_alerts if a.spam_risk_level == "medium"]),
                "low": len([a for a in spam_alerts if a.spam_risk_level == "low"]),
            }
        },
        "dlp": {
            "total": len(dlp_alerts),
            "with_sensitive_data": len([a for a in dlp_alerts if a.has_sensitive_data]),
            "by_sensitivity": {
                "critical": len([a for a in dlp_alerts if a.dlp_sensitivity_level == "critical"]),
                "high": len([a for a in dlp_alerts if a.dlp_sensitivity_level == "high"]),
                "medium": len([a for a in dlp_alerts if a.dlp_sensitivity_level == "medium"]),
                "low": len([a for a in dlp_alerts if a.dlp_sensitivity_level == "low"]),
            }
        }
    }


# ============== Run Server ==============

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )