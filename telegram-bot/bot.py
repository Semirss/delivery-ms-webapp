import os
import logging
import requests
import threading
from flask import Flask, request, jsonify
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    Application, CommandHandler, CallbackQueryHandler, 
    ContextTypes, MessageHandler, filters, ConversationHandler
)
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.INFO
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

TELEGRAM_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "YOUR_BOT_TOKEN")
API_BASE_URL = os.getenv("NEXTJS_API_URL", "http://localhost:3000/api")

# Conversation States for Customer
PICKUP_LOC, DROPOFF_LOC, CONFIRM = range(3)

# ================= CUSTOMER FLOW ================= #

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    keyboard = [
        [InlineKeyboardButton("Request Delivery", callback_data='request_delivery')],
        [InlineKeyboardButton("I am a Driver", callback_data='driver_login')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)

    # Use reply_text for text messages
    if update.message:
        await update.message.reply_text(
            "Welcome to the Delivery MVP! What would you like to do?",
            reply_markup=reply_markup,
        )
    return ConversationHandler.END

async def start_delivery_request(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    query = update.callback_query
    await query.answer()
    
    context.user_data['customer_name'] = update.effective_user.first_name
    
    await query.edit_message_text(text="Let's start your delivery request! Please reply with the pickup location:")
    return PICKUP_LOC

async def get_pickup(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data['pickup_location'] = update.message.text
    await update.message.reply_text("Great. Now, please reply with the drop-off location:")
    return DROPOFF_LOC

async def get_dropoff(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data['dropoff_location'] = update.message.text
    
    pickup = context.user_data['pickup_location']
    dropoff = context.user_data['dropoff_location']
    
    keyboard = [
        [InlineKeyboardButton("Confirm Request", callback_data='confirm_request')],
        [InlineKeyboardButton("Cancel", callback_data='cancel_request')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(
        f"Please confirm your delivery details:\n\n"
        f"📍 Pickup: {pickup}\n"
        f"🏁 Drop-off: {dropoff}\n"
        f"📦 Package: Standard\n"
        f"💵 Est. Fee: $10.00\n\n"
        f"Is this correct?",
        reply_markup=reply_markup
    )
    return CONFIRM

async def confirm_delivery(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    query = update.callback_query
    await query.answer()
    
    if query.data == 'cancel_request':
        await query.edit_message_text("Request cancelled.")
        return ConversationHandler.END
        
    payload = {
        "customer_name": context.user_data.get('customer_name', 'Telegram User'),
        "customer_phone": context.user_data.get('customer_phone', 'via Telegram'),
        "pickup_location": context.user_data['pickup_location'],
        "dropoff_location": context.user_data['dropoff_location'],
        "package_type": "Standard",
        "delivery_fee": 10.00
    }
    
    try:
        response = requests.post(f"{API_BASE_URL}/deliveries", json=payload)
        response.raise_for_status()
        await query.edit_message_text("✅ Your delivery request has been created! A driver will be assigned soon.")
    except Exception as e:
        logger.error(f"Error creating delivery: {e}")
        await query.edit_message_text("❌ Failed to create delivery request. Please try again later.")
        
    return ConversationHandler.END

async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    await update.message.reply_text("Operation cancelled.")
    return ConversationHandler.END

# ================= DRIVER FLOW ================= #

async def driver_login(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    query = update.callback_query
    await query.answer()
    telegram_id = update.effective_user.id
    
    await query.edit_message_text(
        f"Driver portal access. Your Telegram ID is: {telegram_id}.\nProvide this to the Admin for assignment."
    )

async def driver_action(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    query = update.callback_query
    await query.answer()
    
    data = query.data # format: action_deliveryId
    action, delivery_id = data.split('_', 1)
    
    new_status = ""
    if action == "accept":
        new_status = "Picked Up"
    elif action == "pickedup":
        new_status = "Delivered"
        
    # TODO: Update DB through Next.js API
    # requests.post(f"{API_BASE_URL}/deliveries/{delivery_id}/status", json={"status": new_status})
    
    if action == "accept":
        keyboard = [[InlineKeyboardButton("Mark as Delivered", callback_data=f"pickedup_{delivery_id}")]]
        await query.edit_message_text("Delivery Accepted! Click when delivered.", reply_markup=InlineKeyboardMarkup(keyboard))
    elif action == "pickedup":
        await query.edit_message_text("Delivery Marked as Completed! 🏁")


# ================= FLASK KEEP-ALIVE & WEBHOOK ================= #

@app.route("/")
def index():
    return "Delivery MVP Telegram Bot is running via Flask."

@app.route("/webhook/notify", methods=["POST"])
def notify_driver():
    """Endpoint called by Next.js when a driver is assigned."""
    data = request.json
    driver_telegram_id = data.get('driver', {}).get('telegram_id')
    delivery_id = data.get('id')
    pickup = data.get('pickup_location')
    dropoff = data.get('dropoff_location')
    
    if not driver_telegram_id:
        return jsonify({"error": "No telegram_id for driver"}), 400
        
    telegram_api_url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    
    keyboard = {
        "inline_keyboard": [
            [{"text": "Accept Delivery", "callback_data": f"accept_{delivery_id}"}]
        ]
    }
    
    payload = {
        "chat_id": driver_telegram_id,
        "text": f"🚨 NEW DELIVERY ASSIGNED 🚨\n\n📍 Pickup: {pickup}\n🏁 Drop-off: {dropoff}",
        "reply_markup": keyboard
    }
    
    requests.post(telegram_api_url, json=payload)
    return jsonify({"success": True})


def main() -> None:
    application = Application.builder().token(TELEGRAM_TOKEN).build()

    conv_handler = ConversationHandler(
        entry_points=[
            CommandHandler('start', start),
            CallbackQueryHandler(start_delivery_request, pattern='^request_delivery$')
        ],
        states={
            PICKUP_LOC: [MessageHandler(filters.TEXT & ~filters.COMMAND, get_pickup)],
            DROPOFF_LOC: [MessageHandler(filters.TEXT & ~filters.COMMAND, get_dropoff)],
            CONFIRM: [CallbackQueryHandler(confirm_delivery, pattern='^(confirm_request|cancel_request)$')]
        },
        fallbacks=[CommandHandler('cancel', cancel)]
    )

    application.add_handler(conv_handler)
    application.add_handler(CallbackQueryHandler(driver_login, pattern='^driver_login$'))
    application.add_handler(CallbackQueryHandler(driver_action, pattern='^(accept|pickedup)_.*$'))

    # Start bot polling in the main thread
    print("Starting bot polling...")
    application.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    # Run flask in a separate thread so polling can run in main thread
    def run_flask():
        port = int(os.environ.get("PORT", 5000))
        app.run(host="0.0.0.0", port=port, use_reloader=False)

    flask_thread = threading.Thread(target=run_flask)
    flask_thread.daemon = True
    flask_thread.start()

    main()
