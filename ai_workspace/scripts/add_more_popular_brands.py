# -*- coding: utf-8 -*-
"""
Additional Indonesian Popular F&B Brands to make the database 100% comprehensive:
- KOI Thé (Golden bubble milk tea, black tea macchiato, brown sugar)
- Xing Fu Tang (Brown sugar boba milk stir-fried pearls)
- Kopi Soe (Es Roegal Rum Regal, Kopi Soe Gula Aren)
- Kopi Lain Hati (Es Kopi Main Hati, Es Kopi Valakor)
- Gokana Ramen & Teppan (Gokana 1, Beef Hot Ramen, Teppan)
- Ta Wan (Bubur Tiga Rasa, Jamur Enoki Lada Garam)
- D'Cost (Ikan Gurame Asam Manis, Cumi Goreng Tepung)
- Momoyo (Jumbo Fruit Tea, Boba Sundae, Mango Pomelo Sago)
- Menantea (MatemaTea, Integalsea)
- Xi Bo Ba & Kokumi (Brown sugar boba fresh milk, Okinawa brown sugar)
"""

import json
import os

MORE_BRANDS = {
  # KOI Thé
  "koi the golden bubble milk tea": {
    "name": "KOI Thé Golden Bubble Milk Tea",
    "emoji": "🧋",
    "calories": 340,
    "protein": 4.2,
    "carbs": 64.0,
    "fat": 7.8,
    "fiber": 1.0,
    "sugar": 38.0,
    "caffeineMg": 70,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "KOI Thé",
    "aliases": ["koi the golden bubble milk tea", "golden bubble milk tea koi", "koi milk tea", "koi the", "koi boba"],
    "ingredients": ["Teh hitam seduh premium KOI", "Krimer susu lembut", "Golden bubble tapioka emas kenyal khas KOI", "Sirup gula tebu", "Es batu"],
    "visual_clues": ["cup cup khas KOI Thé dengan bulatan mutiara golden bubble berwarna kuning keemasan transparan di dasar cup"]
  },
  "koi the black tea macchiato": {
    "name": "KOI Thé Black Tea Macchiato",
    "emoji": "🍵",
    "calories": 210,
    "protein": 3.0,
    "carbs": 32.0,
    "fat": 8.0,
    "fiber": 0.0,
    "sugar": 26.0,
    "caffeineMg": 80,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "KOI Thé",
    "aliases": ["koi the black tea macchiato", "black tea macchiato koi", "koi macchiato", "macchiato koi"],
    "ingredients": ["Teh hitam Ceylon seduh murni", "Krim macchiato susu manis gurih tebal di permukaan", "Es batu"],
    "visual_clues": ["lapisan cairan teh hitam jernih di bawah dengan selimut busa krim macchiato putih tebal di atasnya dalam cup KOI"]
  },

  # Xing Fu Tang
  "xing fu tang brown sugar boba milk": {
    "name": "Xing Fu Tang Brown Sugar Boba Milk",
    "emoji": "🧋",
    "calories": 420,
    "protein": 6.0,
    "carbs": 76.0,
    "fat": 10.5,
    "fiber": 1.0,
    "sugar": 48.0,
    "caffeineMg": 0,
    "serving": "1 cup (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Xing Fu Tang",
    "aliases": ["xing fu tang brown sugar boba milk", "brown sugar boba milk xing fu tang", "xing fu tang", "boba xing fu tang"],
    "ingredients": ["Boba tapioka segar yang dimasak wajan tembaga dengan gula merah murni", "Susu sapi segar murni 100%", "Krim susu lembut dengan taburan gula aren dibakar torch"],
    "visual_clues": ["garis-garis lurik cokelat karamel tebal mengalir di dinding cup bening dengan boba hitam pekat berkilau di dasar dan lapisan karamel bakar di atas"]
  },

  # Kopi Soe
  "kopi soe es roegal": {
    "name": "Kopi Soe Es Roegal (Rum Regal)",
    "emoji": "🥛",
    "calories": 280,
    "protein": 5.2,
    "carbs": 44.0,
    "fat": 9.5,
    "fiber": 1.0,
    "sugar": 28.0,
    "caffeineMg": 0,
    "serving": "1 cup (350ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Kopi Soe",
    "aliases": ["kopi soe es roegal", "es roegal kopi soe", "roegal kopi soe", "kopi soe roegal", "kopi soe"],
    "ingredients": ["Susu segar murni", "Perisa rum halal aromatik wangi", "Biskuit Marie Regal utuh yang dihancurkan renyah di atasnya", "Es batu"],
    "visual_clues": ["cup transparan berlogo huruf 'Kopi Soe' jadul dengan susu putih dan tumpukan remahan biskuit Marie Regal coklat keemasan di atas"]
  },
  "kopi soe kopi soe gula aren": {
    "name": "Kopi Soe Gula Aren",
    "emoji": "☕",
    "calories": 210,
    "protein": 4.5,
    "carbs": 33.0,
    "fat": 7.0,
    "fiber": 0.0,
    "sugar": 24.0,
    "caffeineMg": 110,
    "serving": "1 cup (350ml)",
    "category": "Minuman Kopi",
    "brand": "Kopi Soe",
    "aliases": ["kopi soe kopi soe gula aren", "kopi soe gula aren", "es kopi soe", "kopi soe"],
    "ingredients": ["Double shot espresso kopi lokal", "Susu segar", "Gula aren cair asli", "Es batu"],
    "visual_clues": ["es kopi susu cokelat krem klasik dalam cup Kopi Soe"]
  },

  # Kopi Lain Hati
  "kopi lain hati es kopi main hati": {
    "name": "Kopi Lain Hati Es Kopi Main Hati",
    "emoji": "☕",
    "calories": 215,
    "protein": 4.2,
    "carbs": 34.0,
    "fat": 7.2,
    "fiber": 0.0,
    "sugar": 25.0,
    "caffeineMg": 115,
    "serving": "1 cup (350ml)",
    "category": "Minuman Kopi",
    "brand": "Kopi Lain Hati",
    "aliases": ["kopi lain hati es kopi main hati", "es kopi main hati lain hati", "kopi main hati", "kopi lain hati"],
    "ingredients": ["Espresso kopi pilihan", "Susu segar", "Gula aren manis legit", "Es batu kristal"],
    "visual_clues": ["cup bertuliskan 'Kopi Lain Hati' warna merah hati dengan es kopi susu gula aren"]
  },

  # Gokana Ramen & Teppan
  "gokana beef hot ramen": {
    "name": "Gokana Beef Hot Ramen",
    "emoji": "🍜",
    "calories": 590,
    "protein": 28.0,
    "carbs": 76.0,
    "fat": 20.0,
    "fiber": 3.5,
    "sugar": 4.5,
    "caffeineMg": 0,
    "serving": "1 mangkok porsi (420g)",
    "category": "Makanan Utama",
    "brand": "Gokana",
    "aliases": ["gokana beef hot ramen", "beef hot ramen gokana", "ramen gokana", "gokana ramen", "gokana"],
    "ingredients": ["Mie ramen keriting kuning kenyal", "Irisan daging sapi sukiyaki gurih", "Kuah sup ramen pedas merah gurih khas Gokana level pedas 1-4", "Telur rebus setengah matang (nitamago), jamur kuping, daun bawang, nori"],
    "visual_clues": ["mangkok merah-hitam khas Gokana berisi kuah ramen merah pedas berminyak cabai dengan mie, daging sapi, dan separuh telur rebus"]
  },
  "gokana 1 bento": {
    "name": "Gokana 1 (Chicken Teriyaki + Fry Mix)",
    "emoji": "🍱",
    "calories": 680,
    "protein": 32.0,
    "carbs": 78.0,
    "fat": 27.0,
    "fiber": 3.0,
    "sugar": 10.0,
    "caffeineMg": 0,
    "serving": "1 paket bento lengkap",
    "category": "Makanan Siap Saji",
    "brand": "Gokana",
    "aliases": ["gokana 1 bento", "gokana 1", "paket gokana 1", "bento gokana 1"],
    "ingredients": ["Nasi putih pulen", "Chicken Teriyaki fillet ayam saus manis gurih", "Gorengan fry mix renyah (marumi & katsu)", "Salad mayones segar"],
    "visual_clues": ["kotak bento hitam sekat dengan nasi putih, teriyaki ayam, gorengan keemasan, dan salad"]
  },

  # Ta Wan
  "ta wan bubur tiga rasa": {
    "name": "Ta Wan Bubur Tiga Rasa (Ayam, Sapi, Ikan)",
    "emoji": "🥣",
    "calories": 380,
    "protein": 24.0,
    "carbs": 52.0,
    "fat": 8.5,
    "fiber": 1.5,
    "sugar": 1.0,
    "caffeineMg": 0,
    "serving": "1 mangkok saji (400g)",
    "category": "Makanan Utama",
    "brand": "Ta Wan",
    "aliases": ["ta wan bubur tiga rasa", "bubur tiga rasa ta wan", "bubur ta wan", "ta wan"],
    "ingredients": ["Bubur beras lembut gurih kental berkaldu khas oriental", "Irisan daging sapi empuk", "Suwiran daging ayam", "Potongan fillet ikan lembut tanpa duri", "Cakwe renyah, daun seledri, daun bawang, kecap asin wijen"],
    "visual_clues": ["mangkok porselen putih besar berisi bubur kental lembut dengan cakwe dan taburan daging di permukaannya"]
  },
  "ta wan jamur enoki lada garam": {
    "name": "Ta Wan Jamur Enoki Goreng Lada Garam",
    "emoji": "🍄",
    "calories": 260,
    "protein": 5.5,
    "carbs": 28.0,
    "fat": 14.5,
    "fiber": 3.5,
    "sugar": 1.0,
    "caffeineMg": 0,
    "serving": "1 piring porsi (150g)",
    "category": "Lauk Pauk",
    "brand": "Ta Wan",
    "aliases": ["ta wan jamur enoki lada garam", "jamur enoki lada garam ta wan", "enoki goreng ta wan", "jamur enoki ta wan"],
    "ingredients": ["Jamur enoki segar dibalut tepung bumbu garing renyah", "Tumisan irisan cabai merah, cabai rawit, bawang putih, dan daun bawang wangi lada garam"],
    "visual_clues": ["tumpukan jamur enoki goreng krispi mengembang keemasan bertabur cincangan cabai merah dan bawang putih cincang"]
  },

  # D'Cost Seafood
  "dcost gurame asam manis": {
    "name": "D'Cost Ikan Gurame Asam Manis",
    "emoji": "🐟",
    "calories": 520,
    "protein": 38.0,
    "carbs": 44.0,
    "fat": 22.0,
    "fiber": 2.0,
    "sugar": 16.0,
    "caffeineMg": 0,
    "serving": "1 ekor gurame porsi (450g)",
    "category": "Makanan Utama",
    "brand": "D'Cost",
    "aliases": ["dcost gurame asam manis", "gurame asam manis dcost", "ikan gurame dcost", "dcost"],
    "ingredients": ["1 Ekor ikan gurame segar dibelah fillet dan digoreng tepung garing mekar", "Saus asam manis merah segar kaya rasa", "Potongan nanas manis, wortel, dan kacang polong"],
    "visual_clues": ["ikan gurame goreng tepung mekar keemasan disiram saus merah asam manis mengkilap dengan potongan nanas di atas piring lonjong D'Cost"]
  },
  "dcost cumi goreng tepung": {
    "name": "D'Cost Cumi Goreng Tepung Crispy",
    "emoji": "🦑",
    "calories": 360,
    "protein": 22.0,
    "carbs": 32.0,
    "fat": 16.5,
    "fiber": 1.0,
    "sugar": 1.5,
    "caffeineMg": 0,
    "serving": "1 piring saji (180g)",
    "category": "Makanan Utama",
    "brand": "D'Cost",
    "aliases": ["dcost cumi goreng tepung", "cumi goreng tepung dcost", "cumi tepung dcost"],
    "ingredients": ["Potongan cincin cumi-cumi segar kenyal", "Tepung bumbu krispi renyah keemasan", "Saus sambal cocolan"],
    "visual_clues": ["cincin-cincin cumi goreng tepung kuning keemasan renyah bertumpuk di atas piring"]
  },

  # Momoyo
  "momoyo jumbo fruit tea": {
    "name": "Momoyo Jumbo Fruit Tea (1 Liter)",
    "emoji": "🍹",
    "calories": 240,
    "protein": 1.0,
    "carbs": 58.0,
    "fat": 0.2,
    "fiber": 2.5,
    "sugar": 48.0,
    "caffeineMg": 40,
    "serving": "1 bucket jumbo (1000ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Momoyo",
    "aliases": ["momoyo jumbo fruit tea", "jumbo fruit tea momoyo", "fruit tea momoyo", "momoyo 1 liter", "momoyo"],
    "ingredients": ["Jasmine Green Tea seduh", "Irisan buah jeruk sunkist, semangka, markisa, lemon, dan apel asli melimpah", "Sirup buah tebu & es batu"],
    "visual_clues": ["ember cup raksasa 1 liter transparan berlogo beruang pink Momoyo berisi irisan aneka buah warna-warni mengapung di teh kuning cerah"]
  },
  "momoyo boba sundae": {
    "name": "Momoyo Boba Sundae",
    "emoji": "🍦",
    "calories": 275,
    "protein": 4.2,
    "carbs": 50.0,
    "fat": 6.5,
    "fiber": 0.8,
    "sugar": 36.0,
    "caffeineMg": 0,
    "serving": "1 cup sundae (240g)",
    "category": "Es Krim",
    "brand": "Momoyo",
    "aliases": ["momoyo boba sundae", "boba sundae momoyo", "sundae boba momoyo", "es krim momoyo"],
    "ingredients": ["Es krim soft serve vanila susu Momoyo", "Topping brown sugar boba kenyal", "Sirup gula aren kental"],
    "visual_clues": ["cup sundae berlogo beruang Momoyo dengan es krim vanila dan lelehan boba cokelat"]
  },

  # Menantea
  "menantea matematea": {
    "name": "Menantea MatemaTea (Fruit Tea)",
    "emoji": "🍹",
    "calories": 160,
    "protein": 0.5,
    "carbs": 39.0,
    "fat": 0.2,
    "fiber": 1.2,
    "sugar": 34.0,
    "caffeineMg": 45,
    "serving": "1 cup (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Menantea",
    "aliases": ["menantea matematea", "matematea menantea", "matematea", "menantea fruit tea", "menantea"],
    "ingredients": ["Seduhan teh buah segar beraroma rempah jeruk dan apel khas Jerome Polin", "Potongan buah segar", "Gula tebu cair & es batu"],
    "visual_clues": ["cup oranye cerah bertuliskan rumus matematika dan logo Menantea berisi teh buah segar kuning jingga"]
  },

  # Xi Bo Ba
  "xi bo ba the brown sugar boba fresh milk": {
    "name": "Xi Bo Ba The Brown Sugar Boba Fresh Milk",
    "emoji": "🧋",
    "calories": 380,
    "protein": 5.5,
    "carbs": 68.0,
    "fat": 9.5,
    "fiber": 1.0,
    "sugar": 44.0,
    "caffeineMg": 0,
    "serving": "1 cup (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Xi Bo Ba",
    "aliases": ["xi bo ba the brown sugar boba fresh milk", "brown sugar boba fresh milk xi bo ba", "boba xi bo ba", "xi bo ba", "xiboba"],
    "ingredients": ["Brown sugar boba kenyal hangat dimasak gula aren", "Susu sapi segar", "Cream cheese foam gurih lembut di atasnya"],
    "visual_clues": ["cup plastik gendut bersegel khas Xi Bo Ba dengan lumuran karamel cokelat di dinding dan lapisan cheese foam putih di atas"]
  },

  # Kokumi
  "kokumi okinawa brown sugar big boba": {
    "name": "Kokumi Okinawa Brown Sugar Big Boba",
    "emoji": "🧋",
    "calories": 410,
    "protein": 5.8,
    "carbs": 74.0,
    "fat": 10.0,
    "fiber": 1.0,
    "sugar": 46.0,
    "caffeineMg": 0,
    "serving": "1 cup (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Kokumi",
    "aliases": ["kokumi okinawa brown sugar big boba", "okinawa brown sugar kokumi", "boba kokumi", "kokumi okinawa", "kokumi"],
    "ingredients": ["Boba ukuran besar (big boba) empuk manis", "Susu segar murni", "Sirup gula aren Okinawa khas Jepang yang kaya karamel legit", "Krim lembut"],
    "visual_clues": ["cup bulat bertuliskan 'KOKUMI' dengan logo unicorn lucu berisi susu putih berlumur sirup aren Okinawa cokelat pekat"]
  },

  # Dum Dum Thai Tea
  "dum dum thai tea original": {
    "name": "Dum Dum Thai Tea Original",
    "emoji": "🧋",
    "calories": 280,
    "protein": 4.5,
    "carbs": 50.0,
    "fat": 7.0,
    "fiber": 0.5,
    "sugar": 36.0,
    "caffeineMg": 65,
    "serving": "1 cup jumbo (600ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Dum Dum",
    "aliases": ["dum dum thai tea original", "dum dum thai tea", "thai tea dum dum", "dum dum", "dumdum"],
    "ingredients": ["Seduhan daun teh merah Thailand pekat asli yang ditarik (pulled tea)", "Susu kental manis & susu evaporasi", "Es batu kristal melimpah"],
    "visual_clues": ["cup jumbo ramping bening khas Dum Dum dengan sedotan hitam panjang dan cairan teh susu oranye cerah khas Thailand"]
  }
}

def enrich_more():
    file_path = os.path.join("ai_workspace", "dataset", "food_master.json")
    with open(file_path, "r", encoding="utf-8") as f:
        existing = json.load(f)

    before = len(existing)
    added = 0
    updated = 0

    for k, v in MORE_BRANDS.items():
        ck = k.lower().strip()
        if ck in existing:
            existing[ck].update(v)
            updated += 1
        else:
            existing[ck] = v
            added += 1

    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(existing, f, ensure_ascii=False, indent=2)

    print(f"[*] Added more popular brands!")
    print(f"    Before: {before}")
    print(f"    Added: {added}")
    print(f"    Updated: {updated}")
    print(f"    Total now: {len(existing)}")

if __name__ == "__main__":
    enrich_more()
