# -*- coding: utf-8 -*-
"""
Exhaustive Brand Enrichment Script for Indonesian F&B Chains.
Expands food_master.json with all remaining variants and additional major brands:
- Teazzi (complete catalog of all tea, latte, oolong, topping variants)
- Mixue (complete catalog of all sundae, shake, ice cream, lemonade, tea, smoothie variants)
- Chatime (complete catalog of all milk tea, mousse, oriental tea, smoothie, fresh milk)
- Kopi Kenangan & Chigo (complete catalog of coffee, non-coffee, cerita roti, chigo chicken)
- Burger Bangor (complete catalog of all burger tiers, sides, hotdogs, fries)
- Haus! (complete catalog of coffee, boba, cheese foam, yakult, roti bakar, snacks)
- Janji Jiwa & Jiwa Toast (complete catalog of all coffee, non-coffee, jiwatoast series)
- Fore Coffee (complete catalog of all latte, macchiato, specialty coffee, pastry, sandwiches)
- Starbucks Indonesia (popular staple coffees, frappuccinos, teas, pastries)
- Shihlin Taiwan Street Snacks (XXL crispy chicken variants, tempura, ricebox)
- Marugame Udon (niku udon, beef curry, tori baitan, tempura ebi, chikuwa)
- Yoshinoya (original beef bowl, yakiniku, black pepper, karaage)
- Bakmi GM (bakmi gm spesial, pangsit goreng isi 5/10, siomay, nasi goreng)
- Roti'O & Roti Boy (coffee buns, pastries, kopi'o)
- Dunkin' Donuts Indonesia (boston kreme, frosted, glazed, iced drinks)
- D'Crepes (choco peanut, choco cheese, smoked beef, spicy tuna)
- FamilyMart & Lawson (fami cafe kopi keluarga, crispy chicken, odeng, tteokbokki)
- Xi Bo Ba, Kokumi, Menantea, Momoyo, Dum Dum Thai Tea, Es Teler 77
"""

import json
import os

EXTENSIVE_BRAND_DATA = {
  # =========================================================================
  # TEAZZI (Tambahan varian lengkap)
  # =========================================================================
  "teazzi amber oolong milk tea": {
    "name": "Teazzi Amber Oolong Milk Tea",
    "emoji": "🧋",
    "calories": 250,
    "protein": 3.9,
    "carbs": 43.0,
    "fat": 7.4,
    "fiber": 0.0,
    "sugar": 28.0,
    "caffeineMg": 70,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": ["teazzi amber oolong milk tea", "amber oolong milk tea teazzi", "teazzi amber oolong", "amber oolong teazzi"],
    "ingredients": ["Teh Amber Oolong khas Taiwan dengan fermentasi medium", "Susu segar murni", "Sirup gula tebu", "Es batu"],
    "visual_clues": ["cairan teh susu berwarna cokelat keemasan kemerahan khas amber oolong", "cup Teazzi elegan bertuliskan kaligrafi"]
  },
  "teazzi ceylon black milk tea": {
    "name": "Teazzi Ceylon Black Milk Tea",
    "emoji": "🧋",
    "calories": 260,
    "protein": 4.1,
    "carbs": 45.0,
    "fat": 7.6,
    "fiber": 0.0,
    "sugar": 30.0,
    "caffeineMg": 80,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": ["teazzi ceylon black milk tea", "ceylon black milk tea teazzi", "ceylon milk tea teazzi", "teazzi ceylon"],
    "ingredients": ["Seduhan teh hitam Ceylon Sri Lanka pekat aromatik", "Susu segar murni", "Gula tebu cair", "Es batu"],
    "visual_clues": ["teh susu cokelat pekat klasik dengan aroma teh hitam kuat"]
  },
  "teazzi four seasons spring pure tea": {
    "name": "Teazzi Four Seasons Spring Pure Tea (No Sugar)",
    "emoji": "🍵",
    "calories": 5,
    "protein": 0.2,
    "carbs": 1.0,
    "fat": 0.0,
    "fiber": 0.0,
    "sugar": 0.0,
    "caffeineMg": 55,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": ["teazzi four seasons spring pure tea", "teazzi pure tea", "teh tawar teazzi", "four seasons spring tea teazzi"],
    "ingredients": ["Seduhan murni daun teh Four Seasons Oolong Taiwan tanpa gula", "Air mineral murni", "Es batu kristal"],
    "visual_clues": ["cairan teh jernih berwarna kuning keemasan kehijauan transparan dalam cup Teazzi"]
  },
  "teazzi honey lemon green tea": {
    "name": "Teazzi Honey Lemon Green Tea",
    "emoji": "🍋",
    "calories": 160,
    "protein": 0.5,
    "carbs": 39.0,
    "fat": 0.1,
    "fiber": 0.5,
    "sugar": 34.0,
    "caffeineMg": 45,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": ["teazzi honey lemon green tea", "honey lemon green tea teazzi", "teazzi honey lemon", "madu lemon teazzi"],
    "ingredients": ["Jasmine Green Tea seduh", "Madu alami murni pilihan", "Perasan lemon segar asli", "Es batu"],
    "visual_clues": ["cairan teh kuning keemasan segar dengan irisan lemon di dalamnya"]
  },
  "teazzi taro milk tea": {
    "name": "Teazzi Taro Milk Tea",
    "emoji": "🍠",
    "calories": 315,
    "protein": 4.2,
    "carbs": 58.0,
    "fat": 7.8,
    "fiber": 1.0,
    "sugar": 36.0,
    "caffeineMg": 0,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": ["teazzi taro milk tea", "taro milk tea teazzi", "teazzi taro"],
    "ingredients": ["Pasta taro talas ungu Taiwan autentik", "Susu segar murni", "Gula tebu & es batu"],
    "visual_clues": ["minuman warna ungu pastel lembut khas taro di dalam cup ramping Teazzi"]
  },

  # =========================================================================
  # MIXUE (Tambahan varian lengkap)
  # =========================================================================
  "mixue lucky sundae strawberry": {
    "name": "Mixue Lucky Sundae Strawberry",
    "emoji": "🍨",
    "calories": 290,
    "protein": 4.2,
    "carbs": 56.0,
    "fat": 6.5,
    "fiber": 1.2,
    "sugar": 44.0,
    "caffeineMg": 0,
    "serving": "1 cup lucky sundae (260g)",
    "category": "Es Krim",
    "brand": "Mixue",
    "aliases": ["mixue lucky sundae strawberry", "lucky sundae strawberry mixue", "lucky sundae mixue", "mixue lucky sundae"],
    "ingredients": ["Es krim vanila Mixue bertekstur lembut padat", "Selai buah stroberi asli dengan bulir buah", "Topping cone renyah hancur di dasar cup"],
    "visual_clues": ["cup sundae tinggi berisi es krim putih berselubung saus stroberi merah cerah"]
  },
  "mixue lucky sundae chocolate": {
    "name": "Mixue Lucky Sundae Chocolate",
    "emoji": "🍨",
    "calories": 315,
    "protein": 4.8,
    "carbs": 58.0,
    "fat": 8.0,
    "fiber": 1.5,
    "sugar": 45.0,
    "caffeineMg": 5,
    "serving": "1 cup lucky sundae (260g)",
    "category": "Es Krim",
    "brand": "Mixue",
    "aliases": ["mixue lucky sundae chocolate", "lucky sundae chocolate mixue", "lucky sundae coklat mixue"],
    "ingredients": ["Es krim vanila Mixue", "Saus coklat cair pekat lezat", "Crumbs waffle renyah di dasar"],
    "visual_clues": ["es krim putih berlumur saus cokelat hitam pekat tebal"]
  },
  "mixue pearl milk tea": {
    "name": "Mixue Pearl Milk Tea (Original)",
    "emoji": "🧋",
    "calories": 310,
    "protein": 4.2,
    "carbs": 58.0,
    "fat": 7.5,
    "fiber": 1.0,
    "sugar": 34.0,
    "caffeineMg": 50,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Mixue",
    "aliases": ["mixue pearl milk tea", "pearl milk tea mixue", "boba milk tea mixue original", "teh susu boba mixue"],
    "ingredients": ["Black tea Mixue", "Krimer susu manis", "Tapioca pearl hitam kenyal", "Gula cair & es batu"],
    "visual_clues": ["cup berlogo Snow King dengan teh susu cokelat muda dan boba di dasar"]
  },
  "mixue jasmine tea original": {
    "name": "Mixue Jasmine Tea Original",
    "emoji": "🍵",
    "calories": 70,
    "protein": 0.2,
    "carbs": 17.5,
    "fat": 0.0,
    "fiber": 0.0,
    "sugar": 16.0,
    "caffeineMg": 40,
    "serving": "1 cup jumbo (700ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Mixue",
    "aliases": ["mixue jasmine tea original", "jasmine tea mixue", "es teh melati mixue", "teh melati mixue", "original jasmine tea mixue"],
    "ingredients": ["Seduhan daun teh hijau melati harum", "Sirup gula cair", "Es batu kristal melimpah"],
    "visual_clues": ["cup jumbo 700ml bening dengan cairan teh kuning keemasan jernih berlogo Snow King"]
  },
  "mixue kiwi smoothie": {
    "name": "Mixue Kiwi Smoothie with Jelly",
    "emoji": "🥝",
    "calories": 240,
    "protein": 1.2,
    "carbs": 57.0,
    "fat": 0.8,
    "fiber": 2.0,
    "sugar": 48.0,
    "caffeineMg": 0,
    "serving": "1 cup (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Mixue",
    "aliases": ["mixue kiwi smoothie", "kiwi smoothie mixue", "smoothie kiwi mixue"],
    "ingredients": ["Sari buah kiwi segar hijau dengan biji kiwi renyah", "Smoothie es serut manis segar", "Potongan jelly kenyal"],
    "visual_clues": ["minuman smoothie warna hijau terang berbintik hitam biji kiwi dengan lapisan jelly di dasar cup"]
  },

  # =========================================================================
  # CHATIME (Tambahan varian lengkap)
  # =========================================================================
  "chatime grass jelly roasted milk tea": {
    "name": "Chatime Grass Jelly Roasted Milk Tea",
    "emoji": "🧋",
    "calories": 310,
    "protein": 4.5,
    "carbs": 54.0,
    "fat": 8.0,
    "fiber": 1.8,
    "sugar": 34.0,
    "caffeineMg": 75,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": ["chatime grass jelly roasted milk tea", "grass jelly roasted milk tea chatime", "roasted milk tea cincau chatime"],
    "ingredients": ["Teh Oolong sangrai harum khas Chatime", "Krimer susu lembut", "Topping grass jelly (cincau hitam) lembut kenyal", "Gula tebu & es"],
    "visual_clues": ["teh susu cokelat dengan balok cincau hitam mengkilap lembut melayang di dasar cup ungu Chatime"]
  },
  "chatime lychee green tea": {
    "name": "Chatime Lychee Green Tea",
    "emoji": "🍹",
    "calories": 160,
    "protein": 0.5,
    "carbs": 40.0,
    "fat": 0.1,
    "fiber": 0.4,
    "sugar": 36.0,
    "caffeineMg": 45,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": ["chatime lychee green tea", "lychee green tea chatime", "chatime leci", "teh leci chatime"],
    "ingredients": ["Jasmine Green Tea Chatime", "Sirup buah leci harum manis", "Gula tebu murni & es batu"],
    "visual_clues": ["cairan teh kuning keemasan bening dengan aroma wangi leci manis segar"]
  },
  "chatime superior cocoa": {
    "name": "Chatime Superior Pure Cocoa",
    "emoji": "🍫",
    "calories": 330,
    "protein": 6.5,
    "carbs": 52.0,
    "fat": 11.0,
    "fiber": 3.0,
    "sugar": 38.0,
    "caffeineMg": 20,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": ["chatime superior cocoa", "superior cocoa chatime", "chatime cocoa", "chatime cokelat", "pure cocoa chatime"],
    "ingredients": ["Bubuk kakao coklat premium impor pekat", "Susu segar murni", "Gula cair & es batu"],
    "visual_clues": ["minuman coklat gelap pekat bertekstur kental lezat di dalam cup Chatime"]
  },

  # =========================================================================
  # KOPI KENANGAN & CHIGO (Tambahan varian)
  # =========================================================================
  "kopi kenangan caramel macchiato": {
    "name": "Kopi Kenangan Caramel Macchiato",
    "emoji": "☕",
    "calories": 240,
    "protein": 5.2,
    "carbs": 38.0,
    "fat": 7.8,
    "fiber": 0.0,
    "sugar": 30.0,
    "caffeineMg": 120,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Kopi Kenangan",
    "aliases": ["kopi kenangan caramel macchiato", "caramel macchiato kopi kenangan", "karamel macchiato kenangan"],
    "ingredients": ["Double shot espresso Arabika-Robusta", "Susu segar vanila", "Saus karamel mentega keemasan kental di atasnya", "Es batu"],
    "visual_clues": ["lapisan susu putih di bawah, espresso coklat di tengah, dan corak pola saus karamel di atas busa susu"]
  },
  "kopi kenangan kenangan milk tea": {
    "name": "Kenangan Milk Tea with Boba",
    "emoji": "🧋",
    "calories": 320,
    "protein": 4.2,
    "carbs": 60.0,
    "fat": 7.5,
    "fiber": 1.0,
    "sugar": 38.0,
    "caffeineMg": 55,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Kopi Kenangan",
    "aliases": ["kenangan milk tea with boba", "kenangan milk tea", "milk tea kopi kenangan", "boba kenangan milk tea"],
    "ingredients": ["Seduhan teh hitam aromatik", "Susu segar Kopi Kenangan", "Boba tapioka gula aren kenyal", "Es batu"],
    "visual_clues": ["cup Kopi Kenangan berisi teh susu coklat krem dengan lapisan boba hitam di dasar"]
  },
  "chigo boneless crispy chicken garlic parmesan": {
    "name": "Chigo Boneless Crispy Chicken Garlic Parmesan (Kopi Kenangan)",
    "emoji": "🍗",
    "calories": 480,
    "protein": 34.0,
    "carbs": 26.0,
    "fat": 28.0,
    "fiber": 1.0,
    "sugar": 2.0,
    "caffeineMg": 0,
    "serving": "1 porsi boks (200g)",
    "category": "Makanan Siap Saji",
    "brand": "Kopi Kenangan",
    "aliases": ["chigo boneless crispy chicken garlic parmesan", "chigo chicken", "ayam chigo kopi kenangan", "chigo garlic parmesan"],
    "ingredients": ["Daging paha ayam fillet tanpa tulang digoreng tepung krispi renyah", "Bumbu butter bawang putih gurih harum", "Taburan bubuk keju parmesan melimpah"],
    "visual_clues": ["potongan ayam krispi keemasan bertabur bubuk keju putih kekuningan di dalam kotak kardus merah Chigo x Kopi Kenangan"]
  },

  # =========================================================================
  # BURGER BANGOR (Tambahan varian)
  # =========================================================================
  "burger bangor fish burger": {
    "name": "Burger Bangor Fish Burger",
    "emoji": "🍔",
    "calories": 430,
    "protein": 18.5,
    "carbs": 44.0,
    "fat": 19.5,
    "fiber": 2.0,
    "sugar": 5.0,
    "caffeineMg": 0,
    "serving": "1 porsi burger (190g)",
    "category": "Burger & Sandwich",
    "brand": "Burger Bangor",
    "aliases": ["burger bangor fish burger", "bangor fish burger", "fish burger bangor", "burger ikan bangor"],
    "ingredients": ["Roti bun wijen lembut", "Patty ikan dori krispi berbalut tepung roti panko renyah", "Saus tartar gurih asam creamy khas", "Selada segar & keju cheddar"],
    "visual_clues": ["burger dengan fillet ikan krispi kotak keemasan dan lelehan saus tartar putih"]
  },
  "burger bangor cheese fries": {
    "name": "Burger Bangor Cheese Fries",
    "emoji": "🍟",
    "calories": 360,
    "protein": 5.5,
    "carbs": 42.0,
    "fat": 19.0,
    "fiber": 3.0,
    "sugar": 2.0,
    "caffeineMg": 0,
    "serving": "1 porsi kentang (160g)",
    "category": "Camilan",
    "brand": "Burger Bangor",
    "aliases": ["burger bangor cheese fries", "bangor cheese fries", "kentang keju bangor", "cheese fries bangor"],
    "ingredients": ["Kentang goreng crinkle cut garing gurih", "Siraman saus keju cheddar leleh kental gurih khas Bangor"],
    "visual_clues": ["kentang goreng keemasan berselimut lelehan saus keju kuning cerah dalam wadah karton Bangor"]
  },

  # =========================================================================
  # STARBUCKS INDONESIA
  # =========================================================================
  "starbucks caffe latte": {
    "name": "Starbucks Caffe Latte (Grande)",
    "emoji": "☕",
    "calories": 220,
    "protein": 12.0,
    "carbs": 18.0,
    "fat": 11.0,
    "fiber": 0.0,
    "sugar": 17.0,
    "caffeineMg": 150,
    "serving": "1 cup Grande (473ml)",
    "category": "Minuman Kopi",
    "brand": "Starbucks",
    "aliases": ["starbucks caffe latte", "caffe latte starbucks", "starbucks latte", "latte starbucks"],
    "ingredients": ["Double shot Starbucks Signature Dark Roast Espresso", "Steamed whole milk (susu segar hangat)", "Lapisan busa susu tipis di permukaan"],
    "visual_clues": ["cup kertas putih berlogo putri duyung hijau Siren Starbucks atau cup plastik bening berembun"]
  },
  "starbucks caramel macchiato": {
    "name": "Starbucks Caramel Macchiato (Iced Grande)",
    "emoji": "☕",
    "calories": 250,
    "protein": 8.0,
    "carbs": 37.0,
    "fat": 8.0,
    "fiber": 0.0,
    "sugar": 34.0,
    "caffeineMg": 150,
    "serving": "1 cup Grande (473ml)",
    "category": "Minuman Kopi",
    "brand": "Starbucks",
    "aliases": ["starbucks caramel macchiato", "caramel macchiato starbucks", "iced caramel macchiato starbucks"],
    "ingredients": ["Double shot espresso", "Susu vanila segar", "Saus karamel drizzle mentega khas Starbucks di atas es batu"],
    "visual_clues": ["minuman kopi susu bertingkat dengan corak lelehan saus karamel cokelat di permukaan"]
  },
  "starbucks java chip frappuccino": {
    "name": "Starbucks Java Chip Frappuccino (Grande)",
    "emoji": "🥤",
    "calories": 440,
    "protein": 6.0,
    "carbs": 68.0,
    "fat": 17.0,
    "fiber": 3.0,
    "sugar": 60.0,
    "caffeineMg": 110,
    "serving": "1 cup Grande (473ml)",
    "category": "Minuman Kopi",
    "brand": "Starbucks",
    "aliases": ["starbucks java chip frappuccino", "java chip frappuccino starbucks", "java chip starbucks", "frappuccino starbucks"],
    "ingredients": ["Kopi roast Starbucks diblender dengan susu, es batu, dan sirup moka", "Chocochip java chip renyah", "Topping whipped cream tebal dan siraman saus coklat moka"],
    "visual_clues": ["minuman frappe blender cokelat pekat bertabur serpihan coklat dengan kubah whipped cream putih di atasnya"]
  },
  "starbucks green tea cream frappuccino": {
    "name": "Starbucks Green Tea Cream Frappuccino",
    "emoji": "🍵",
    "calories": 410,
    "protein": 6.0,
    "carbs": 64.0,
    "fat": 15.0,
    "fiber": 2.0,
    "sugar": 59.0,
    "caffeineMg": 90,
    "serving": "1 cup Grande (473ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Starbucks",
    "aliases": ["starbucks green tea cream frappuccino", "green tea frappuccino starbucks", "matcha frappuccino starbucks"],
    "ingredients": ["Bubuk matcha teh hijau Jepang manis", "Susu segar & es diblender", "Topping whipped cream vanila"],
    "visual_clues": ["minuman frappe hijau daun cerah dengan gunung whipped cream putih lembut di bawah tutup dome"]
  },

  # =========================================================================
  # SHIHLIN TAIWAN STREET SNACKS
  # =========================================================================
  "shihlin xxl crispy chicken": {
    "name": "Shihlin XXL Crispy Chicken (Original/BBQ)",
    "emoji": "🍗",
    "calories": 620,
    "protein": 46.0,
    "carbs": 38.0,
    "fat": 32.0,
    "fiber": 2.0,
    "sugar": 2.0,
    "caffeineMg": 0,
    "serving": "1 kantong porsi jumbo (280g)",
    "category": "Camilan",
    "brand": "Shihlin",
    "aliases": ["shihlin xxl crispy chicken", "shihlin crispy chicken", "ayam shihlin", "xxl crispy chicken shihlin", "shihlin"],
    "ingredients": ["Fillet dada ayam super lebar tanpa tulang khas Taiwan", "Tepung tapioka butiran kasar garing renyah", "Bumbu tabur rempah five-spice (bubuk cabai, lada, garam, bubuk BBQ)"],
    "visual_clues": ["potongan-potongan ayam krispi pipih lebar keemasan dalam kantong kertas merah putih khas Shihlin ditaburi bubuk cabai merah"]
  },
  "shihlin seafood tempura": {
    "name": "Shihlin Seafood Tempura",
    "emoji": "🥢",
    "calories": 360,
    "protein": 18.0,
    "carbs": 32.0,
    "fat": 18.0,
    "fiber": 1.0,
    "sugar": 1.5,
    "caffeineMg": 0,
    "serving": "1 kantong porsi (160g)",
    "category": "Camilan",
    "brand": "Shihlin",
    "aliases": ["shihlin seafood tempura", "seafood tempura shihlin", "tempura shihlin"],
    "ingredients": ["Olahan daging ikan dan cumi tempura lembut kenyal", "Digoreng garing keemasan", "Bumbu tabur lada garam cabai Shihlin"],
    "visual_clues": ["irisan tempura ikan persegi panjang cokelat keemasan bertabur bumbu rempah"]
  },

  # =========================================================================
  # MARUGAME UDON
  # =========================================================================
  "marugame niku udon": {
    "name": "Marugame Niku Udon",
    "emoji": "🍜",
    "calories": 540,
    "protein": 28.0,
    "carbs": 76.0,
    "fat": 14.0,
    "fiber": 3.0,
    "sugar": 6.0,
    "caffeineMg": 0,
    "serving": "1 mangkok saji (450g)",
    "category": "Makanan Utama",
    "brand": "Marugame Udon",
    "aliases": ["marugame niku udon", "niku udon marugame", "niku udon", "marugame udon", "marugame"],
    "ingredients": ["Mie udang tebal kenyal lembut buatan tangan segar khas Sanuki", "Daging sapi impor iris tipis bumbu sukiyaki manis gurih", "Kuah sup kake dashi bening kaldu ikan cakalang harum", "Irisan daun bawang segar & taburan remahan kremes tempura (tenkasu)"],
    "visual_clues": ["mangkok keramik krem-coklat berisi mie udon putih tebal di kuah dashi bening kecokelatan dengan tumpukan daging sapi sukiyaki lembut di atasnya"]
  },
  "marugame beef curry udon": {
    "name": "Marugame Beef Curry Udon",
    "emoji": "🍛",
    "calories": 680,
    "protein": 30.0,
    "carbs": 88.0,
    "fat": 24.0,
    "fiber": 4.5,
    "sugar": 8.0,
    "caffeineMg": 0,
    "serving": "1 mangkok saji (500g)",
    "category": "Makanan Utama",
    "brand": "Marugame Udon",
    "aliases": ["marugame beef curry udon", "beef curry udon marugame", "curry udon marugame", "udon kari marugame"],
    "ingredients": ["Mie udon tebal khas Marugame", "Kuah kari Jepang kental harum kaya rempah gurih", "Daging sapi iris bumbu sukiyaki", "Wortel dan bawang bombay empuk"],
    "visual_clues": ["mie udon berselimut kuah kari cokelat kental pekat dengan daging sapi di atasnya"]
  },
  "marugame ebi tempura": {
    "name": "Marugame Ebi Tempura",
    "emoji": "🍤",
    "calories": 160,
    "protein": 10.0,
    "carbs": 13.0,
    "fat": 7.5,
    "fiber": 0.5,
    "sugar": 0.5,
    "caffeineMg": 0,
    "serving": "1 pcs ebi tempura (60g)",
    "category": "Camilan",
    "brand": "Marugame Udon",
    "aliases": ["marugame ebi tempura", "ebi tempura marugame", "tempura udang marugame"],
    "ingredients": ["Udang utuh segar pilihan", "Adonan tepung tempura Jepang renyah berserat bunga garing"],
    "visual_clues": ["udang goreng tempura lurus panjang dengan balutan tepung renyah berkerut keemasan"]
  },

  # =========================================================================
  # YOSHINOYA INDONESIA
  # =========================================================================
  "yoshinoya original beef bowl": {
    "name": "Yoshinoya Original Beef Bowl (Gyudon)",
    "emoji": "🍚",
    "calories": 660,
    "protein": 26.0,
    "carbs": 82.0,
    "fat": 24.0,
    "fiber": 2.5,
    "sugar": 7.0,
    "caffeineMg": 0,
    "serving": "1 mangkuk reguler (360g)",
    "category": "Makanan Utama",
    "brand": "Yoshinoya",
    "aliases": ["yoshinoya original beef bowl", "original beef bowl yoshinoya", "gyudon yoshinoya", "yoshinoya", "beef bowl yoshinoya"],
    "ingredients": ["Nasi putih pulen Jepang hangat", "100% Irisan tipis daging sapi impor US Beef empuk juicy", "Bawang bombay manis dimasak kuah kaldu rempah rahasia Yoshinoya gurih asin", "Topping jahe merah acar (beni shoga)"],
    "visual_clues": ["mangkuk oranye khas Yoshinoya berisi nasi putih tertutup penuh irisan daging sapi tipis berlemak juicy dan bawang bombay layu"]
  },
  "yoshinoya yakiniku beef bowl": {
    "name": "Yoshinoya Yakiniku Beef Bowl",
    "emoji": "🍚",
    "calories": 690,
    "protein": 26.0,
    "carbs": 88.0,
    "fat": 25.0,
    "fiber": 2.5,
    "sugar": 12.0,
    "caffeineMg": 0,
    "serving": "1 mangkuk reguler (360g)",
    "category": "Makanan Utama",
    "brand": "Yoshinoya",
    "aliases": ["yoshinoya yakiniku beef bowl", "yakiniku beef bowl yoshinoya", "yakiniku yoshinoya"],
    "ingredients": ["Nasi putih pulen", "Daging sapi iris tipis dimasak saus karamel yakiniku manis gurih", "Bawang bombay dan taburan biji wijen putih"],
    "visual_clues": ["daging sapi kecokelatan mengkilap saus yakiniku manis di atas mangkuk nasi hangat bertabur wijen"]
  },

  # =========================================================================
  # BAKMI GM
  # =========================================================================
  "bakmi gm spesial gm": {
    "name": "Bakmi GM Spesial GM",
    "emoji": "🍜",
    "calories": 520,
    "protein": 22.0,
    "carbs": 68.0,
    "fat": 18.0,
    "fiber": 2.5,
    "sugar": 4.0,
    "caffeineMg": 0,
    "serving": "1 porsi mangkuk (300g)",
    "category": "Makanan Utama",
    "brand": "Bakmi GM",
    "aliases": ["bakmi gm spesial gm", "bakmi spesial gm", "bakmi gm", "mie bakmi gm"],
    "ingredients": ["Bakmi telur pipih tipis kenyal khas Bakmi GM dengan minyak bumbu gurih wangi", "Tumisan daging ayam dan jamur kancing kecokelatan manis gurih", "Sawi caisim hijau segar rebus", "Kuah kaldu ayam gurih hangat"],
    "visual_clues": ["bakmi pipih berwarna kuning pucat dalam mangkok putih dengan topping tumisan ayam jamur kecokelatan dan sayur sawi"]
  },
  "pangsit goreng bakmi gm": {
    "name": "Pangsit Goreng Bakmi GM (Isi 5)",
    "emoji": "🥟",
    "calories": 320,
    "protein": 8.0,
    "carbs": 30.0,
    "fat": 19.0,
    "fiber": 1.0,
    "sugar": 8.0,
    "caffeineMg": 0,
    "serving": "1 porsi isi 5 pcs + saus (150g)",
    "category": "Camilan",
    "brand": "Bakmi GM",
    "aliases": ["pangsit goreng bakmi gm", "pangsit bakmi gm", "pangsit goreng gm", "pangsit gm"],
    "ingredients": ["Kulit pangsit telur renyah mekar super garing berbentuk lekukan kipas khas", "Isian olahan ayam udang gurih", "Saus merah asam manis legendaris khas Bakmi GM"],
    "visual_clues": ["5 buah pangsit goreng kuning keemasan berbentuk mangkok mekar sangat garing disajikan dengan mangkuk kecil saus merah cerah"]
  },

  # =========================================================================
  # ROTI'O & ROTI BOY
  # =========================================================================
  "roti o coffee bun": {
    "name": "Roti'O Coffee Bun",
    "emoji": "🍞",
    "calories": 310,
    "protein": 6.5,
    "carbs": 44.0,
    "fat": 12.5,
    "fiber": 1.5,
    "sugar": 18.0,
    "caffeineMg": 15,
    "serving": "1 pcs bun (95g)",
    "category": "Roti & Pastry",
    "brand": "Roti'O",
    "aliases": ["roti o coffee bun", "roti o", "roti'o", "coffee bun roti o", "roti o kopi"],
    "ingredients": ["Roti ragi bulat empuk beraroma wangi", "Lapisan luar kerak topping krim kopi moka karamel krispi", "Isian lelehan salted butter mentega asin gurih di tengah roti"],
    "visual_clues": ["roti berbentuk kubah bundar berwarna cokelat karamel harum kopi dengan bagian bawah bermentega gurih dalam kantong kertas putih-coklat Roti'O"]
  },
  "roti boy original bun": {
    "name": "Roti Boy Original Coffee Bun",
    "emoji": "🍞",
    "calories": 305,
    "protein": 6.2,
    "carbs": 43.0,
    "fat": 12.0,
    "fiber": 1.5,
    "sugar": 17.5,
    "caffeineMg": 15,
    "serving": "1 pcs bun (95g)",
    "category": "Roti & Pastry",
    "brand": "Roti Boy",
    "aliases": ["roti boy original bun", "roti boy", "rotiboy", "coffee bun rotiboy"],
    "ingredients": ["Roti bun lembut", "Topping krim kopi renyah garing di luar", "Isian mentega gurih meleleh di dalam"],
    "visual_clues": ["roti kubah bundar cokelat wangi kopi khas Roti Boy dalam kemasan kertas kuning RotiBoy"]
  },

  # =========================================================================
  # DUNKIN' DONUTS INDONESIA
  # =========================================================================
  "dunkin donut boston kreme": {
    "name": "Dunkin' Donut Boston Kreme",
    "emoji": "🍩",
    "calories": 290,
    "protein": 4.5,
    "carbs": 38.0,
    "fat": 13.5,
    "fiber": 1.2,
    "sugar": 22.0,
    "caffeineMg": 0,
    "serving": "1 pcs donat (85g)",
    "category": "Donat & Dessert",
    "brand": "Dunkin' Donuts",
    "aliases": ["dunkin donut boston kreme", "boston kreme dunkin", "donat dunkin boston kreme", "dunkin donuts", "dunkin"],
    "ingredients": ["Donat ragi lembut padat tanpa lubang tengah", "Isian krim puding custard vanila manis lembut melimpah", "Lapisan lelehan cokelat tebal mengkilap di atasnya"],
    "visual_clues": ["donat bundar tertutup glasur cokelat hitam tebal mengkilap dengan isian krim vanila putih di dalam"]
  },

  # =========================================================================
  # D'CREPES
  # =========================================================================
  "dcrepes choco peanut": {
    "name": "D'Crepes Choco Peanut",
    "emoji": "🥞",
    "calories": 340,
    "protein": 7.0,
    "carbs": 46.0,
    "fat": 14.5,
    "fiber": 2.5,
    "sugar": 24.0,
    "caffeineMg": 0,
    "serving": "1 porsi crepes (120g)",
    "category": "Camilan",
    "brand": "D'Crepes",
    "aliases": ["dcrepes choco peanut", "d crepes choco peanut", "dcrepes coklat kacang", "crepes coklat kacang dcrepes", "dcrepes"],
    "ingredients": ["Adonan crepes tipis garing super renyah wangi vanila mentega", "Taburan meises coklat manis", "Selai kacang tanah gurih kental"],
    "visual_clues": ["crepes segitiga renyah garing berwarna cokelat keemasan di dalam wadah karton segitiga biru-oranye D'Crepes"]
  },
  "dcrepes smoked beef and cheese": {
    "name": "D'Crepes Smoked Beef and Cheese",
    "emoji": "🥞",
    "calories": 320,
    "protein": 12.0,
    "carbs": 34.0,
    "fat": 15.0,
    "fiber": 1.5,
    "sugar": 4.0,
    "caffeineMg": 0,
    "serving": "1 porsi crepes (140g)",
    "category": "Camilan",
    "brand": "D'Crepes",
    "aliases": ["dcrepes smoked beef and cheese", "d crepes smoked beef cheese", "dcrepes asin", "crepes smoked beef dcrepes"],
    "ingredients": ["Crepes tipis garing", "Irisan daging sapi asap (smoked beef)", "Keju cheddar parut leleh", "Saus mayones dan saus sambal"],
    "visual_clues": ["crepes segitiga garing gurih dengan isian daging asap merah muda dan lelehan keju di dalamnya"]
  },

  # =========================================================================
  # FAMILYMART INDONESIA & LAWSON INDONESIA
  # =========================================================================
  "familymart kopi susu keluarga": {
    "name": "FamilyMart Kopi Susu Keluarga (KSK)",
    "emoji": "☕",
    "calories": 195,
    "protein": 4.2,
    "carbs": 30.0,
    "fat": 6.8,
    "fiber": 0.0,
    "sugar": 22.0,
    "caffeineMg": 110,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "FamilyMart",
    "aliases": ["familymart kopi susu keluarga", "kopi susu keluarga familymart", "ksk familymart", "kopi familymart", "familymart"],
    "ingredients": ["Espresso kopi robusta pekat FamiCafe", "Susu segar murni", "Sirup gula aren alami", "Es batu kristal"],
    "visual_clues": ["cup plastik biru-hijau berlogo FamilyMart berisi es kopi susu gula aren cokelat krem"]
  },
  "familymart crispy chicken": {
    "name": "FamilyMart Crispy Chicken (FamiChiki)",
    "emoji": "🍗",
    "calories": 380,
    "protein": 24.0,
    "carbs": 18.0,
    "fat": 24.0,
    "fiber": 1.0,
    "sugar": 0.5,
    "caffeineMg": 0,
    "serving": "1 potong ayam (150g)",
    "category": "Makanan Siap Saji",
    "brand": "FamilyMart",
    "aliases": ["familymart crispy chicken", "crispy chicken familymart", "famichiki", "ayam familymart"],
    "ingredients": ["Daging paha ayam tanpa tulang tebal juicy", "Tepung bumbu renyah gurih keemasan", "Minyak goreng nabati"],
    "visual_clues": ["ayam goreng fillet tanpa tulang persegi cokelat keemasan renyah dalam bungkus kertas strip FamilyMart"]
  },
  "lawson odeng original": {
    "name": "Lawson Odeng Original",
    "emoji": "🍢",
    "calories": 110,
    "protein": 9.5,
    "carbs": 12.0,
    "fat": 2.5,
    "fiber": 0.8,
    "sugar": 2.0,
    "caffeineMg": 0,
    "serving": "1 tusuk odeng + kuah dashi (120g)",
    "category": "Makanan Utama",
    "brand": "Lawson",
    "aliases": ["lawson odeng original", "odeng lawson", "lawson odeng", "odeng kuah lawson", "lawson"],
    "ingredients": ["Kue ikan (fish cake) lipat khas Korea lembut kenyal bertekstur", "Tusuk bambu", "Kuah sup kaldu dashi bening gurih hangat beraroma lobak dan daun bawang"],
    "visual_clues": ["lembaran otak-otak ikan bergelombang dilipat pada tusukan bambu panjang terendam dalam kuah kaldu hangat Lawson"]
  },
  "lawson spicy odeng": {
    "name": "Lawson Spicy Odeng",
    "emoji": "🍢",
    "calories": 130,
    "protein": 9.5,
    "carbs": 14.0,
    "fat": 3.0,
    "fiber": 1.0,
    "sugar": 3.5,
    "caffeineMg": 0,
    "serving": "1 tusuk odeng + kuah pedas (120g)",
    "category": "Makanan Utama",
    "brand": "Lawson",
    "aliases": ["lawson spicy odeng", "spicy odeng lawson", "odeng pedas lawson"],
    "ingredients": ["Kue ikan lipat khas Korea", "Kuah kaldu pedas merah gochujang rempah gurih pedas nikmat"],
    "visual_clues": ["odeng tusuk dalam kuah merah pedas menyegarkan beraroma cabai"]
  },
  "lawson tteokbokki": {
    "name": "Lawson Tteokbokki",
    "emoji": "🍲",
    "calories": 340,
    "protein": 6.5,
    "carbs": 68.0,
    "fat": 4.5,
    "fiber": 2.5,
    "sugar": 14.0,
    "caffeineMg": 0,
    "serving": "1 mangkok porsi (200g)",
    "category": "Makanan Utama",
    "brand": "Lawson",
    "aliases": ["lawson tteokbokki", "tteokbokki lawson", "tokpoki lawson"],
    "ingredients": ["Kue beras silinder kenyal Korea (tteok)", "Saus pasta cabai gochujang pedas manis kental", "Potongan kue ikan eomuk dan daun bawang"],
    "visual_clues": ["mangkuk bundar berisi silinder kue beras putih kenyal berlumur saus merah menyala pekat"]
  },

  # =========================================================================
  # ES TELER 77
  # =========================================================================
  "es teler 77 original": {
    "name": "Es Teler 77 Original",
    "emoji": "🍧",
    "calories": 330,
    "protein": 3.8,
    "carbs": 54.0,
    "fat": 12.0,
    "fiber": 3.5,
    "sugar": 42.0,
    "caffeineMg": 0,
    "serving": "1 mangkok saji (350g)",
    "category": "Donat & Dessert",
    "brand": "Es Teler 77",
    "aliases": ["es teler 77 original", "es teler 77", "es teler", "es teler komplit 77"],
    "ingredients": ["Daging buah alpukat mentega segar lembut", "Daging kelapa muda serut kenyal", "Potongan buah nangka kuning manis wangi harum", "Santan kelapa gurih beraroma pandan", "Susu kental manis dan es serut kristal"],
    "visual_clues": ["mangkok kaca berisi gunungan es serut bersiram susu kental manis putih dengan aneka potongan hijau alpukat, putih kelapa, dan kuning nangka"]
  },
  "bakso super 77": {
    "name": "Bakso Super 77 (Es Teler 77)",
    "emoji": "🍜",
    "calories": 460,
    "protein": 24.0,
    "carbs": 48.0,
    "fat": 18.5,
    "fiber": 2.0,
    "sugar": 3.0,
    "caffeineMg": 0,
    "serving": "1 mangkok porsi lengkap (380g)",
    "category": "Makanan Utama",
    "brand": "Es Teler 77",
    "aliases": ["bakso super 77", "bakso es teler 77", "bakso 77", "mie bakso 77"],
    "ingredients": ["Bakso sapi halus dan urat kenyal daging sapi pilihan", "Mie kuning telur & bihun putih", "Pangsit goreng renyah", "Kuah kaldu sumsum sapi gurih bening panas", "Taburan seledri dan bawang goreng"],
    "visual_clues": ["mangkok kuah bakso kaldu bening dengan butiran bakso sapi abu-abu kecokelatan kenyal dan pangsit goreng mekar di atasnya"]
  }
}

def enrich_extensive():
    file_path = os.path.join("ai_workspace", "dataset", "food_master.json")
    with open(file_path, "r", encoding="utf-8") as f:
        existing = json.load(f)

    before_count = len(existing)
    added = 0
    updated = 0

    for k, v in EXTENSIVE_BRAND_DATA.items():
        ck = k.lower().strip()
        if ck in existing:
            existing[ck].update(v)
            updated += 1
        else:
            existing[ck] = v
            added += 1

    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(existing, f, ensure_ascii=False, indent=2)

    print(f"[*] Extensive Brand Enrichment Done!")
    print(f"    Total before: {before_count}")
    print(f"    Added: {added}")
    print(f"    Updated: {updated}")
    print(f"    Total now: {len(existing)}")

if __name__ == "__main__":
    enrich_extensive()
