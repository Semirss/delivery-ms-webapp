import os
import logging
import requests
import threading
from flask import Flask, request, jsonify
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup, ReplyKeyboardMarkup
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

# --- CONVERSATION STATES ---
# Customer Flow
CUST_NAME, CUST_PHONE, CUST_PICKUP, CUST_DROPOFF, CUST_PACKAGE, CUST_CONFIRM = range(6)
# Driver Auth Flow
DRV_AUTH_CHOICE, DRV_LOGIN_NAME, DRV_LOGIN_PASS, DRV_SIGNUP_NAME, DRV_SIGNUP_PHONE, DRV_SIGNUP_PASS = range(6, 12)

# ================= CUSTOMER FLOW ================= #

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    keyboard = [
        [InlineKeyboardButton("📦 Request Delivery", callback_data='flow_customer')],
        [InlineKeyboardButton("🚲 I am a Driver", callback_data='flow_driver')]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)

    if update.message:
        await update.message.reply_text(
            "Welcome to SwiftDispatch! 🚲\nHow can we help you today?",
            reply_markup=reply_markup,
        )
    return ConversationHandler.END


# --- CUSTOMER REQUEST BUILDER ---
async def start_customer_flow(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    query = update.callback_query
    await query.answer()
    
    # Try to extract name if available, otherwise ask
    name = update.effective_user.first_name
    if name:
        context.user_data['customer_name'] = name
        await query.edit_message_text("Let's get your delivery sorted! Please reply with your Phone Number:")
        return CUST_PHONE
    else:
        await query.edit_message_text("Let's get your delivery sorted! Please reply with your Full Name:")
        return CUST_NAME

async def cust_get_name(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data['customer_name'] = update.message.text
    await update.message.reply_text("Thanks! Please reply with your Phone Number:")
    return CUST_PHONE

async def cust_get_phone(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data['customer_phone'] = update.message.text
    await update.message.reply_text("Great. Where are we picking the package up from? (Reply with pickup address)")
    return CUST_PICKUP

async def cust_get_pickup(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data['pickup_location'] = update.message.text
    await update.message.reply_text("Got it. Where are we dropping it off? (Reply with drop-off address)")
    return CUST_DROPOFF

async def cust_get_dropoff(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data['dropoff_location'] = update.message.text
    
    keyboard = [
        [InlineKeyboardButton("Documents", callback_data='pkg_Documents'), InlineKeyboardButton("Small Box", callback_data='pkg_Small Box')],
        [InlineKeyboardButton("Food/Groceries", callback_data='pkg_Food/Groceries'), InlineKeyboardButton("Electronics", callback_data='pkg_Electronics')],
        [InlineKeyboardButton("Other", callback_data='pkg_Other')]
    ]
    await update.message.reply_text("Almost done. What type of package is this?", reply_markup=InlineKeyboardMarkup(keyboard))
    return CUST_PACKAGE

async def cust_get_package(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    query = update.callback_query
    await query.answer()
    pkg_type = query.data.replace('pkg_', '')
    context.user_data['package_type'] = pkg_type
    
    return await render_customer_confirmation(query, context)

async def render_customer_confirmation(query, context) -> int:
    name = context.user_data.get('customer_name')
    phone = context.user_data.get('customer_phone')
    pickup = context.user_data.get('pickup_location')
    dropoff = context.user_data.get('dropoff_location')
    pkg = context.user_data.get('package_type')
    
    keyboard = [
        [InlineKeyboardButton("✅ Confirm Request", callback_data='confirm_request')],
        [InlineKeyboardButton("✏️ Edit Details", callback_data='edit_request')],
        [InlineKeyboardButton("❌ Cancel", callback_data='cancel_request')]
    ]
    
    text = (
        f"📋 Please confirm your delivery details:\n\n"
        f"👤 Name: {name}\n"
        f"📞 Phone: {phone}\n"
        f"🟢 Pickup: {pickup}\n"
        f"📍 Drop-off: {dropoff}\n"
        f"📦 Package: {pkg}\n\n"
        f"Is everything correct?"
    )
    
    if query.message.text:
        await query.edit_message_text(text, reply_markup=InlineKeyboardMarkup(keyboard))
    else: # If replacing an inline keyboard from previous msg
        await query.message.reply_text(text, reply_markup=InlineKeyboardMarkup(keyboard))
        
    return CUST_CONFIRM

async def cust_confirm(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    query = update.callback_query
    await query.answer()
    
    if query.data == 'cancel_request':
        await query.edit_message_text("❌ Request cancelled.")
        return ConversationHandler.END
        
    if query.data == 'edit_request':
        await query.edit_message_text("Let's start over. Please reply with the pickup location:")
        return CUST_PICKUP
        
    payload = {
        "customer_name": context.user_data.get('customer_name'),
        "customer_phone": context.user_data.get('customer_phone'),
        "pickup_location": context.user_data.get('pickup_location'),
        "dropoff_location": context.user_data.get('dropoff_location'),
        "package_type": context.user_data.get('package_type'),
        "delivery_fee": None # Handled manually later
    }
    
    try:
        response = requests.post(f"{API_BASE_URL}/deliveries", json=payload)
        response.raise_for_status()
        await query.edit_message_text(
            "🎉 Your delivery request has been dispatched!\n\n"
            "An available bike courier will be assigned shortly. They will contact you regarding the delivery fee."
        )
    except Exception as e:
        logger.error(f"Error creating delivery: {e}")
        await query.edit_message_text("⚠️ Failed to create delivery request. Please try again later.")
        
    return ConversationHandler.END

async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    await update.message.reply_text("Process cancelled. Send /start to begin again.")
    return ConversationHandler.END


# ================= DRIVER FLOW & AUTH ================= #

async def start_driver_flow(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    query = update.callback_query
    await query.answer()
    
    # Check if already logged in via memory
    if context.user_data.get('is_driver_logged_in'):
        await show_driver_menu(query.message, context)
        return ConversationHandler.END

    keyboard = [
        [InlineKeyboardButton("🔑 Log In", callback_data='drv_login')],
        [InlineKeyboardButton("📝 Sign Up", callback_data='drv_signup')]
    ]
    await query.edit_message_text(
        "Welcome to the Driver Portal.\nAre you an existing driver or looking to join the fleet?",
        reply_markup=InlineKeyboardMarkup(keyboard)
    )
    return DRV_AUTH_CHOICE

async def drv_auth_choice(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    query = update.callback_query
    await query.answer()
    
    if query.data == 'drv_login':
        await query.edit_message_text("Please reply with your Driver Full Name:")
        return DRV_LOGIN_NAME
    elif query.data == 'drv_signup':
        await query.edit_message_text("Excited to have you! Please reply with your Full Name:")
        return DRV_SIGNUP_NAME
    return ConversationHandler.END

# --- LOGIN ---
async def drv_login_name(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data['try_login_name'] = update.message.text
    await update.message.reply_text("Please reply with your Password:")
    return DRV_LOGIN_PASS

async def drv_login_pass(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    password = update.message.text
    name = context.user_data.get('try_login_name')
    
    try:
        # Check login against the Next API
        res = requests.post(f"{API_BASE_URL}/drivers/login", json={"name": name, "password": password})
        
        if res.status_code != 200:
            await update.message.reply_text("❌ Invalid name or password. Try /start again.")
            return ConversationHandler.END
            
        driver_data = res.json()
        
        if driver_data.get('approval_status') == 'Pending':
            await update.message.reply_text(
                "⏳ Your account is currently Pending Approval.\n\n"
                "You cannot login until the admin approves your account. You will receive a notification here when approved."
            )
            return ConversationHandler.END
            
        # Success Login
        context.user_data['is_driver_logged_in'] = True
        context.user_data['driver_id'] = driver_data.get('id')
        context.user_data['driver_name'] = driver_data.get('name')
        
        # Link their telegram ID if not linked
        telegram_id = str(update.effective_chat.id)
        if driver_data.get('telegram_id') != telegram_id:
            requests.patch(f"{API_BASE_URL}/drivers/{driver_data.get('id')}", json={"telegram_id": telegram_id})
        
        await update.message.reply_text(f"✅ Login successful! Welcome back, {name}.")
        await show_driver_menu(update.message, context)
        
    except Exception as e:
        logger.error(f"Login error: {e}")
        await update.message.reply_text("⚠️ System error during login. Try again later.")
        
    return ConversationHandler.END

# --- SIGNUP ---
async def drv_signup_name(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data['signup_name'] = update.message.text
    await update.message.reply_text("Please reply with your Phone Number:")
    return DRV_SIGNUP_PHONE

async def drv_signup_phone(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data['signup_phone'] = update.message.text
    await update.message.reply_text("Please reply with a Password you want to use for your account:")
    return DRV_SIGNUP_PASS

async def drv_signup_pass(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    password = update.message.text
    name = context.user_data.get('signup_name')
    phone = context.user_data.get('signup_phone')
    telegram_id = str(update.effective_chat.id)
    
    payload = {
        "name": name,
        "phone": phone,
        "password": password,
        "telegram_id": telegram_id,
        "status": "Offline",
        "approval_status": "Pending"
    }
    
    try:
        res = requests.post(f"{API_BASE_URL}/drivers", json=payload)
        res.raise_for_status()
        await update.message.reply_text(
            "📝 Signup successful!\n\n"
            "⏳ Waiting for approval. You cannot login until the admin approves your account.\n"
            "You will be notified right here when your account is ready."
        )
    except Exception as e:
        logger.error(f"Signup error: {e}")
        await update.message.reply_text("❌ Failed to create account. You may already have an account using this Telegram Profile. Try logging in.")
        
    return ConversationHandler.END


# --- DRIVER MENU COMMANDS ---
async def show_driver_menu(message, context):
    name = context.user_data.get('driver_name', '')
    # Send a persistent reply keyboard for Online/Offline actions and Logout
    keyboard = [
        ["🟢 Go Online", "🔴 Go Offline"],
        ["🚪 Logout"]
    ]
    markup = ReplyKeyboardMarkup(keyboard, resize_keyboard=True)
    await message.reply_text(f"Hey {name}! Use the menu below to manage your dispatch status.", reply_markup=markup)

async def toggle_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.user_data.get('is_driver_logged_in'):
        await update.message.reply_text("You must be logged in as a driver. Send /start")
        return

    text = update.message.text
    driver_id = context.user_data.get('driver_id')
    new_status = "Online" if "Online" in text else "Offline"
    
    try:
        requests.patch(f"{API_BASE_URL}/drivers/{driver_id}", json={"status": new_status})
        await update.message.reply_text(f"✅ Status updated to: {new_status}")
    except Exception as e:
         await update.message.reply_text("❌ Failed to update status.")

async def logout_driver(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if context.user_data.get('is_driver_logged_in'):
        context.user_data.clear()
        from telegram import ReplyKeyboardRemove
        await update.message.reply_text("🚪 Logged out successfully.", reply_markup=ReplyKeyboardRemove())
    else:
        await update.message.reply_text("You are not logged in.")


# ================= FLASK KEEP-ALIVE ================= #

@app.route("/")
def index():
    return "SwiftDispatch Telegram Bot is running."

# Keep original webhook for future proofing if Next sends notifications directly to bot server
@app.route("/webhook/notify", methods=["POST"])
def notify_driver():
    return jsonify({"success": True})

async def main() -> None:
    application = Application.builder().token(TELEGRAM_TOKEN).build()

    # CUSTOMER FLOW
    cust_handler = ConversationHandler(
        entry_points=[CallbackQueryHandler(start_customer_flow, pattern='^flow_customer$')],
        states={
            CUST_NAME: [MessageHandler(filters.TEXT & ~filters.COMMAND, cust_get_name)],
            CUST_PHONE: [MessageHandler(filters.TEXT & ~filters.COMMAND, cust_get_phone)],
            CUST_PICKUP: [MessageHandler(filters.TEXT & ~filters.COMMAND, cust_get_pickup)],
            CUST_DROPOFF: [MessageHandler(filters.TEXT & ~filters.COMMAND, cust_get_dropoff)],
            CUST_PACKAGE: [CallbackQueryHandler(cust_get_package, pattern='^pkg_')],
            CUST_CONFIRM: [CallbackQueryHandler(cust_confirm, pattern='^(confirm_request|cancel_request|edit_request)$')]
        },
        fallbacks=[CommandHandler('cancel', cancel)]
    )
    
    # DRIVER AUTH FLOW
    drv_handler = ConversationHandler(
        entry_points=[CallbackQueryHandler(start_driver_flow, pattern='^flow_driver$')],
        states={
            DRV_AUTH_CHOICE: [CallbackQueryHandler(drv_auth_choice, pattern='^(drv_login|drv_signup)$')],
            DRV_LOGIN_NAME: [MessageHandler(filters.TEXT & ~filters.COMMAND, drv_login_name)],
            DRV_LOGIN_PASS: [MessageHandler(filters.TEXT & ~filters.COMMAND, drv_login_pass)],
            DRV_SIGNUP_NAME: [MessageHandler(filters.TEXT & ~filters.COMMAND, drv_signup_name)],
            DRV_SIGNUP_PHONE: [MessageHandler(filters.TEXT & ~filters.COMMAND, drv_signup_phone)],
            DRV_SIGNUP_PASS: [MessageHandler(filters.TEXT & ~filters.COMMAND, drv_signup_pass)],
        },
        fallbacks=[CommandHandler('cancel', cancel)]
    )

    application.add_handler(CommandHandler('start', start))
    application.add_handler(cust_handler)
    application.add_handler(drv_handler)
    
    # Persistent Driver menu buttons
    application.add_handler(MessageHandler(filters.Regex('^(🟢 Go Online|🔴 Go Offline)$'), toggle_status))
    application.add_handler(MessageHandler(filters.Regex('^🚪 Logout$'), logout_driver))

    print("Starting bot polling...")
    # PTB 21.x + Python 3.14: use async context manager + explicit polling
    async with application:
        await application.start()
        await application.updater.start_polling(allowed_updates=Update.ALL_TYPES)
        print("Bot is live. Waiting for updates...")
        # Run forever until process is killed
        import asyncio as _asyncio
        await _asyncio.sleep(float('inf'))

if __name__ == "__main__":
    import asyncio

    def run_flask():
        port = int(os.environ.get("PORT", 5000))
        app.run(host="0.0.0.0", port=port, use_reloader=False)

    flask_thread = threading.Thread(target=run_flask)
    flask_thread.daemon = True
    flask_thread.start()

    asyncio.run(main())
