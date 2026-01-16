from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uvicorn
from datetime import datetime

# Import your DLP detector (assuming dlp_detector.py is in same directory)
from dlp_detector import DLPDetector

app = FastAPI(
    title="Sifitlier DLP API",
    description="Data Loss Prevention API for detecting sensitive information",
    version="1.0.0"
)

# Enable CORS for Flutter app to access API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize DLP detector
dlp_detector = DLPDetector()

# Request/Response Models
class TextScanRequest(BaseModel):
    text: str
    source: Optional[str] = "manual"  # manual, sms, email, telegram
    
    class Config:
        json_schema_extra = {
            "example": {
                "text": "My credit card is 4532-1234-5678-9010",
                "source": "sms"
            }
        }

class DLPScanResponse(BaseModel):
    success: bool
    timestamp: str
    scan_id: str
    total_detections: int
    risk_score: int
    risk_level: str
    message: str
    detections: list
    original_text_preview: str

# API Endpoints

@app.get("/")
def root():
    """Health check endpoint"""
    return {
        "status": "online",
        "service": "Sifitlier DLP API",
        "version": "1.0.0",
        "endpoints": {
            "scan": "/api/dlp/scan",
            "docs": "/docs"
        }
    }

@app.post("/api/dlp/scan", response_model=DLPScanResponse)
def scan_text(request: TextScanRequest):
    """
    Scan text for sensitive data
    
    Args:
        request: TextScanRequest containing text to scan and source
        
    Returns:
        DLPScanResponse with detection results
    """
    try:
        # Validate input
        if not request.text or len(request.text.strip()) == 0:
            raise HTTPException(status_code=400, detail="Text cannot be empty")
        
        # Perform DLP scan
        detections = dlp_detector.scan_text(request.text)
        summary = dlp_detector.generate_summary(detections)
        
        # Generate unique scan ID (in production, use UUID)
        scan_id = f"scan_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # Create text preview (first 50 chars)
        text_preview = request.text[:50] + "..." if len(request.text) > 50 else request.text
        
        response = DLPScanResponse(
            success=True,
            timestamp=datetime.now().isoformat(),
            scan_id=scan_id,
            total_detections=summary['total_detections'],
            risk_score=summary['risk_score'],
            risk_level=summary['risk_level'],
            message=summary['message'],
            detections=summary['detections'],
            original_text_preview=text_preview
        )
        
        return response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/dlp/patterns")
def get_supported_patterns():
    """
    Get list of all supported sensitive data patterns
    
    Returns:
        List of pattern descriptions and their sensitivity levels
    """
    patterns_info = []
    
    for pattern_name, config in dlp_detector.patterns.items():
        patterns_info.append({
            "id": pattern_name,
            "description": config['description'],
            "sensitivity": config['sensitivity'].value,
            "recommendation": config['recommendation']
        })
    
    return {
        "total_patterns": len(patterns_info),
        "patterns": patterns_info
    }

@app.get("/api/health")
def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "detector_loaded": dlp_detector is not None,
        "total_patterns": len(dlp_detector.patterns)
    }

# Run with: uvicorn main:app --reload --host 0.0.0.0 --port 8000
if __name__ == "__main__":
    uvicorn.run(
        "main_dlp:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )