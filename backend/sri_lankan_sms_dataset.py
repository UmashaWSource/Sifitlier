"""
Sri Lankan SMS Dataset Generator
=================================
Generates 1000+ labeled SMS messages reflecting real Sri Lankan messaging patterns.
Combined with the UCI dataset for training a model that works on actual SL phones.

Categories:
SPAM: loan scams, carrier promos, food deals, retail promos, education spam,
      investment scams, phishing, contest spam
HAM:  bank alerts, ride apps, e-commerce, personal (Singlish), university,
      government, receipts, OTPs, family, work
"""

import random
import pandas as pd


def generate_dataset():
    """Generate labeled Sri Lankan SMS dataset"""

    spam_messages = []
    ham_messages = []

    # ================================================================
    # SPAM: Loan Scams (Singlish/Sinhala-English mix)
    # ================================================================
    loan_templates = [
        "Rs.{amount} k dakwa nayak kalin anumatha kara aetha! Salli ganna: https://f1na.com/{code}",
        "{amount} LKR rin - wadiya honda 0.01%! Danma balanna: https://f1na.com/{code}",
        "Vegavat saha pahasu! 0.01% poliyata rupiyal {amount} dakva naya https://f1na.com/{code}",
        "Oba Rs.{amount} dක්වා ණයක් ලබාගැනීමට සුදුසුකම් ලබයි! දැන්ම apply කරන්න: https://f1na.com/{code}",
        "URGENT: Rs.{amount} loan approved! No documents needed. Click: https://quickloan.lk/{code}",
        "Congratulations! You qualify for Rs.{amount} instant loan at 0% interest! Apply: https://f1na.com/{code}",
        "Rs.{amount} personal loan, no guarantors! Instant approval. Visit: https://easyloan.lk/{code}",
        "SPECIAL: Get Rs.{amount} within 1 hour! Lowest interest rate. https://f1na.com/{code}",
        "Obe namata Rs.{amount} loan ekak ready! Araganna: https://f1na.com/{code}",
        "Apita call karanna Rs.{amount} loan ekak ganna. 0% interest for 3 months! {phone}",
        "Need cash? Rs.{amount} approved for you! No salary slip needed. Click NOW: https://f1na.com/{code}",
        "Your loan of Rs.{amount} has been pre-approved! Claim before midnight: https://f1na.com/{code}",
    ]
    for _ in range(60):
        t = random.choice(loan_templates)
        msg = t.format(
            amount=random.choice(["50,000", "100,000", "150,000", "200,000", "250,000", "500,000", "100 000", "250 000"]),
            code=''.join(random.choices('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOP0123456789', k=7)),
            phone=f"07{random.randint(10000000, 99999999)}"
        )
        spam_messages.append(msg)

    # ================================================================
    # SPAM: Carrier/Telecom Promos
    # ================================================================
    carrier_promos = [
        "Dialog: Activate Rs.{price} YouTube pack! Unlimited YouTube for 30 days. Dial #678*{num}#",
        "Dialog: Get {gb}GB for just Rs.{price}! Dial #{num}# to activate. Valid {days} days.",
        "Mobitel: Reload Rs.{price} and get {gb}GB bonus data FREE! Valid for {days} days. T&C apply.",
        "Mobitel: {gb}GB data + Unlimited calls for Rs.{price}/month! Activate now: Dial #{num}#",
        "Hutch: Super Saver! {gb}GB data only Rs.{price}. Dial *{num}# Valid {days} days.",
        "Airtel: Weekend blast! {gb}GB data Rs.{price} only. Activate *{num}#. T&C apply.",
        "Dialog TV: Watch IPL LIVE! Subscribe Sports Pack Rs.{price}/month. Dial #{num}#",
        "Dialog: Flash deal! Unlimited data midnight-6am for just Rs.{price}. Today only!",
        "Mobitel: Smart Postpaid plan! {gb}GB + unlimited talk for Rs.{price}. Visit nearest outlet.",
        "Dialog 4G: Upgrade to fiber Rs.{price}/month. 100Mbps unlimited. Call 1777.",
        "Hutch: Birthday offer! Get DOUBLE data on any reload today. Happy Birthday from Hutch!",
        "Dialog: Your data balance is low. Recharge Rs.{price} for {gb}GB. Dial #{num}#",
    ]
    for _ in range(80):
        t = random.choice(carrier_promos)
        msg = t.format(
            price=random.choice(["49", "99", "149", "199", "299", "399", "499", "599"]),
            gb=random.choice(["1", "2", "3", "5", "10", "15", "20"]),
            num=random.randint(100, 999),
            days=random.choice(["7", "14", "28", "30"])
        )
        spam_messages.append(msg)

    # ================================================================
    # SPAM: Food & Restaurant Promos
    # ================================================================
    food_promos = [
        "It's MEGA MONDAY! Buy any Large Pizza & get {pct}% OFF on your next item. Visit or call 0112729729. Pizza Hut",
        "Pizza Hut: Buy 1 Get 1 FREE on all Medium pizzas! Valid today only. Order: 0112729729",
        "KFC: {pct}% OFF on Zinger Burger combo! Order now on UberEats or call {phone}",
        "McDonald's: McDelivery special! Free McFlurry with any meal over Rs.{amount}. Order app.",
        "Chinese Dragon Cafe: {pct}% OFF on Dolphin Rice till {date}! Now just Rs.{amount}! Order: {url}",
        "Enjoy {pct}% OFF at BreadTalk on all cakes this weekend! Visit nearest outlet.",
        "Domino's: Buy any 2 Pizzas for just Rs.{amount}! Free delivery. Call 0112303030",
        "Burger King: Whopper Wednesday! Rs.{amount} for Whopper meal. Today only!",
        "Cargills Food City: Fresh fruits & vegetables {pct}% OFF every Tuesday!",
        "Subway: Buy one get one {pct}% OFF on all 6-inch subs. Valid this week.",
    ]
    for _ in range(50):
        t = random.choice(food_promos)
        msg = t.format(
            pct=random.choice(["20", "25", "30", "40", "50"]),
            phone=f"011{random.randint(1000000, 9999999)}",
            amount=random.choice(["500", "700", "900", "1200", "1500", "1990", "2500"]),
            date=f"{random.randint(1,28)}/{random.randint(1,12)}",
            url=f"https://bit.ly/{''.join(random.choices('abcdefghijklmnop23456789', k=7))}"
        )
        spam_messages.append(msg)

    # ================================================================
    # SPAM: Retail & Supermarket Promos
    # ================================================================
    retail_promos = [
        "Enjoy {pct}% OFF on Fresh Vegetables, Fruits, Seafood & Meat @ Softlogic GLOMARK with SAMPATH Debit Cards EVERY MONDAY!",
        "Keells Super: {pct}% OFF on selected items this weekend! Don't miss out. T&C apply.",
        "Arpico: MEGA SALE! Up to {pct}% OFF on electronics, furniture & more. Visit nearest showroom.",
        "Abans: Year-end clearance! {pct}% OFF on washing machines & refrigerators. Limited stock!",
        "Singer: Easy payment plans from Rs.{amount}/month. No down payment! Visit singer.lk",
        "Damro: {pct}% OFF on all furniture! Free delivery islandwide. Call 0112{num}",
        "Laugfs Supermarket: Buy 2 get 1 FREE on selected grocery items. This weekend only!",
        "DSI Shoes: {pct}% OFF storewide! Valid at all outlets till {date}. T&C apply.",
        "Fashion Bug: New arrivals! {pct}% OFF on all ladies wear. Shop now at fashionbug.lk",
        "Softlogic: iPhone 15 just Rs.{amount}/month with 0% interest. Visit softlogic.lk",
        "CIB: Credit card offer! {pct}% OFF at partner merchants. Use code SAVE{num}",
    ]
    for _ in range(50):
        t = random.choice(retail_promos)
        msg = t.format(
            pct=random.choice(["10", "15", "20", "25", "30", "40", "50"]),
            amount=random.choice(["2999", "4999", "7999", "9999", "14999"]),
            num=random.randint(100000, 999999),
            date=f"{random.randint(1,28)}/{random.randint(1,12)}"
        )
        spam_messages.append(msg)

    # ================================================================
    # SPAM: Education Promos
    # ================================================================
    edu_promos = [
        "ESOFT: Fast-Track your Career After O/Ls. Register now for IT diplomas! Call 011{num}",
        "NSBM: Applications open for {year} intake! Scholarships available. Visit nsbm.ac.lk",
        "SLIIT: Study {course} at Sri Lanka's #1 IT university. Apply now! sliit.lk",
        "IIT: British degrees in Sri Lanka! Register for free seminar on {date}. Call {phone}",
        "Predict on T20 matches & Win power banks from ESOFT UNI. Visit {url} now.",
        "ANC Education: IELTS classes starting next week! Band 7+ guaranteed. Call 011{num}",
        "British Council: Register for next IELTS exam. Limited seats! britishcouncil.lk",
        "Informatics: Diploma in Cyber Security starting {date}. Early bird {pct}% OFF!",
        "ICBT: Full scholarships for A/L students! Apply before {date}. icbt.lk",
        "Java Institute: Free coding workshop this Saturday! Register: {url}",
    ]
    for _ in range(40):
        t = random.choice(edu_promos)
        msg = t.format(
            num=random.randint(1000000, 9999999),
            year=random.choice(["2025", "2026"]),
            course=random.choice(["Software Engineering", "Networking", "Data Science", "Business", "Cyber Security"]),
            date=f"{random.randint(1,28)}/{random.randint(1,12)}",
            phone=f"07{random.randint(10000000, 99999999)}",
            url=f"https://bit.ly/{''.join(random.choices('abcdefghijklmnop23456789', k=7))}",
            pct=random.choice(["10", "15", "20", "25"])
        )
        spam_messages.append(msg)

    # ================================================================
    # SPAM: Short Promos / Education Spam (hard cases)
    # ================================================================
    short_spam = [
        "Power Up with ESOFT, Fast-Track your Career After O/Ls.",
        "Predict on T20 matches & Win power banks! Visit now.",
        "Win a FREE Samsung phone! Just answer 3 questions!",
        "Claim your Rs.5000 gift card NOW! Limited offer.",
        "FREE data! Activate your bonus pack today. Dial *123#",
        "50% OFF on all courses! Register today. Don't miss out!",
        "Win BIG prizes! Join our lucky draw. Click here now.",
        "Special offer just for YOU! Upgrade your plan today.",
        "FLASH SALE! Everything 70% OFF. Shop now before midnight!",
        "Get certified in 3 months! Enroll now for early bird discount.",
        "Congratulations! You've been selected for our special program.",
        "Last chance! Offer expires TODAY. Act NOW!",
        "Free workshop this Saturday! Register now. Limited seats!",
        "Exclusive deal: Rs.999 for unlimited internet! Activate now.",
        "Join & earn! Refer friends and win exciting prizes.",
        "Hurry! Only 5 spots left for the free training program.",
        "Your lucky number won! Claim prize: reply YES",
        "Special discount for Dialog customers only! Save 40% today.",
        "Don't miss this opportunity! Career change starts HERE.",
        "Download our app and get Rs.500 cashback! Install now.",
        "Win a trip to Maldives! Enter competition now: bit.ly/win",
        "BOGO offer! Buy one get one FREE at all outlets!",
        "Apply now for 0% interest education loans! NSBM University.",
        "Transform your career! Join SLIIT diploma program today.",
        "Cricket fever! Predict scores and win merchandise!",
    ]
    for msg in short_spam:
        spam_messages.append(msg)
    # Add them with brand name variations
    brands_spam = ["ESOFT", "NSBM", "SLIIT", "ICBT", "Dialog", "Mobitel", "Hutch"]
    for _ in range(40):
        msg = random.choice(short_spam)
        brand = random.choice(brands_spam)
        spam_messages.append(f"{brand}: {msg}")

    # ================================================================
    # SPAM: Singlish Scam Messages
    # ================================================================
    singlish_spam = [
        "Oba salakuna jeewakaya! Rs.{amount} dakinnam. Click: {url}",
        "FREE data {gb}GB! Danma activate karanna. Dial *{num}#",
        "Congratulations! Oba select unai special offer ekata. {url}",
        "Obe namata loan ekak ready! Rs.{amount}. Apply: {url}",
        "Lucky draw winner! Rs.{amount} prize. Claim karanna: {url}",
        "Special chance! Work from home and earn Rs.{amount}/day. Join: {url}",
        "Obe phone ekata FREE {gb}GB data! Activate: *{num}#",
        "Win win win! Rs.{amount} cash prize oba sandahamai! {url}",
        "Job opportunity! Rs.{amount}/month salary. No experience. Apply: {url}",
        "Obe Dialog account ekata bonus Rs.{amount}! Claim now: {url}",
    ]
    for _ in range(50):
        t = random.choice(singlish_spam)
        msg = t.format(
            amount=random.choice(["5,000", "10,000", "25,000", "50,000", "100,000"]),
            gb=random.choice(["1", "2", "5", "10"]),
            num=random.randint(100, 999),
            url=f"https://bit.ly/{''.join(random.choices('abcdefghijklmnop23456789', k=7))}"
        )
        spam_messages.append(msg)

    # ================================================================
    # SPAM: Investment / Crypto Scams
    # ================================================================
    invest_spam = [
        "Make Rs.{amount} daily from home! No investment needed. Join our WhatsApp group: {url}",
        "Bitcoin is booming! Invest Rs.5000 and earn Rs.{amount} in 7 days. Start: {url}",
        "GUARANTEED {pct}% returns monthly! Safe investment. Limited spots. Join now: {url}",
        "Work from home and earn Rs.{amount}/day! Part-time data entry. Contact: {phone}",
        "Forex trading made easy! Rs.{amount} profit in first week. Free training: {url}",
        "Double your money in 30 days! Trusted by 10,000+ Sri Lankans. Visit: {url}",
        "Online business opportunity! No experience needed. Earn Rs.{amount}/month. Call {phone}",
    ]
    for _ in range(35):
        t = random.choice(invest_spam)
        msg = t.format(
            amount=random.choice(["5,000", "10,000", "25,000", "50,000", "100,000"]),
            pct=random.choice(["15", "20", "30", "50"]),
            url=f"https://bit.ly/{''.join(random.choices('abcdefghijklmnop23456789', k=7))}",
            phone=f"07{random.randint(10000000, 99999999)}"
        )
        spam_messages.append(msg)

    # ================================================================
    # SPAM: General phishing / contest
    # ================================================================
    phishing = [
        "Congratulations! You won a {brand} gift voucher worth Rs.{amount}! Claim: {url}",
        "Your {brand} account needs verification! Click immediately: {url}",
        "ALERT: Unusual activity on your account. Verify now: {url}",
        "You have {num} unread messages! Check now: {url}",
        "FREE {brand} smartphone! Answer 3 questions to claim: {url}",
        "Your parcel could not be delivered. Pay Rs.{amount} customs fee: {url}",
        "Sri Lanka Customs: Package held. Pay duty Rs.{amount} to release: {url}",
    ]
    for _ in range(35):
        t = random.choice(phishing)
        msg = t.format(
            brand=random.choice(["Dialog", "Mobitel", "Samsung", "Apple", "Amazon", "Daraz"]),
            amount=random.choice(["500", "1000", "2500", "5000", "10000"]),
            url=f"https://{''.join(random.choices('abcdefghijk', k=5))}.com/{''.join(random.choices('abcdefghijklmnop', k=6))}",
            num=random.randint(3, 15)
        )
        spam_messages.append(msg)

    # ================================================================
    # HAM: Bank Transaction Alerts
    # ================================================================
    bank_templates = [
        "{bank}: Your account XX{acc} has been credited with Rs.{amount} on {date}.",
        "{bank}: Your account XX{acc} has been debited Rs.{amount} on {date}. Bal: Rs.{bal}",
        "{bank}: Your credit card ending {card} was charged Rs.{amount} at {merchant}.",
        "{bank}: Payment of Rs.{amount} received. Reference: {ref}. Thank you.",
        "{bank}: Your salary of Rs.{amount} has been credited to account XX{acc}.",
        "{bank}: Standing order of Rs.{amount} processed successfully. Ref: {ref}",
        "{bank}: Your loan installment of Rs.{amount} has been debited. Next due: {date}",
        "{bank}: FD maturity alert. Your deposit of Rs.{amount} matures on {date}.",
        "{bank}: ATM withdrawal of Rs.{amount} at {branch}. Remaining balance: Rs.{bal}",
        "{bank}: Your cheque #{ref} for Rs.{amount} has been cleared.",
        "{bank}: International transfer of USD {usd} received. LKR equivalent: Rs.{amount}",
        "{bank}: Card payment approved. Rs.{amount} at {merchant}. Available credit: Rs.{bal}",
    ]
    banks = ["BOC", "Sampath Bank", "HNB", "Commercial Bank", "NTB", "Seylan Bank", "DFCC", "Pan Asia Bank", "NSB"]
    merchants = ["Dialog", "Keells", "Cargills", "Lanka IOC", "CPC", "NWS&DB", "CEB", "SLT", "Daraz", "Uber"]
    branches = ["Colombo Fort", "Nugegoda", "Kandy", "Galle", "Kurunegala", "Matara", "Jaffna", "Batticaloa"]

    for _ in range(100):
        t = random.choice(bank_templates)
        msg = t.format(
            bank=random.choice(banks),
            acc=random.randint(1000, 9999),
            amount=f"{random.randint(500, 500000):,}",
            date=f"{random.randint(1,28)}/{random.randint(1,12)}/2025",
            bal=f"{random.randint(1000, 2000000):,}",
            card=random.randint(1000, 9999),
            merchant=random.choice(merchants),
            ref=f"{random.choice(['TXN','REF','CHQ'])}{random.randint(100000, 999999)}",
            branch=random.choice(branches),
            usd=random.randint(50, 5000)
        )
        ham_messages.append(msg)

    # ================================================================
    # HAM: OTP / Verification Messages
    # ================================================================
    otp_templates = [
        "{bank}: Your OTP is {otp}. Valid for {mins} minutes. Do NOT share with anyone.",
        "{bank}: Use code {otp} to confirm your transaction of Rs.{amount}.",
        "{bank}: Verification code {otp} for online banking login.",
        "Your {service} verification code is {otp}. Don't share this code.",
        "{otp} is your {service} verification code. This code expires in {mins} minutes.",
        "{bank}: OTP {otp} for credit card payment of Rs.{amount}. Do not share.",
    ]
    services = ["PayHere", "Frimi", "FriMi", "Dialog Genie", "eZ Cash", "mCash", "Sampath Vishwa"]

    for _ in range(60):
        t = random.choice(otp_templates)
        msg = t.format(
            bank=random.choice(banks),
            otp=random.randint(100000, 999999),
            mins=random.choice(["3", "5", "10"]),
            amount=f"{random.randint(500, 100000):,}",
            service=random.choice(services)
        )
        ham_messages.append(msg)

    # ================================================================
    # HAM: Ride App Notifications
    # ================================================================
    ride_templates = [
        "Your Uber is arriving now. Driver: {name}. Vehicle: WP-{plate}",
        "PickMe: Your ride request accepted. {name} arriving in {mins} mins. {vehicle}",
        "Uber: Your trip to {place} costs Rs.{amount}. Rate your driver.",
        "PickMe: Trip completed. Fare: Rs.{amount}. Thank you for riding with us!",
        "Your Uber ride with {name} has been completed. Fare: Rs.{amount}",
        "PickMe: Driver {name} is {mins} mins away. Track on app.",
    ]
    names = ["Kasun", "Nimal", "Sunil", "Chaminda", "Ruwan", "Saman", "Pradeep", "Mahesh", "Amal", "Dinesh"]
    places = ["Colombo Fort", "Nugegoda", "Maharagama", "Kaduwela", "Rajagiriya", "Battaramulla", "Dehiwala", "Mount Lavinia"]

    for _ in range(40):
        t = random.choice(ride_templates)
        msg = t.format(
            name=random.choice(names),
            plate=f"{''.join(random.choices('ABCDEFGH', k=3))}-{random.randint(1000,9999)}",
            mins=random.randint(2, 15),
            vehicle=random.choice(["Toyota Aqua - White", "Suzuki Alto - Silver", "Wagon R - Blue", "Honda Fit - Black"]),
            place=random.choice(places),
            amount=f"{random.randint(200, 5000):,}"
        )
        ham_messages.append(msg)

    # ================================================================
    # HAM: E-commerce & Delivery
    # ================================================================
    ecom_templates = [
        "Daraz: Your order #{ref} has been shipped! Track: daraz.lk/track",
        "Daraz: Your order #{ref} is out for delivery. Expected today by {time}.",
        "Daraz: Order #{ref} delivered successfully. Rate your experience on the app.",
        "Kapruka: Your gift has been delivered to {place}. Order #{ref}.",
        "Your Amazon order has been dispatched. Tracking: {ref}. Estimated delivery: {date}",
        "AliExpress: Your package has arrived at Colombo customs. Track: {ref}",
        "Sri Lanka Post: Your parcel {ref} is ready for collection at {place} post office.",
    ]
    for _ in range(40):
        t = random.choice(ecom_templates)
        msg = t.format(
            ref=f"LK{random.randint(10000, 99999)}",
            time=f"{random.randint(9, 18)}:{random.choice(['00', '30'])}",
            place=random.choice(places),
            date=f"{random.randint(1, 28)}/{random.randint(1, 12)}"
        )
        ham_messages.append(msg)

    # ================================================================
    # HAM: Receipts & Bills
    # ================================================================
    receipt_templates = [
        "Keells Super: Your bill Rs.{amount}. Points earned: {pts}. Thank you for shopping!",
        "Cargills Food City: Payment of Rs.{amount} received. Invoice #{ref}.",
        "CEB: Your electricity bill for {month} is Rs.{amount}. Due date: {date}. Pay via: {url}",
        "NWS&DB: Water bill Rs.{amount}. Account: {acc}. Pay before {date} to avoid surcharge.",
        "SLT: Your monthly bill is Rs.{amount}. Pay online at slt.lk or visit nearest outlet.",
        "Dialog: Your postpaid bill for {month} is Rs.{amount}. Pay via MyDialog app.",
        "Pizza Hut: Order confirmed! Your bill: Rs.{amount}. Delivery in 30-45 mins. Ref: PH{ref}",
        "Arpico: Purchase receipt Rs.{amount}. Loyalty points: {pts}. Thank you!",
    ]
    months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    for _ in range(50):
        t = random.choice(receipt_templates)
        msg = t.format(
            amount=f"{random.randint(200, 25000):,}",
            pts=random.randint(5, 250),
            ref=random.randint(10000, 99999),
            month=random.choice(months),
            date=f"{random.randint(1, 28)}/{random.randint(1, 12)}",
            url="ebill.lk",
            acc=random.randint(10000000, 99999999)
        )
        ham_messages.append(msg)

    # ================================================================
    # HAM: Personal Messages (Singlish / English) — EXPANDED
    # ================================================================
    personal = [
        # University life
        "oya exam eka kohomada? mage hondai",
        "machang {time} ta ena. late unoth call karanna",
        "Lab cancelled tomorrow. Check LMS for details.",
        "Hey can you send me the notes from yesterday's lecture?",
        "bro mage phone eka charge naa. charger ekak tiyenawada?",
        "assignment submit karada? deadline today 11.59pm",
        "library eke group study room ekak book karannam. enawada?",
        "thanks for the help machang. exam eka gahanna puluwan",
        "results aawada? mage GPA eka hari naa",
        "presentation eka heta ne. slides danna one",
        "new semester start next Monday. timetable awa",
        "hostel food eka boring. outside kamu yamu",
        "project deadline next week. haven't started yet :(",
        "internship ekak hoyaganna one summer walata",
        "convocation eka next month! family enawa kiyla kiwwa",
        "ape group eke meeting tomorrow 10am. zoom link ewanawa",
        "Ada class naa. Lecturer ekena sick leave",
        "lab report submit karanna one before friday",
        "thesis eka finish karanna baruwa. help karannako",
        "mage laptop eka restart wenawa. virus ekakda?",
        "lecture notes ewa share karanna group ekata",
        "exam hall eka change unada? mokakda room eka",
        "viva eka next week. prepare wenna one",
        "semester break eke mokakda plan? gama yanawada",
        "credits 120 tiyennada graduate wenna?",
        "FYP supervisor eka approve karada topic eka?",
        "GPA calculator eken check karo. 3.2 enawa",

        # Daily life & social
        "Happy birthday! Hope you have an amazing day!",
        "Mom wants to know if you're coming for dinner Sunday",
        "ane traffic eka ithin. late wenawa definitely",
        "food order karanawada? uu ate hondai kiyla kiwwa",
        "gym ekta yannada heta morning? 6am ta ennam",
        "movie ekak balamu weekend eke. Horror ekak tiyenawa",
        "wedding eka Saturday ne. gift ekak gannnam yamu",
        "bus eka miss una. next ekta ennam. 30min late",
        "raining heavily. umbrella ekak ganna puluwan da?",
        "match eka live balanna dialog tv eken",
        "parking naa bro. tuk ekaken ennam",
        "canteen eke kottu hondai today. try karanna",
        "Photos ewa send karo WhatsApp eken",
        "Happy New Year! Suba Aluth Auruddak Wewa!",
        "cricket match eka balannada today? SL vs India",
        "oya weekend eka free da? beach ekak yamu",
        "rent eka this month pay karada? owner call karala",
        "interview eka kohomada? anxious about it",
        "doctor appointment eka 3pm ta. hospital yannam",
        "birthday party eka Saturday 7pm ta. come!",
        "laundry ganna one. clothes run out",
        "mama Kandy yanna hadanawa weekend eke. enawada?",
        "wifi password eka mokakda hostel eke?",

        # More Singlish daily conversation
        "kohomada bro? loku kalayak une contact unela naa",
        "malli okkoma hondai. amma taththath salpen innawa",
        "ane sorry machang. forgot to call you back",
        "ada weather eka hondai ne. picnic ekak yamu",
        "lunch eka mokakda ada? rice and curry da?",
        "class eka boring ithin. phone eka balanawa",
        "weekend eke game ekak danawada? football yamu",
        "bro oya inna area eke parking tiyenawada?",
        "mama bus eke innawa. 20 min witha ennam",
        "ane mage wallet eka harakuna. mokak karannada",
        "heta dawasa holiday ne. sleep karanna hadanawa",
        "meka try karala bala. hondai kiyla kiwwa kawruwath",
        "oya okka dennek enawada trip ekata? van ekak gamu",
        "mage internet eka slow ithin. wifi eka hondai da oya gawa?",
        "grocery ganna one weekend eke. Keells yamu",
        "amma kiyla kiwwa pol sambol hadanna. recipe eka tiyenawada?",
        "ada poya day ne. temple ekata yannada?",
        "new phone ekak ganna one. Samsung da iPhone da?",
        "bro mage bike eka puncture. ganna aawada?",
        "power cut ada 2pm to 5pm. generator eka on karanna",
        "dentist eka heta appointment. anxious about it",
        "heta dawasa mage turn. breakfast hadannam",
        "salary awa da machang? mage naa awey",
        "car eka service ekata danna one. mileage wedi",
        "concert eka balanna yannada? tickets tiyenawa",
        "ane bore ithin. mokak karannada today",
        "medicine ganna one pharmacy eken. tablet ewa over una",
        "gas eka over una. cylinder ekak ganna one",
        "train eka late. platform eke waiting innawa",
        "mage room mate eka snore karanawa. sleep wenna baa",
        "adath load shedding. candle ekak tiyenawada?",
        "podi ekage school eka heta start wenawa",
        "tuition eka miss una ada. notes ewa tiyenawada?",
        "sudu naan hadamu dinner walata. ingredients gannada?",
        "oya gawa pet shop ekak tiyenawada? fish food ganna one",
        "mama okkoma clean karanawa room eka. landlord enawa inspect karanna",
        "curfew da heta? news eke mokak kiyanawada?",
        "meka share karanna bako social media eke. personal info",
        "bro oyage bike eka loanata dunnada? heta one",
        "cooking class ekak tiyenawa saturday. interested da?",

        # Pure Sinhala messages (Unicode)
        "හෙට උදේ 8ට එන්න. පරණ තැන",
        "අම්මා කිව්වා ඉක්මනට එන්න කියලා",
        "සතුටු උපන්දිනයක්! සුභ පැතුම්",
        "මට කතා කරන්න. ඉක්මනට",
        "පාඩම් කරනවද? exam එක ළඟයි",
        "කෑම හදනවද? මම එනවා dinner ට",
        "bus එක miss උනා. next එකෙන් එනවා",
        "මගේ phone එක silent දාලා තිබුනා. sorry",
        "හොඳ weather එකක්. park එකට යමුද?",
        "ගෙදර එනකොට bread ටිකක් අරගෙන එන්න",
    ]
    # Add each
    for msg in personal:
        ham_messages.append(msg)
    # Create variations
    for msg in personal[:30]:
        ham_messages.append(msg.replace("today", "tomorrow").replace("heta", "ada").replace("eka", "ekak"))

    # ================================================================
    # HAM: Government / Official
    # ================================================================
    govt = [
        "Since the Grama Niladhari will not be visiting houses this time, please contact him only if there are amendments to the 2026 draft electoral register.",
        "Dept of Immigration: Your passport application {ref} is being processed. Expected completion: {days} working days.",
        "RMV: Your vehicle revenue license renewal is due on {date}. Visit rmv.gov.lk",
        "NIC Office: Your new NIC is ready for collection. Bring receipt to {place} office.",
        "Sri Lanka Police: Community awareness program at {place} on {date}. All residents welcome.",
        "Election Commission: Voter registration deadline is {date}. Check your details at elections.gov.lk",
        "MOH Office: COVID vaccination available at {place} on {date}. Bring NIC.",
        "Divisional Secretariat: Your land deed application has been forwarded. Ref: {ref}",
        "Census Dept: National census survey in your area on {date}. Please be available.",
        "University Grants Commission: A/L results released. Check ugc.ac.lk",
    ]
    for msg in govt:
        ham_messages.append(msg.format(
            ref=f"APP{random.randint(10000, 99999)}",
            days=random.randint(10, 45),
            date=f"{random.randint(1, 28)}/{random.randint(1, 12)}/2025",
            place=random.choice(["Colombo", "Nugegoda", "Kandy", "Galle", "Kurunegala"])
        ))

    # ================================================================
    # HAM: Appointment / Reminder
    # ================================================================
    appt_templates = [
        "Reminder: Your appointment with Dr. {name} is on {date} at {time}. {hospital}",
        "Nawaloka Hospital: Your lab results are ready. Visit or call 011{num}.",
        "Asiri Hospital: Appointment confirmed for {date} at {time}. Bring previous reports.",
        "Lanka Hospitals: Your appointment #{ref} has been rescheduled to {date}.",
        "Dental appointment tomorrow at {time}. Dr. {name}. Please arrive 15 mins early.",
    ]
    hospitals = ["Nawaloka Hospital", "Asiri Hospital", "Lanka Hospitals", "Durdans Hospital"]
    for _ in range(20):
        t = random.choice(appt_templates)
        msg = t.format(
            name=random.choice(names),
            date=f"{random.randint(1, 28)}/{random.randint(1, 12)}",
            time=f"{random.randint(8, 17)}:{random.choice(['00', '15', '30', '45'])}",
            hospital=random.choice(hospitals),
            num=random.randint(1000000, 9999999),
            ref=f"APT{random.randint(1000, 9999)}"
        )
        ham_messages.append(msg)

    # Build DataFrame
    df_spam = pd.DataFrame({'label': 'spam', 'message': spam_messages})
    df_ham = pd.DataFrame({'label': 'ham', 'message': ham_messages})
    df = pd.concat([df_spam, df_ham], ignore_index=True)
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)

    return df


def save_dataset(filepath='sri_lankan_sms.csv'):
    """Generate and save dataset"""
    df = generate_dataset()

    # Stats
    spam_count = len(df[df['label'] == 'spam'])
    ham_count = len(df[df['label'] == 'ham'])

    print(f"Sri Lankan SMS Dataset Generated:")
    print(f"  Total: {len(df)}")
    print(f"  Spam:  {spam_count}")
    print(f"  Ham:   {ham_count}")
    print(f"  Ratio: {spam_count/len(df)*100:.0f}% spam / {ham_count/len(df)*100:.0f}% ham")

    df.to_csv(filepath, index=False)
    print(f"  Saved to: {filepath}")

    return df


if __name__ == '__main__':
    save_dataset()
