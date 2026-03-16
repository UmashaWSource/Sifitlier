"""
Sifitlier Telegram Bot
Scans messages for spam and sensitive data
Developed by Umasha Wijenayake
"""

import os
import sys
import asyncio
import logging
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, MessageHandler, CallbackQueryHandler, filters, ContextTypes

# ================================================================================
# ENVIRONMENT CONFIGURATION
# ================================================================================
# Load environment variables from .env file for secure token management
# This prevents hardcoding sensitive data in the source code
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # dotenv not installed, will use system env vars

# Import detectors
from train_spam_classifier import SpamClassifier  # ML-based spam detection
from dlp_detector import DLPDetector              # Regex-based sensitive data detection

# ================================================================================
# LOGGING CONFIGURATION
# ================================================================================
# Set up logging to track bot activity and debug issues
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# ================================================================================
# BOT TOKEN CONFIGURATION
# ================================================================================
# SECURITY: Token is loaded from environment variable, NOT hardcoded
# This allows safe pushing to GitHub without exposing credentials
BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")

# Validate token exists before starting
if not BOT_TOKEN:
    logger.error("❌ ERROR: TELEGRAM_BOT_TOKEN not set!")
    logger.error("Please set the token using one of these methods:")
    logger.error("  1. Create a .env file with: TELEGRAM_BOT_TOKEN=your_token_here")
    logger.error("  2. Set environment variable: export TELEGRAM_BOT_TOKEN=your_token_here")
    sys.exit(1)

# Initialize ML models
spam_classifier = SpamClassifier()
dlp_detector = DLPDetector()

# Load spam model
MODEL_PATH = "spam_classifier_pipeline.pkl"
if os.path.exists(MODEL_PATH):
    try:
        spam_classifier.load(MODEL_PATH)
        logger.info("✅ Spam classifier loaded for Telegram bot")
    except Exception as e:
        logger.warning(f"⚠️ Failed to load spam classifier: {e}")
else:
    logger.warning("⚠️ Spam model not found for Telegram bot")


# ================================================================================
# COMMAND HANDLERS
# ================================================================================
# These functions handle specific bot commands (e.g., /start, /help)
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Send welcome message when /start is issued"""
    welcome_text = (
        "🛡️ Welcome to Sifitlier Security Bot!\n\n"
        "I help you stay safe by scanning messages for:\n"
        "•  Spam & Phishing attempts\n"
        "•  Sensitive data leaks (passwords, credit cards, etc.)\n\n"
        "How to use:\n"
        "1️⃣ Forward any suspicious message to me\n"
        "2️⃣ Or paste/type a message directly\n"
        "3️⃣ I'll analyze it and tell you if it's safe!\n\n"
        "Commands:\n"
        "/start - Show this welcome message\n"
        "/help - How to use this bot\n"
        "/spam - Check a message for spam\n"
        "/dlp - Check for sensitive data\n"
        "/about - About Sifitlier\n"
        "/cancel - Cancel current operation\n"
        "/feedback - Send feedback\n\n"
        "Stay safe! 🔒"
    )
    await update.message.reply_text(welcome_text)


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Send help message"""
    help_text = (
        "🆘 How to Use Sifitlier Bot\n\n"
        "Option 1: Forward a Message\n"
        "Simply forward any suspicious SMS, email, or message to me.\n\n"
        "Option 2: Type/Paste Directly\n"
        "Just send me the text you want to check.\n\n"
        "Option 3: Use Commands\n"
        "• /spam <message> - Check for spam/phishing\n"
        "• /dlp <message> - Check for sensitive data\n\n"
        "Examples:\n"
        "/spam Congratulations! You won $1000! Click here to claim\n"
        "/dlp My password is Secret123\n\n"
        "Other Commands:\n"
        "• /cancel - Cancel current operation\n"
        "• /feedback <message> - Send us feedback\n\n"
        "I'll analyze the message and give you a detailed report! "
    )
    await update.message.reply_text(help_text)


async def about(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Send about information"""
    about_text = (
        "🛡️ About Sifitlier\n\n"
        "Sifitlier is an AI-powered mobile security solution designed to protect users from digital threats in real-time.\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        " What We Protect You From:\n"
        "•  Spam messages & Phishing attacks\n"
        "•  Social engineering attempts\n"
        "•  Accidental sensitive data leaks\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        " Key Features:\n"
        "• Machine Learning spam detection\n"
        "• Real-time DLP (Data Loss Prevention)\n"
        "• Multi-platform support (SMS, Email, Telegram)\n"
        "• Instant threat analysis\n"
        "• Privacy-focused design\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        " Developed by: Umasha Wijenayake\n"
        " Project: Final Year Project\n"
        " Purpose: AI-Powered Mobile Security Research\n"
        " Version: 1.0.0\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n\n"
        " Get Full Protection:\n"
        "Download our mobile app for comprehensive security features including real-time SMS monitoring, email scanning, and more!\n\n"
        " Your security is our priority"
    )
    await update.message.reply_text(about_text)


async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Cancel current operation"""
    context.user_data.clear()
    await update.message.reply_text(
        "✅ Operation cancelled.\n\n"
        "All pending operations have been cleared.\n"
        "Send /start to begin again or just send me a message to scan."
    )


async def feedback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle user feedback"""
    if not context.args:
        await update.message.reply_text(
            " Send Feedback\n\n"
            "We value your input! Let us know how we can improve.\n\n"
            "Usage: /feedback <your message>\n\n"
            "Example: /feedback The bot is great but needs faster response"
        )
        return
    
    feedback_text = ' '.join(context.args)
    user = update.effective_user
    
    # Log feedback
    logger.info(f" Feedback from {user.username or user.id}: {feedback_text}")
    
    await update.message.reply_text(
        "✅ Thank you for your feedback!\n\n"
        "Your input helps us improve Sifitlier and make it better for everyone.\n\n"
        "We appreciate you taking the time to share your thoughts! "
    )


# ================================================================================
# SCAN COMMAND HANDLERS
# ================================================================================
# These functions handle the /spam and /dlp scanning commands

async def check_spam_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Check message for spam using /spam command"""
    if not context.args:
        await update.message.reply_text(
            "⚠️ Please provide a message to check.\n\n"
            "Usage: /spam <your message here>\n\n"
            "Example: /spam You won a free iPhone! Click here now!"
        )
        return
    
    message = ' '.join(context.args)
    await analyze_for_spam(update, message)


async def check_dlp_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Check message for sensitive data using /dlp command"""
    if not context.args:
        await update.message.reply_text(
            "⚠️ Please provide a message to check.\n\n"
            "Usage: /dlp <your message here>\n\n"
            "Example: /dlp My password is Secret123"
        )
        return
    
    message = ' '.join(context.args)
    await analyze_for_dlp(update, message)


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle any text message - analyze directly for both spam and DLP"""
    message = update.message.text
    
    # Store message for reference
    context.user_data['last_message'] = message
    
    # Analyze directly for both spam and DLP
    await update.message.reply_text(" Analyzing message...")
    
    try:
        # Spam analysis
        spam_result = "⚠️ Unavailable"
        spam_details = ""
        if spam_classifier.pipeline:
            result = spam_classifier.predict(message)
            if result['is_spam']:
                spam_result = "🚨 SPAM DETECTED"
                spam_details = (
                    f"\n   - Risk: {result['risk_level'].upper()}"
                    f"\n   - Confidence: {result['confidence']*100:.0f}%"
                )
            else:
                spam_result = f"✅ Safe ({result['confidence']*100:.0f}% confidence)"
                spam_details = ""
        
        # DLP analysis
        dlp_result_data = dlp_detector.analyze(message)
        if dlp_result_data['has_sensitive_data']:
            categories = ', '.join(dlp_result_data['categories'][:2]) if dlp_result_data['categories'] else 'Unknown'
            dlp_result = "🔐 SENSITIVE DATA FOUND"
            dlp_details = (
                f"\n   - Level: {dlp_result_data['sensitivity_level'].upper()}"
                f"\n   - Type: {categories}"
            )
        else:
            dlp_result = "✅ No sensitive data"
            dlp_details = ""
        
        response = (
            "🛡️ SCAN RESULTS\n"
            "━━━━━━━━━━━━━━━\n\n"
            f"Spam Check: {spam_result}{spam_details}\n\n"
            f"DLP Check: {dlp_result}{dlp_details}\n\n"
            "━━━━━━━━━━━━━━━\n"
            "💡 Use /spam or /dlp for detailed analysis"
        )
        
        await update.message.reply_text(response)
        
    except Exception as e:
        logger.error(f"Analysis error: {e}")
        await update.message.reply_text(
            "❌ Error analyzing message\n\n"
            "Please try again or use /spam or /dlp commands directly."
        )


# ============== Analysis Functions ==============

async def analyze_for_spam(update: Update, message: str):
    """Analyze message for spam and send result"""
    await update.message.reply_text(" Analyzing for spam...")
    
    try:
        if spam_classifier.pipeline:
            result = spam_classifier.predict(message)
            
            if result['is_spam']:
                response = (
                    "🚨 SPAM DETECTED!\n\n"
                    f"Risk Level: {result['risk_level'].upper()}\n"
                    f"Confidence: {result['confidence']*100:.1f}%\n"
                    f"Spam Probability: {result['spam_probability']*100:.1f}%\n\n"
                    "⚠️ Warning: This message appears to be spam or phishing.\n"
                    "Do NOT click any links or share personal information!\n\n"
                    "━━━━━━━━━━━━━━━\n"
                    "🛡️ Stay vigilant, stay safe!"
                )
            else:
                response = (
                    "✅ Message appears SAFE\n\n"
                    f"Risk Level: {result['risk_level'].upper()}\n"
                    f"Confidence: {result['confidence']*100:.1f}%\n"
                    f"Spam Probability: {result['spam_probability']*100:.1f}%\n\n"
                    "This message doesn't show typical spam patterns.\n"
                    "Still, always be cautious with unknown senders!\n\n"
                    "━━━━━━━━━━━━━━━\n"
                    "🛡️ Stay vigilant, stay safe!"
                )
        else:
            response = "⚠️ Spam classifier not available. Please try again later."
            
    except Exception as e:
        logger.error(f"Spam analysis error: {e}")
        response = "❌ Error analyzing message. Please try again."
    
    await update.message.reply_text(response)


async def analyze_for_dlp(update: Update, message: str):
    """Analyze message for sensitive data"""
    await update.message.reply_text(" Checking for sensitive data...")
    
    try:
        result = dlp_detector.analyze(message)
        
        if result['has_sensitive_data']:
            categories = ', '.join(result['categories']) if result['categories'] else 'Unknown'
            response = (
                "🔐 SENSITIVE DATA DETECTED!\n\n"
                f"Sensitivity Level: {result['sensitivity_level'].upper()}\n"
                f"Categories Found: {categories}\n"
                f"Total Matches: {result['total_matches']}\n\n"
                f"⚠️ Recommendation: {result['recommendation']}\n\n"
                "Please remove sensitive information before sharing!\n\n"
                "━━━━━━━━━━━━━━━\n"
                "🛡️ Protect your personal data!"
            )
        else:
            response = (
                "✅ No Sensitive Data Found\n\n"
                f"Sensitivity Level: {result['sensitivity_level'].upper()}\n\n"
                "This message appears safe to share. No passwords, credit cards, or personal identifiers were detected.\n\n"
                "━━━━━━━━━━━━━━━\n"
                "🛡️ Stay vigilant, stay safe!"
            )
            
    except Exception as e:
        logger.error(f"DLP analysis error: {e}")
        response = "❌ Error analyzing message. Please try again."
    
    await update.message.reply_text(response)


# ============== Error Handler ==============

async def error_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle errors"""
    logger.error(f"Exception while handling an update: {context.error}")
    
    # Send message to user
    if update and update.effective_message:
        await update.effective_message.reply_text(
            "❌ Oops! Something went wrong.\n\n"
            "Please try again or use a different command.\n"
            "If the problem persists, use /feedback to report it."
        )


# ============== Main ==============

def run_bot():
    """Run the Telegram bot"""
    logger.info("🚀 Starting Sifitlier Telegram Bot...")
    
    # Create application
    application = Application.builder().token(BOT_TOKEN).build()
    
    # Add command handlers
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("about", about))
    application.add_handler(CommandHandler("spam", check_spam_command))
    application.add_handler(CommandHandler("dlp", check_dlp_command))
    application.add_handler(CommandHandler("cancel", cancel))
    application.add_handler(CommandHandler("feedback", feedback))
    
    # Add message handler for non-command messages
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    # Add error handler
    application.add_error_handler(error_handler)
    
    # Run bot
    logger.info("✅ Bot is running! Press Ctrl+C to stop.")
    application.run_polling(allowed_updates=Update.ALL_TYPES)


# ================================================================================
# SCRIPT EXECUTION
# ================================================================================
# Only run the bot if this file is executed directly (not imported)
if __name__ == "__main__":
    run_bot()