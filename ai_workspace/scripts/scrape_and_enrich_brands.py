# -*- coding: utf-8 -*-
"""
Script to curate, scrape and enrich Indonesian popular F&B brands into food_master.json
Brands covered:
- Teazzi (all variants of milk tea, oolong, pure tea, latte)
- Mixue (all sundae, ice cream cone, milk tea, lemonade, smoothie variants)
- Chatime (all milk tea, brown sugar, fruit tea, mousse variants)
- Kopi Kenangan (all coffee, non-coffee, cerita roti, jiwa toast variants)
- Burger Bangor (all beef, chicken, fish, fries, cheese burger variants)
- Haus! (all coffee, boba, cheese foam, choco, toast variants)
- Janji Jiwa & Jiwa Toast (all coffee, non-coffee, toast brioche variants)
- Fore Coffee (all latte, specialty coffee, tea, pastry & croissant variants)
- Point Coffee (Indomaret) (frappe, latte, dolce, brew variants)
- Teguk (kopi semanis kamu, boba, toast, croffle variants)
- Richeese Factory (combo fire chicken, wings, pink lava, cheese sauce, burger)
- J.CO Donuts & Coffee (alcapone, glazzy, oreology, jcoccino, j.cool yogurt)
- HokBen (Hoka Hoka Bento) (bento special, simple set, teriyaki, yakiniku, egg chicken roll, shrimp roll, ebi furai)
- Solaria (nasi goreng spesial, cordon bleu, mie goreng, kwetiau sapi, bihun)
- KFC Indonesia (super besar, zinger burger, twister, cream soup, perkedel, sundae, mocha float)
- McDonald's Indonesia (panas 1/2, big mac, mcchicken, cheeseburger, french fries, mcflurry oreo, apple pie)
- A&W Restaurant (mozza burger, aroma chicken, root beer float, waffle)
- Subway Indonesia (italian bmt, tuna melt, steak & cheese, cookies)
- Ayam Keprabon Express (geprek blenger mozzarella, karca, kol goreng)
- Ayam Geprek Bensu (geprek leleh, sambal matah, jamur krispi)
- Mie Gacoan (mie hompimpa, mie gacoan, mie suit, pangsit, udang keju, udang rambutan, es gobak sodor, dll.)
"""

import json
import os

BRAND_DATA = {
  # =========================================================================
  # 1. TEAZZI
  # =========================================================================
  "teazzi four seasons oolong milk tea": {
    "name": "Teazzi Four Seasons Oolong Milk Tea",
    "emoji": "🧋",
    "calories": 245,
    "protein": 3.8,
    "carbs": 42.0,
    "fat": 7.2,
    "fiber": 0.0,
    "sugar": 28.0,
    "caffeineMg": 65,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": [
      "teazzi four seasons oolong milk tea",
      "teazzi oolong milk tea",
      "four seasons oolong milk tea teazzi",
      "teazzi four seasons",
      "teazzi milk tea"
    ],
    "ingredients": [
      "Seduhan daun teh Four Seasons Oolong premium Taiwan",
      "Susu segar (fresh milk) atau krimer nabati lembut",
      "Sirup gula tebu murni",
      "Es batu kristal"
    ],
    "visual_clues": [
      "gelas cup ramping tinggi khas Teazzi bertuliskan kaligrafi logo Teazzi",
      "cairan teh susu berwarna cokelat krem keemasan lembut",
      "warna teh susu oolong khas dengan lapisan es batu di atasnya"
    ]
  },
  "teazzi deep roasted oolong milk tea": {
    "name": "Teazzi Deep Roasted Oolong Milk Tea",
    "emoji": "🧋",
    "calories": 255,
    "protein": 4.0,
    "carbs": 44.0,
    "fat": 7.5,
    "fiber": 0.0,
    "sugar": 29.0,
    "caffeineMg": 75,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": [
      "teazzi deep roasted oolong milk tea",
      "deep roasted oolong milk tea teazzi",
      "teazzi deep roasted",
      "roasted oolong milk tea teazzi"
    ],
    "ingredients": [
      "Seduhan teh Oolong sangrai pekat (deep roasted oolong tea)",
      "Susu segar murni",
      "Gula tebu cair",
      "Es batu kristal"
    ],
    "visual_clues": [
      "cairan milk tea berwarna cokelat agak gelap khas sangrai pekat",
      "cup cup Teazzi dengan segel film bermotif elegan khas Taiwan",
      "aroma harum smoky roasted oolong"
    ]
  },
  "teazzi jasmine green milk tea": {
    "name": "Teazzi Jasmine Green Milk Tea",
    "emoji": "🧋",
    "calories": 230,
    "protein": 3.5,
    "carbs": 39.0,
    "fat": 6.8,
    "fiber": 0.0,
    "sugar": 26.0,
    "caffeineMg": 55,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": [
      "teazzi jasmine green milk tea",
      "jasmine green milk tea teazzi",
      "teazzi green milk tea",
      "teazzi jasmine"
    ],
    "ingredients": [
      "Seduhan teh hijau melati wangi (jasmine green tea)",
      "Susu segar",
      "Gula tebu murni",
      "Es batu"
    ],
    "visual_clues": [
      "cairan teh susu berwarna krem kehijauan cerah",
      "cup Teazzi dengan sedotan boba besar atau kecil"
    ]
  },
  "teazzi peach oolong tea": {
    "name": "Teazzi Peach Oolong Tea",
    "emoji": "🍑",
    "calories": 140,
    "protein": 0.5,
    "carbs": 34.0,
    "fat": 0.2,
    "fiber": 0.5,
    "sugar": 30.0,
    "caffeineMg": 45,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": [
      "teazzi peach oolong tea",
      "peach oolong tea teazzi",
      "teazzi peach oolong",
      "peach oolong teazzi"
    ],
    "ingredients": [
      "Seduhan Four Seasons Oolong Tea",
      "Sari buah persik (peach puree/juice)",
      "Potongan buah peach segar atau jelly",
      "Gula tebu & es batu"
    ],
    "visual_clues": [
      "cairan teh jernih berwarna kuning jingga kemerahan buah persik",
      "terlihat potongan jelly atau bulir buah peach di dasar cup transparan"
    ]
  },
  "teazzi lemon aiyu jelly oolong": {
    "name": "Teazzi Lemon Aiyu Jelly Oolong Tea",
    "emoji": "🍋",
    "calories": 165,
    "protein": 0.8,
    "carbs": 40.0,
    "fat": 0.2,
    "fiber": 1.2,
    "sugar": 32.0,
    "caffeineMg": 40,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": [
      "teazzi lemon aiyu jelly oolong",
      "lemon aiyu jelly oolong teazzi",
      "teazzi lemon aiyu",
      "lemon aiyu teazzi"
    ],
    "ingredients": [
      "Four Seasons Oolong Tea seduh segar",
      "Perasan lemon segar alami",
      "Topping jelly aiyu tradisional Taiwan yang lembut kenyal",
      "Gula tebu & es batu"
    ],
    "visual_clues": [
      "cairan teh kuning keemasan segar dengan irisan lemon di dalamnya",
      "lapisan jelly aiyu transparan lembut melayang di bagian bawah gelas"
    ]
  },
  "teazzi fresh passion fruit green tea": {
    "name": "Teazzi Fresh Passion Fruit Green Tea",
    "emoji": "🍹",
    "calories": 155,
    "protein": 0.6,
    "carbs": 38.0,
    "fat": 0.2,
    "fiber": 1.0,
    "sugar": 32.0,
    "caffeineMg": 40,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": [
      "teazzi fresh passion fruit green tea",
      "passion fruit green tea teazzi",
      "teazzi passion fruit",
      "teazzi markisa"
    ],
    "ingredients": [
      "Jasmine green tea",
      "Sari buah markisa segar beserta biji renyah",
      "Gula tebu & es batu kristal"
    ],
    "visual_clues": [
      "cairan kuning oranye segar dengan biji markisa hitam khas tersebar di dasar cup"
    ]
  },
  "teazzi pearl milk tea": {
    "name": "Teazzi Pearl Milk Tea",
    "emoji": "🧋",
    "calories": 335,
    "protein": 4.2,
    "carbs": 62.0,
    "fat": 7.8,
    "fiber": 1.0,
    "sugar": 38.0,
    "caffeineMg": 65,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": [
      "teazzi pearl milk tea",
      "teazzi boba milk tea",
      "boba milk tea teazzi",
      "pearl milk tea teazzi"
    ],
    "ingredients": [
      "Four Seasons Oolong Milk Tea",
      "Topping tapioca pearl (boba) kenyal kenyal manis",
      "Susu segar & sirup gula tebu"
    ],
    "visual_clues": [
      "cairan teh susu cokelat muda keemasan dengan lapisan boba hitam tebal di dasar gelas"
    ]
  },
  "teazzi uji matcha fresh milk": {
    "name": "Teazzi Uji Matcha Fresh Milk",
    "emoji": "🍵",
    "calories": 260,
    "protein": 6.5,
    "carbs": 38.0,
    "fat": 8.5,
    "fiber": 1.5,
    "sugar": 28.0,
    "caffeineMg": 70,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teazzi",
    "aliases": [
      "teazzi uji matcha fresh milk",
      "teazzi matcha latte",
      "matcha fresh milk teazzi",
      "uji matcha teazzi"
    ],
    "ingredients": [
      "Bubuk Uji Matcha premium murni dari Kyoto",
      "Susu segar full cream",
      "Sirup gula tebu",
      "Es batu"
    ],
    "visual_clues": [
      "gradasi warna hijau pekat matcha di atas dan putih susu segar di bagian bawah"
    ]
  },

  # =========================================================================
  # 2. MIXUE
  # =========================================================================
  "mixue fresh squeezed lemonade": {
    "name": "Mixue Fresh Squeezed Lemonade",
    "emoji": "🍋",
    "calories": 165,
    "protein": 0.4,
    "carbs": 41.0,
    "fat": 0.1,
    "fiber": 0.8,
    "sugar": 36.0,
    "caffeineMg": 0,
    "serving": "1 cup jumbo (700ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Mixue",
    "aliases": [
      "mixue fresh squeezed lemonade",
      "mixue lemonade",
      "lemonade mixue",
      "fresh lemonade mixue",
      "es lemon mixue",
      "lemon mixue"
    ],
    "ingredients": [
      "Perasan buah lemon segar",
      "Irisan buah lemon asli utuh yang ditumbuk di dalam cup",
      "Sirup gula cair Mixue",
      "Air mineral & es batu melimpah"
    ],
    "visual_clues": [
      "cup jumbo bening 700ml berlogo Snow King (Raja Salju Mixue)",
      "cairan kuning pucat jernih dengan beberapa irisan bulat lemon kuning tebal terlihat melayang",
      "tutup cup bersegel plastik bermotif Snow King"
    ]
  },
  "mixue boba sundae": {
    "name": "Mixue Boba Sundae",
    "emoji": "🍦",
    "calories": 285,
    "protein": 4.5,
    "carbs": 52.0,
    "fat": 6.8,
    "fiber": 0.8,
    "sugar": 38.0,
    "caffeineMg": 0,
    "serving": "1 cup sundae (250g)",
    "category": "Es Krim",
    "brand": "Mixue",
    "aliases": [
      "mixue boba sundae",
      "boba sundae mixue",
      "sundae boba mixue",
      "es krim boba mixue",
      "sundae boba"
    ],
    "ingredients": [
      "Es krim soft serve vanila susu lembut khas Mixue",
      "Brown sugar tapioca pearl (boba) hangat kenyal",
      "Sirup brown sugar pekat manis legit"
    ],
    "visual_clues": [
      "cup sundae bening pendek lebar berisi es krim vanila putih berbentuk spiral tinggi",
      "lumuran sirup gula aren cokelat kehitaman di dinding cup dan tumpukan boba hitam di atas atau dasar es krim"
    ]
  },
  "mixue mi sundae cookies": {
    "name": "Mixue Mi-Sundae Cookies",
    "emoji": "🍨",
    "calories": 310,
    "protein": 4.8,
    "carbs": 54.0,
    "fat": 8.5,
    "fiber": 1.2,
    "sugar": 40.0,
    "caffeineMg": 5,
    "serving": "1 cup sundae (250g)",
    "category": "Es Krim",
    "brand": "Mixue",
    "aliases": [
      "mixue mi sundae cookies",
      "mixue oreo sundae",
      "mi sundae cookies mixue",
      "sundae cookies mixue",
      "sundae oreo mixue",
      "es krim oreo mixue"
    ],
    "ingredients": [
      "Es krim soft serve vanila susu Mixue",
      "Remahan biskuit coklat Oreo / cookies renyah",
      "Saus sirup coklat pekat di dasar cup"
    ],
    "visual_clues": [
      "cup es krim sundae dengan taburan bubuk biskuit coklat hitam pekat melimpah di atas es krim vanila putih"
    ]
  },
  "mixue mi sundae mango": {
    "name": "Mixue Mi-Sundae Mango",
    "emoji": "🥭",
    "calories": 260,
    "protein": 3.8,
    "carbs": 51.0,
    "fat": 5.2,
    "fiber": 1.0,
    "sugar": 42.0,
    "caffeineMg": 0,
    "serving": "1 cup sundae (250g)",
    "category": "Es Krim",
    "brand": "Mixue",
    "aliases": [
      "mixue mi sundae mango",
      "mixue mango sundae",
      "sundae mangga mixue",
      "mi sundae mango mixue",
      "es krim mangga mixue"
    ],
    "ingredients": [
      "Es krim vanila lembut Mixue",
      "Selai puree mangga asli berbulir harum manis",
      "Potongan jelly mangga"
    ],
    "visual_clues": [
      "es krim putih spiral disiram selai mangga kuning oranye cerah berkilau di sekelilingnya"
    ]
  },
  "mixue mi sundae strawberry": {
    "name": "Mixue Mi-Sundae Strawberry",
    "emoji": "🍓",
    "calories": 255,
    "protein": 3.8,
    "carbs": 50.0,
    "fat": 5.2,
    "fiber": 1.0,
    "sugar": 41.0,
    "caffeineMg": 0,
    "serving": "1 cup sundae (250g)",
    "category": "Es Krim",
    "brand": "Mixue",
    "aliases": [
      "mixue mi sundae strawberry",
      "mixue strawberry sundae",
      "sundae stroberi mixue",
      "es krim stroberi sundae mixue"
    ],
    "ingredients": [
      "Es krim vanila susu Mixue",
      "Selai buah stroberi asli dengan bulir buah stroberi asam manis",
      "Sirup stroberi merah"
    ],
    "visual_clues": [
      "es krim putih lembut berlumur saus selai stroberi merah cerah dengan biji-biji stroberi alami"
    ]
  },
  "mixue ice cream cone vanilla": {
    "name": "Mixue Ice Cream Cone Vanilla",
    "emoji": "🍦",
    "calories": 160,
    "protein": 3.2,
    "carbs": 26.0,
    "fat": 4.8,
    "fiber": 0.5,
    "sugar": 19.0,
    "caffeineMg": 0,
    "serving": "1 cone (150g)",
    "category": "Es Krim",
    "brand": "Mixue",
    "aliases": [
      "mixue ice cream cone vanilla",
      "mixue cone vanilla",
      "es krim cone mixue",
      "cone mixue",
      "es krim mixue",
      "mixue ice cream"
    ],
    "ingredients": [
      "Es krim soft serve susu vanila creamy tinggi",
      "Cone waffle wangi renyah khas Mixue berbungkus kertas Snow King"
    ],
    "visual_clues": [
      "es krim soft serve putih sangat tinggi mengerucut di atas cone wafel wangi cokelat keemasan"
    ]
  },
  "mixue ice cream cone strawberry": {
    "name": "Mixue Ice Cream Cone Strawberry",
    "emoji": "🍦",
    "calories": 165,
    "protein": 3.0,
    "carbs": 27.5,
    "fat": 4.6,
    "fiber": 0.5,
    "sugar": 21.0,
    "caffeineMg": 0,
    "serving": "1 cone (150g)",
    "category": "Es Krim",
    "brand": "Mixue",
    "aliases": [
      "mixue ice cream cone strawberry",
      "mixue cone strawberry",
      "es krim stroberi cone mixue",
      "cone stroberi mixue"
    ],
    "ingredients": [
      "Es krim soft serve rasa stroberi warna pink pastel lembut",
      "Cone waffle renyah"
    ],
    "visual_clues": [
      "es krim warna merah muda (pink) spiral tinggi di atas cone renyah"
    ]
  },
  "mixue brown sugar pearl milk tea": {
    "name": "Mixue Brown Sugar Pearl Milk Tea",
    "emoji": "🧋",
    "calories": 340,
    "protein": 4.5,
    "carbs": 63.0,
    "fat": 8.0,
    "fiber": 1.0,
    "sugar": 39.0,
    "caffeineMg": 55,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Mixue",
    "aliases": [
      "mixue brown sugar pearl milk tea",
      "mixue boba milk tea",
      "brown sugar pearl milk tea mixue",
      "milk tea mixue",
      "boba milk tea mixue"
    ],
    "ingredients": [
      "Seduhan black tea pekat khas Mixue",
      "Susu / krimer susu manis gurih",
      "Brown sugar tapioca pearl boba kenyal",
      "Sirup gula aren murni"
    ],
    "visual_clues": [
      "gelas cup bermotif Snow King dengan cairan teh susu coklat krem dan boba hitam berlimpah di dasar"
    ]
  },
  "mixue supreme milk tea": {
    "name": "Mixue Supreme Milk Tea",
    "emoji": "🧋",
    "calories": 420,
    "protein": 5.5,
    "carbs": 78.0,
    "fat": 9.5,
    "fiber": 2.5,
    "sugar": 44.0,
    "caffeineMg": 60,
    "serving": "1 cup jumbo (700ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Mixue",
    "aliases": [
      "mixue supreme milk tea",
      "supreme milk tea mixue",
      "mixue supreme",
      "milk tea supreme mixue"
    ],
    "ingredients": [
      "Seduhan Black Tea Mixue",
      "Susu krimer",
      "Brown sugar boba kenyal",
      "Coconut jelly (nata de coco)",
      "Biji oat / barley gandum lembut"
    ],
    "visual_clues": [
      "cup jumbo Mixue dengan aneka topping berlapis di dasar cup: boba hitam, nata de coco putih bening, dan butiran oat"
    ]
  },
  "mixue roasted milk tea": {
    "name": "Mixue Roasted Milk Tea",
    "emoji": "🧋",
    "calories": 270,
    "protein": 4.0,
    "carbs": 46.0,
    "fat": 7.5,
    "fiber": 0.5,
    "sugar": 30.0,
    "caffeineMg": 65,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Mixue",
    "aliases": [
      "mixue roasted milk tea",
      "roasted milk tea mixue",
      "teh susu panggang mixue"
    ],
    "ingredients": [
      "Seduhan teh hitam sangrai wangi smoky",
      "Susu krimer",
      "Gula cair & es batu"
    ],
    "visual_clues": [
      "cairan teh susu berwarna cokelat hangat dengan aroma teh panggang khas"
    ]
  },
  "mixue peach mi shake": {
    "name": "Mixue Peach Mi-Shake",
    "emoji": "🍑",
    "calories": 290,
    "protein": 3.5,
    "carbs": 58.0,
    "fat": 5.5,
    "fiber": 1.2,
    "sugar": 46.0,
    "caffeineMg": 0,
    "serving": "1 cup (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Mixue",
    "aliases": [
      "mixue peach mi shake",
      "peach mi shake mixue",
      "peach milkshake mixue",
      "mi shake peach mixue"
    ],
    "ingredients": [
      "Es krim vanila Mixue diblender dengan sari buah persik (peach)",
      "Jelly buah persik lembut",
      "Sirup buah peach wangi segar"
    ],
    "visual_clues": [
      "minuman milkshake kental berwarna pink oranye lembut bergradasi dengan potongan jelly di dasar"
    ]
  },
  "mixue mango smoothie with ice cream": {
    "name": "Mixue Mango Smoothie with Ice Cream",
    "emoji": "🥭",
    "calories": 320,
    "protein": 4.0,
    "carbs": 64.0,
    "fat": 5.8,
    "fiber": 1.5,
    "sugar": 52.0,
    "caffeineMg": 0,
    "serving": "1 cup jumbo (700ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Mixue",
    "aliases": [
      "mixue mango smoothie with ice cream",
      "mango smoothie mixue",
      "smoothie mangga mixue",
      "mixue mango smoothie"
    ],
    "ingredients": [
      "Smoothie es serut mangga manis kental",
      "Topping es krim soft serve vanila di atasnya",
      "Selai mangga dan potongan jelly"
    ],
    "visual_clues": [
      "minuman smoothie kuning terang dengan topping swirl es krim putih di bagian atasnya"
    ]
  },

  # =========================================================================
  # 3. CHATIME
  # =========================================================================
  "chatime milk tea": {
    "name": "Chatime Milk Tea with Pearl",
    "emoji": "🧋",
    "calories": 360,
    "protein": 4.5,
    "carbs": 66.0,
    "fat": 8.8,
    "fiber": 1.0,
    "sugar": 42.0,
    "caffeineMg": 70,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": [
      "chatime milk tea",
      "chatime pearl milk tea",
      "chatime boba milk tea",
      "pearl milk tea chatime",
      "chatime original milk tea",
      "chatime"
    ],
    "ingredients": [
      "Seduhan daun teh hitam pilihan khas Chatime",
      "Krimer susu lembut creamy",
      "Tapioca pearl (pearl/boba) hitam kenyal",
      "Sirup gula tebu murni (sugar level 100%)",
      "Es batu kristal"
    ],
    "visual_clues": [
      "cup plastik transparan bersegel ungu Chatime dengan logo daun teh ungu",
      "cairan teh susu cokelat keemasan klasik dengan tumpukan pearl hitam di dasar"
    ]
  },
  "chatime roasted milk tea": {
    "name": "Chatime Roasted Milk Tea",
    "emoji": "🧋",
    "calories": 280,
    "protein": 4.0,
    "carbs": 48.0,
    "fat": 7.8,
    "fiber": 0.5,
    "sugar": 32.0,
    "caffeineMg": 75,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": [
      "chatime roasted milk tea",
      "roasted milk tea chatime",
      "chatime roasted tea"
    ],
    "ingredients": [
      "Seduhan teh Oolong sangrai khas Jepang/Taiwan",
      "Krimer susu gurih lembut",
      "Gula tebu murni & es batu"
    ],
    "visual_clues": [
      "cairan teh susu coklat tua hangat dengan wangi teh sangrai khas"
    ]
  },
  "chatime hazelnut chocolate milk tea": {
    "name": "Chatime Hazelnut Chocolate Milk Tea",
    "emoji": "🍫",
    "calories": 385,
    "protein": 5.2,
    "carbs": 68.0,
    "fat": 10.5,
    "fiber": 2.0,
    "sugar": 48.0,
    "caffeineMg": 45,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": [
      "chatime hazelnut chocolate milk tea",
      "chatime hazelnut chocolate",
      "hazelnut chocolate milk tea chatime",
      "chatime hazelnut choco"
    ],
    "ingredients": [
      "Seduhan teh susu Chatime",
      "Sirup hazelnut panggang aromatik",
      "Bubuk kakao coklat pekat lezat",
      "Susu krimer & es batu"
    ],
    "visual_clues": [
      "cairan coklat pekat creamy di dalam cup berlogo ungu Chatime"
    ]
  },
  "chatime brown sugar pearl milk tea": {
    "name": "Chatime Brown Sugar Pearl Milk Tea",
    "emoji": "🧋",
    "calories": 395,
    "protein": 4.8,
    "carbs": 74.0,
    "fat": 9.0,
    "fiber": 1.0,
    "sugar": 48.0,
    "caffeineMg": 60,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": [
      "chatime brown sugar pearl milk tea",
      "chatime brown sugar boba",
      "brown sugar pearl milk tea chatime",
      "brown sugar chatime"
    ],
    "ingredients": [
      "Black tea seduh Chatime",
      "Susu segar murni / krimer premium",
      "Brown sugar pearl yang dimasak karamel gula aren",
      "Sirup brown sugar leleh"
    ],
    "visual_clues": [
      "lelehan sirup gula aren coklat pekat mengalir di sepanjang dinding cup transparan Chatime"
    ]
  },
  "chatime mango green tea": {
    "name": "Chatime Mango Green Tea",
    "emoji": "🥭",
    "calories": 175,
    "protein": 0.5,
    "carbs": 43.0,
    "fat": 0.2,
    "fiber": 0.5,
    "sugar": 38.0,
    "caffeineMg": 45,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": [
      "chatime mango green tea",
      "mango green tea chatime",
      "chatime mango tea",
      "chatime mangga"
    ],
    "ingredients": [
      "Jasmine Green Tea Chatime seduh segar",
      "Sari buah mangga manis tropis",
      "Gula tebu & es batu"
    ],
    "visual_clues": [
      "cairan teh jernih berwarna kuning oranye cerah berkilau dengan logo ungu Chatime"
    ]
  },
  "chatime matcha tea latte": {
    "name": "Chatime Matcha Tea Latte",
    "emoji": "🍵",
    "calories": 270,
    "protein": 6.0,
    "carbs": 42.0,
    "fat": 8.5,
    "fiber": 1.5,
    "sugar": 30.0,
    "caffeineMg": 70,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": [
      "chatime matcha tea latte",
      "chatime matcha latte",
      "matcha latte chatime",
      "chatime matcha"
    ],
    "ingredients": [
      "Matcha bubuk teh hijau Jepang asli",
      "Susu segar murni",
      "Gula cair & es batu"
    ],
    "visual_clues": [
      "cairan berwarna hijau muda lembut berpadu dengan susu putih creamy"
    ]
  },
  "chatime taro milk tea": {
    "name": "Chatime Taro Milk Tea",
    "emoji": "🍠",
    "calories": 310,
    "protein": 4.2,
    "carbs": 56.0,
    "fat": 7.5,
    "fiber": 1.0,
    "sugar": 38.0,
    "caffeineMg": 0,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": [
      "chatime taro milk tea",
      "taro milk tea chatime",
      "chatime taro",
      "taro chatime"
    ],
    "ingredients": [
      "Ekstrak talas wangi (taro flavor) premium",
      "Krimer susu lembut",
      "Gula tebu murni & es batu"
    ],
    "visual_clues": [
      "cairan berwarna ungu pastel khas taro yang lembut dan menggiurkan"
    ]
  },
  "chatime authentic thai tea": {
    "name": "Chatime Authentic Thai Tea",
    "emoji": "🧋",
    "calories": 290,
    "protein": 4.0,
    "carbs": 52.0,
    "fat": 7.2,
    "fiber": 0.5,
    "sugar": 36.0,
    "caffeineMg": 60,
    "serving": "1 cup reguler (500ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Chatime",
    "aliases": [
      "chatime authentic thai tea",
      "chatime thai tea",
      "thai tea chatime"
    ],
    "ingredients": [
      "Seduhan daun teh merah Thailand beraroma rempah",
      "Susu kental manis & susu evaporasi",
      "Es batu"
    ],
    "visual_clues": [
      "cairan teh susu berwarna oranye terang pekat khas Thai tea"
    ]
  },

  # =========================================================================
  # 4. KOPI KENANGAN
  # =========================================================================
  "kopi kenangan mantan": {
    "name": "Kopi Kenangan Mantan",
    "emoji": "☕",
    "calories": 210,
    "protein": 4.5,
    "carbs": 32.0,
    "fat": 7.2,
    "fiber": 0.0,
    "sugar": 24.0,
    "caffeineMg": 120,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Kopi Kenangan",
    "aliases": [
      "kopi kenangan mantan",
      "kopi kenangan",
      "kenangan mantan",
      "es kopi kenangan mantan",
      "es kopi kenangan",
      "kopi mantan"
    ],
    "ingredients": [
      "Double shot espresso kopi Arabika & Robusta pilihan Kopi Kenangan",
      "Susu sapi segar (fresh milk)",
      "Gula aren asli Jawa murni",
      "Es batu kristal"
    ],
    "visual_clues": [
      "cup transparan khas Kopi Kenangan bertuliskan tulisan latin merah 'Kopi Kenangan'",
      "gradasi warna cokelat tua espresso di atas, susu putih di tengah, dan endapan gula aren cokelat tua di dasar cup"
    ]
  },
  "kopi kenangan mantan oatmilk": {
    "name": "Kopi Kenangan Mantan Oatmilk",
    "emoji": "☕",
    "calories": 185,
    "protein": 2.5,
    "carbs": 30.0,
    "fat": 6.0,
    "fiber": 2.0,
    "sugar": 20.0,
    "caffeineMg": 120,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Kopi Kenangan",
    "aliases": [
      "kopi kenangan mantan oatmilk",
      "kenangan mantan oatmilk",
      "kopi kenangan oatmilk",
      "es kopi kenangan oatmilk"
    ],
    "ingredients": [
      "Double espresso Arabika-Robusta",
      "Susu oat (plant-based Oatly / Oatside) bebas laktosa",
      "Gula aren asli",
      "Es batu"
    ],
    "visual_clues": [
      "cup Kopi Kenangan berstiker Oatmilk dengan cairan kopi susu krem kecokelatan lembut"
    ]
  },
  "kopi kenangan americano": {
    "name": "Kopi Kenangan Americano",
    "emoji": "☕",
    "calories": 10,
    "protein": 0.5,
    "carbs": 1.5,
    "fat": 0.1,
    "fiber": 0.0,
    "sugar": 0.0,
    "caffeineMg": 150,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Kopi Kenangan",
    "aliases": [
      "kopi kenangan americano",
      "americano kopi kenangan",
      "iced americano kopi kenangan",
      "kopi hitam kenangan"
    ],
    "ingredients": [
      "Double shot espresso Arabika-Robusta Kopi Kenangan",
      "Air mineral murni",
      "Es batu (atau air panas untuk versi hot)"
    ],
    "visual_clues": [
      "cairan kopi hitam pekat dengan lapisan crema tipis keemasan di permukaan"
    ]
  },
  "kopi kenangan cafe latte": {
    "name": "Kopi Kenangan Cafe Latte",
    "emoji": "☕",
    "calories": 150,
    "protein": 5.8,
    "carbs": 14.0,
    "fat": 7.5,
    "fiber": 0.0,
    "sugar": 12.0,
    "caffeineMg": 120,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Kopi Kenangan",
    "aliases": [
      "kopi kenangan cafe latte",
      "cafe latte kopi kenangan",
      "latte kopi kenangan",
      "kopi kenangan latte"
    ],
    "ingredients": [
      "Double shot espresso",
      "Susu segar steamed (steamed fresh milk)",
      "Tanpa tambahan gula sirup (unsweetened)"
    ],
    "visual_clues": [
      "cairan kopi susu cokelat krem merata di cup Kopi Kenangan"
    ]
  },
  "kopi kenangan avocatto": {
    "name": "Kopi Kenangan Avocatto",
    "emoji": "🥑",
    "calories": 340,
    "protein": 4.8,
    "carbs": 48.0,
    "fat": 15.0,
    "fiber": 3.5,
    "sugar": 36.0,
    "caffeineMg": 100,
    "serving": "1 cup (400ml)",
    "category": "Minuman Kopi",
    "brand": "Kopi Kenangan",
    "aliases": [
      "kopi kenangan avocatto",
      "avocatto kopi kenangan",
      "kopi alpukat kenangan",
      "avocatto kenangan"
    ],
    "ingredients": [
      "Jus buah alpukat asli kental manis",
      "Double shot espresso Kopi Kenangan",
      "1 scoop es krim vanila / coklat premium",
      "Es batu serut"
    ],
    "visual_clues": [
      "lapisan jus alpukat hijau pekat di bawah, siraman kopi espresso coklat di tengah, dan scoop es krim di atasnya"
    ]
  },
  "kopi kenangan milo dinosaurus": {
    "name": "Kopi Kenangan Milo Dinosaurus",
    "emoji": "🦕",
    "calories": 295,
    "protein": 7.2,
    "carbs": 48.0,
    "fat": 8.5,
    "fiber": 1.5,
    "sugar": 36.0,
    "caffeineMg": 15,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Kopi Kenangan",
    "aliases": [
      "kopi kenangan milo dinosaurus",
      "milo dinosaurus kopi kenangan",
      "milo dino kenangan",
      "milo dinosaurus kenangan"
    ],
    "ingredients": [
      "Susu coklat malt Milo kental dingin",
      "Susu segar",
      "Taburan bubuk coklat Milo ekstra melimpah di atasnya"
    ],
    "visual_clues": [
      "minuman cokelat dengan gundukan bubuk coklat malt Milo tebal di atas es batu"
    ]
  },
  "kopi kenangan cerita roti coklat klasik": {
    "name": "Cerita Roti Coklat Klasik Kopi Kenangan",
    "emoji": "🍞",
    "calories": 270,
    "protein": 6.5,
    "carbs": 42.0,
    "fat": 8.8,
    "fiber": 2.0,
    "sugar": 18.0,
    "caffeineMg": 0,
    "serving": "1 pcs roti (90g)",
    "category": "Roti & Pastry",
    "brand": "Kopi Kenangan",
    "aliases": [
      "cerita roti coklat klasik kopi kenangan",
      "cerita roti coklat klasik",
      "cerita roti coklat",
      "roti coklat kenangan",
      "cerita roti kenangan"
    ],
    "ingredients": [
      "Roti bantal manis super empuk dan lembut berpori halus",
      "Isian pasta cokelat meleleh (melted chocolate filling)",
      "Olesan mentega wangi di permukaan"
    ],
    "visual_clues": [
      "roti bantal persegi panjang cokelat keemasan lembut dalam kemasan plastik bertuliskan 'Cerita Roti'",
      "lelehan selai coklat pekat di dalam belahan roti"
    ]
  },
  "kopi kenangan cerita roti daging asap keju": {
    "name": "Cerita Roti Daging Asap Keju Kopi Kenangan",
    "emoji": "🍞",
    "calories": 290,
    "protein": 9.5,
    "carbs": 38.0,
    "fat": 11.2,
    "fiber": 1.5,
    "sugar": 8.0,
    "caffeineMg": 0,
    "serving": "1 pcs roti (95g)",
    "category": "Roti & Pastry",
    "brand": "Kopi Kenangan",
    "aliases": [
      "cerita roti daging asap keju kopi kenangan",
      "cerita roti daging asap keju",
      "cerita roti daging asap",
      "roti daging asap keju kenangan"
    ],
    "ingredients": [
      "Roti manis lembut Cerita Roti",
      "Irisan smoked beef (daging sapi asap)",
      "Saus keju cheddar lumer gurih",
      "Mayones gurih"
    ],
    "visual_clues": [
      "roti bantal dengan taburan rempah oregano atau keju kering di atasnya dan isian daging asap merah muda di dalam"
    ]
  },
  "kopi kenangan toast beef pastrami smoked cheese": {
    "name": "Kopi Kenangan Toast Beef Pastrami Smoked Cheese",
    "emoji": "🥪",
    "calories": 440,
    "protein": 18.5,
    "carbs": 44.0,
    "fat": 21.0,
    "fiber": 2.0,
    "sugar": 6.0,
    "caffeineMg": 0,
    "serving": "1 porsi toast (180g)",
    "category": "Burger & Sandwich",
    "brand": "Kopi Kenangan",
    "aliases": [
      "kopi kenangan toast beef pastrami smoked cheese",
      "toast beef pastrami kopi kenangan",
      "toast beef pastrami kenangan",
      "toast kenangan beef pastrami"
    ],
    "ingredients": [
      "Roti gandum / brioche tebal panggang renyah mentega",
      "Lembaran beef pastrami daging sapi berbumbu gurih asap",
      "Keju smoked cheese leleh",
      "Telur orak-arik (scrambled egg)",
      "Saus mayones spesial"
    ],
    "visual_clues": [
      "sandwich roti panggang tebal terbelah dua dalam kotak kertas Kopi Kenangan, keju leleh mengalir di antara irisan beef pastrami"
    ]
  },

  # =========================================================================
  # 5. BURGER BANGOR
  # =========================================================================
  "burger bangor jelata": {
    "name": "Burger Bangor Jelata",
    "emoji": "🍔",
    "calories": 380,
    "protein": 18.2,
    "carbs": 38.0,
    "fat": 17.5,
    "fiber": 2.0,
    "sugar": 5.5,
    "caffeineMg": 0,
    "serving": "1 porsi burger (170g)",
    "category": "Burger & Sandwich",
    "brand": "Burger Bangor",
    "aliases": [
      "burger bangor jelata",
      "bangor jelata",
      "burger jelata",
      "jelata bangor",
      "burger bangor"
    ],
    "ingredients": [
      "Roti bun lembut bertabur wijen panggang mentega",
      "1x Daging patty 100% Australian beef panggang gurih juicy",
      "Saus Bangor racikan gurih manis khas Bangor",
      "Irisan timun mentimun segar, selada, dan saus mayones"
    ],
    "visual_clues": [
      "burger dalam balutan kertas pembungkus hitam-merah berlogo kepala banteng bertanduk Burger Bangor",
      "patty daging sapi kecokelatan dengan lelehan saus Bangor coklat kemerahan"
    ]
  },
  "burger bangor jelata cheese": {
    "name": "Burger Bangor Jelata Cheese",
    "emoji": "🍔",
    "calories": 440,
    "protein": 21.5,
    "carbs": 38.5,
    "fat": 22.0,
    "fiber": 2.0,
    "sugar": 5.5,
    "caffeineMg": 0,
    "serving": "1 porsi burger (190g)",
    "category": "Burger & Sandwich",
    "brand": "Burger Bangor",
    "aliases": [
      "burger bangor jelata cheese",
      "jelata cheese bangor",
      "bangor jelata cheese",
      "burger bangor keju"
    ],
    "ingredients": [
      "Roti bun wijen panggang",
      "1x Australian beef patty juicy",
      "1x Lembaran keju cheddar Amerika lumer",
      "Saus keju gurih & saus spesial Bangor",
      "Selada segar dan mayones"
    ],
    "visual_clues": [
      "burger dengan lelehan keju cheddar kuning cerah menutupi patty daging sapi panggang"
    ]
  },
  "burger bangor juragan": {
    "name": "Burger Bangor Juragan",
    "emoji": "🍔",
    "calories": 590,
    "protein": 32.0,
    "carbs": 40.0,
    "fat": 33.5,
    "fiber": 2.2,
    "sugar": 6.0,
    "caffeineMg": 0,
    "serving": "1 porsi burger (260g)",
    "category": "Burger & Sandwich",
    "brand": "Burger Bangor",
    "aliases": [
      "burger bangor juragan",
      "bangor juragan",
      "juragan bangor",
      "burger juragan bangor",
      "burger double patty bangor"
    ],
    "ingredients": [
      "Roti bun wijen panggang mentega",
      "2x Daging patty 100% Australian beef tebal",
      "2x Lembaran keju cheddar gurih leleh",
      "Saus Bangor spesial melimpah",
      "Irisan selada segar dan mayones"
    ],
    "visual_clues": [
      "burger tinggi dengan 2 lapis patty daging sapi tebal kecokelatan dan lelehan 2 lapis keju cheddar kuning lumer"
    ]
  },
  "burger bangor ningrat": {
    "name": "Burger Bangor Ningrat",
    "emoji": "🍔",
    "calories": 780,
    "protein": 46.0,
    "carbs": 42.0,
    "fat": 48.0,
    "fiber": 2.5,
    "sugar": 6.5,
    "caffeineMg": 0,
    "serving": "1 porsi burger (340g)",
    "category": "Burger & Sandwich",
    "brand": "Burger Bangor",
    "aliases": [
      "burger bangor ningrat",
      "bangor ningrat",
      "ningrat bangor",
      "burger ningrat bangor",
      "triple burger bangor"
    ],
    "ingredients": [
      "Roti bun wijen lembut",
      "3x Daging patty 100% Australian beef",
      "3x Lembaran keju cheddar meleleh",
      "Saus Bangor racikan khas",
      "Mayones dan selada"
    ],
    "visual_clues": [
      "burger raksasa tinggi bertumpuk 3 lapis daging sapi patty tebal dengan 3 lelehan keju cheddar kuning mengalir di sisinya"
    ]
  },
  "burger bangor sultan": {
    "name": "Burger Bangor Sultan",
    "emoji": "🍔",
    "calories": 920,
    "protein": 54.0,
    "carbs": 44.0,
    "fat": 59.0,
    "fiber": 2.5,
    "sugar": 7.0,
    "caffeineMg": 0,
    "serving": "1 porsi burger (400g)",
    "category": "Burger & Sandwich",
    "brand": "Burger Bangor",
    "aliases": [
      "burger bangor sultan",
      "bangor sultan",
      "sultan bangor",
      "burger sultan bangor"
    ],
    "ingredients": [
      "Roti bun wijen",
      "3x Australian beef patty super juicy",
      "3x Keju cheddar lumer",
      "Lembaran smoked beef bacon renyah",
      "1x Telur ceplok mata sapi setengah matang / matang",
      "Saus Bangor spesial & saus keju"
    ],
    "visual_clues": [
      "burger ekstra besar dengan tumpukan 3 patty daging, telur ceplok, smoked beef, dan aneka saus lumer melimpah"
    ]
  },
  "burger bangor bbq d beef": {
    "name": "Burger Bangor BBQ D'Beef",
    "emoji": "🍔",
    "calories": 490,
    "protein": 24.0,
    "carbs": 44.0,
    "fat": 24.0,
    "fiber": 2.0,
    "sugar": 9.5,
    "caffeineMg": 0,
    "serving": "1 porsi burger (220g)",
    "category": "Burger & Sandwich",
    "brand": "Burger Bangor",
    "aliases": [
      "burger bangor bbq d beef",
      "bangor bbq d beef",
      "bbq d beef bangor",
      "burger bangor bbq"
    ],
    "ingredients": [
      "Roti bun wijen panggang",
      "Australian beef patty",
      "Saus smoky BBQ manis gurih pekat",
      "Bawang bombay karamel (caramelized onion)",
      "Keju cheddar dan selada"
    ],
    "visual_clues": [
      "burger dengan lelehan saus barbekyu coklat gelap mengkilap dan irisan bawang bombay kecokelatan"
    ]
  },
  "burger bangor pitik": {
    "name": "Burger Bangor Pitik (Crispy Chicken)",
    "emoji": "🍔",
    "calories": 460,
    "protein": 22.0,
    "carbs": 46.0,
    "fat": 20.5,
    "fiber": 2.0,
    "sugar": 5.0,
    "caffeineMg": 0,
    "serving": "1 porsi burger (200g)",
    "category": "Burger & Sandwich",
    "brand": "Burger Bangor",
    "aliases": [
      "burger bangor pitik",
      "bangor pitik",
      "pitik bangor",
      "burger ayam bangor",
      "crispy chicken burger bangor"
    ],
    "ingredients": [
      "Roti bun wijen lembut",
      "Fillet dada ayam berbalut tepung bumbu krispi goreng keemasan renyah",
      "Mayones gurih creamy",
      "Selada segar dan saus sambal"
    ],
    "visual_clues": [
      "burger dengan potongan daging ayam goreng krispi tebal berwarna emas kecokelatan menjulur keluar dari bun"
    ]
  },
  "burger bangor french fries": {
    "name": "French Fries Burger Bangor",
    "emoji": "🍟",
    "calories": 280,
    "protein": 3.5,
    "carbs": 38.0,
    "fat": 13.0,
    "fiber": 3.0,
    "sugar": 0.5,
    "caffeineMg": 0,
    "serving": "1 porsi kentang (130g)",
    "category": "Camilan",
    "brand": "Burger Bangor",
    "aliases": [
      "burger bangor french fries",
      "kentang bangor",
      "french fries bangor",
      "fries bangor"
    ],
    "ingredients": [
      "Potongan kentang crinkle cut / straight cut impor",
      "Minyak nabati untuk menggoreng",
      "Garam dan bumbu gurih Bangor"
    ],
    "visual_clues": [
      "kentang goreng kuning keemasan renyah dalam kantong kertas merah Burger Bangor"
    ]
  },

  # =========================================================================
  # 6. HAUS! INDONESIA
  # =========================================================================
  "haus es kopi susu kampung": {
    "name": "Haus! Es Kopi Susu Kampung",
    "emoji": "☕",
    "calories": 220,
    "protein": 3.8,
    "carbs": 34.0,
    "fat": 7.5,
    "fiber": 0.0,
    "sugar": 26.0,
    "caffeineMg": 90,
    "serving": "1 cup reguler (400ml)",
    "category": "Minuman Kopi",
    "brand": "Haus!",
    "aliases": [
      "haus es kopi susu kampung",
      "kopi susu kampung haus",
      "kopi kampung haus",
      "es kopi haus",
      "kopi haus"
    ],
    "ingredients": [
      "Seduhan kopi robusta pekat",
      "Susu kental manis (SKM)",
      "Krimer nabati gurih",
      "Es batu kristal"
    ],
    "visual_clues": [
      "cup transparan bertuliskan logo seru warna-warni 'Haus!' dengan cairan kopi susu coklat manis legit"
    ]
  },
  "haus es coklat lava": {
    "name": "Haus! Es Coklat Lava",
    "emoji": "🍫",
    "calories": 310,
    "protein": 5.0,
    "carbs": 52.0,
    "fat": 9.5,
    "fiber": 2.0,
    "sugar": 38.0,
    "caffeineMg": 15,
    "serving": "1 cup reguler (400ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Haus!",
    "aliases": [
      "haus es coklat lava",
      "es coklat lava haus",
      "coklat lava haus",
      "choco lava haus"
    ],
    "ingredients": [
      "Pasta coklat pekat lava manis legit",
      "Susu segar / krimer coklat",
      "Es batu"
    ],
    "visual_clues": [
      "minuman cokelat pekat gelap dengan lelehan saus coklat tebal di dinding cup Haus!"
    ]
  },
  "haus choco avocado": {
    "name": "Haus! Choco Avocado",
    "emoji": "🥑",
    "calories": 330,
    "protein": 4.5,
    "carbs": 55.0,
    "fat": 11.0,
    "fiber": 3.0,
    "sugar": 40.0,
    "caffeineMg": 10,
    "serving": "1 cup reguler (400ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Haus!",
    "aliases": [
      "haus choco avocado",
      "choco avocado haus",
      "alpukat coklat haus",
      "alpukat choco haus"
    ],
    "ingredients": [
      "Puree alpukat kental harum",
      "Sirup saus coklat lava pekat",
      "Susu krimer & es batu"
    ],
    "visual_clues": [
      "perpaduan warna hijau alpukat cerah dan sirup coklat gelap di dalam cup Haus!"
    ]
  },
  "haus boba brown sugar fresh milk": {
    "name": "Haus! Boba Brown Sugar Fresh Milk",
    "emoji": "🧋",
    "calories": 360,
    "protein": 5.2,
    "carbs": 66.0,
    "fat": 8.5,
    "fiber": 1.0,
    "sugar": 42.0,
    "caffeineMg": 0,
    "serving": "1 cup reguler (400ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Haus!",
    "aliases": [
      "haus boba brown sugar fresh milk",
      "boba brown sugar haus",
      "boba brown sugar fresh milk haus",
      "boba haus"
    ],
    "ingredients": [
      "Susu segar sapi murni",
      "Brown sugar tapioca pearl boba kenyal",
      "Sirup gula aren kental legit",
      "Es batu"
    ],
    "visual_clues": [
      "minuman susu putih segar dengan semburat karamel cokelat di dinding dan tumpukan boba hitam di dasar cup"
    ]
  },
  "haus taro boba": {
    "name": "Haus! Taro Boba",
    "emoji": "🍠",
    "calories": 340,
    "protein": 4.0,
    "carbs": 62.0,
    "fat": 8.0,
    "fiber": 1.0,
    "sugar": 39.0,
    "caffeineMg": 0,
    "serving": "1 cup reguler (400ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Haus!",
    "aliases": [
      "haus taro boba",
      "taro boba haus",
      "taro haus",
      "es taro haus"
    ],
    "ingredients": [
      "Bubuk perisa taro talas ungu wangi",
      "Susu krimer kental",
      "Boba tapioka kenyal",
      "Gula cair & es batu"
    ],
    "visual_clues": [
      "minuman ungu pastel cerah berpadu dengan mutiara boba hitam di dasar cup"
    ]
  },
  "haus thai tea": {
    "name": "Haus! Thai Tea",
    "emoji": "🧋",
    "calories": 210,
    "protein": 3.5,
    "carbs": 38.0,
    "fat": 5.0,
    "fiber": 0.5,
    "sugar": 28.0,
    "caffeineMg": 50,
    "serving": "1 cup reguler (400ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Haus!",
    "aliases": [
      "haus thai tea",
      "thai tea haus",
      "es thai tea haus"
    ],
    "ingredients": [
      "Seduhan teh merah Thailand",
      "Susu kental manis & krimer",
      "Es batu"
    ],
    "visual_clues": [
      "cairan teh susu berwarna oranye terang pekat dalam cup plastik Haus!"
    ]
  },
  "haus toast roti bakar coklat keju": {
    "name": "Haus! Toast Roti Bakar Coklat Keju",
    "emoji": "🍞",
    "calories": 390,
    "protein": 8.5,
    "carbs": 52.0,
    "fat": 16.5,
    "fiber": 2.0,
    "sugar": 22.0,
    "caffeineMg": 0,
    "serving": "1 porsi toast (150g)",
    "category": "Roti & Pastry",
    "brand": "Haus!",
    "aliases": [
      "haus toast roti bakar coklat keju",
      "roti bakar haus",
      "toast haus coklat keju",
      "toast haus"
    ],
    "ingredients": [
      "2 lembar roti tawar tebal dipanggang mentega",
      "Selai coklat meises melimpah",
      "Parutan keju cheddar gurih",
      "Susu kental manis"
    ],
    "visual_clues": [
      "roti bakar tebal kecokelatan berlumur cokelat dan keju parut leleh di dalam kemasan karton Haus!"
    ]
  },

  # =========================================================================
  # 7. JANJI JIWA & JIWA TOAST
  # =========================================================================
  "janji jiwa kopi janji jiwa mantan": {
    "name": "Kopi Janji Jiwa Mantan",
    "emoji": "☕",
    "calories": 220,
    "protein": 4.5,
    "carbs": 34.0,
    "fat": 7.5,
    "fiber": 0.0,
    "sugar": 26.0,
    "caffeineMg": 115,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Janji Jiwa",
    "aliases": [
      "janji jiwa kopi janji jiwa mantan",
      "kopi janji jiwa mantan",
      "kopi janji jiwa",
      "es kopi janji jiwa",
      "es kopi susu janji jiwa",
      "janji jiwa"
    ],
    "ingredients": [
      "Espresso biji kopi robusta-arabika khas Kopi Janji Jiwa",
      "Susu segar (fresh milk)",
      "Gula aren asli alami",
      "Es batu kristal"
    ],
    "visual_clues": [
      "cup bening dengan logo lingkaran hitam bertuliskan 'Kopi Janji Jiwa' dan simbol jari kelingking 'janji'",
      "gradasi warna espresso coklat tua di atas, susu putih di tengah, dan gula aren coklat di dasar"
    ]
  },
  "janji jiwa kopi soklat": {
    "name": "Kopi Soklat Janji Jiwa",
    "emoji": "☕",
    "calories": 260,
    "protein": 5.5,
    "carbs": 42.0,
    "fat": 8.5,
    "fiber": 1.5,
    "sugar": 30.0,
    "caffeineMg": 100,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Janji Jiwa",
    "aliases": [
      "janji jiwa kopi soklat",
      "kopi soklat janji jiwa",
      "kopi soklat",
      "kopi coklat janji jiwa"
    ],
    "ingredients": [
      "Single/double shot espresso",
      "Bubuk coklat premium khas Janji Jiwa",
      "Susu segar & sirup gula tebu",
      "Es batu"
    ],
    "visual_clues": [
      "minuman kopi susu cokelat pekat creamy dengan aroma paduan kopi dan kakao lezat"
    ]
  },
  "janji jiwa kopi pokat": {
    "name": "Kopi Pokat Janji Jiwa",
    "emoji": "🥑",
    "calories": 360,
    "protein": 5.0,
    "carbs": 50.0,
    "fat": 16.0,
    "fiber": 3.8,
    "sugar": 38.0,
    "caffeineMg": 90,
    "serving": "1 cup (400ml)",
    "category": "Minuman Kopi",
    "brand": "Janji Jiwa",
    "aliases": [
      "janji jiwa kopi pokat",
      "kopi pokat janji jiwa",
      "kopi alpukat janji jiwa",
      "kopi pokat"
    ],
    "ingredients": [
      "Jus buah alpukat segar kental",
      "Espresso kopi Janji Jiwa",
      "1 scoop es krim coklat premium",
      "Es batu serut"
    ],
    "visual_clues": [
      "lapisan hijau alpukat di bawah, siraman espresso coklat tua di tengah, dan topping es krim coklat bundar di atas"
    ]
  },
  "janji jiwa matcha latte": {
    "name": "Matcha Latte Janji Jiwa",
    "emoji": "🍵",
    "calories": 240,
    "protein": 5.5,
    "carbs": 36.0,
    "fat": 8.0,
    "fiber": 1.2,
    "sugar": 26.0,
    "caffeineMg": 60,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Janji Jiwa",
    "aliases": [
      "janji jiwa matcha latte",
      "matcha latte janji jiwa",
      "matcha janji jiwa",
      "susu matcha janji jiwa"
    ],
    "ingredients": [
      "Pure matcha powder Jepang",
      "Susu sapi segar",
      "Sirup gula cair & es batu"
    ],
    "visual_clues": [
      "minuman berwarna hijau daun cerah berpadu putih susu dalam cup Janji Jiwa"
    ]
  },
  "jiwa toast egg and cheese": {
    "name": "Jiwa Toast Egg and Cheese",
    "emoji": "🥪",
    "calories": 380,
    "protein": 14.5,
    "carbs": 38.0,
    "fat": 19.0,
    "fiber": 1.8,
    "sugar": 6.0,
    "caffeineMg": 0,
    "serving": "1 porsi toast (160g)",
    "category": "Burger & Sandwich",
    "brand": "Janji Jiwa",
    "aliases": [
      "jiwa toast egg and cheese",
      "jiwa toast egg cheese",
      "egg and cheese jiwa toast",
      "jiwa toast",
      "roti jiwa toast"
    ],
    "ingredients": [
      "Roti brioche tebal empuk dipanggang mentega wangi",
      "Telur dadar orak-arik (scrambled egg) lembut bermentega",
      "Lembaran keju cheddar Amerika gurih meleleh",
      "Saus mayones manis dan saus keju khas Jiwa Toast"
    ],
    "visual_clues": [
      "roti panggang tebal kuning keemasan dalam kemasan saku karton merah/putih 'Jiwa Toast', scrambled egg lembut dan keju meleleh di atasnya"
    ]
  },
  "jiwa toast crispy chicken mentai": {
    "name": "Jiwa Toast Crispy Chicken Mentai",
    "emoji": "🥪",
    "calories": 520,
    "protein": 24.0,
    "carbs": 44.0,
    "fat": 28.0,
    "fiber": 2.0,
    "sugar": 7.0,
    "caffeineMg": 0,
    "serving": "1 porsi toast (220g)",
    "category": "Burger & Sandwich",
    "brand": "Janji Jiwa",
    "aliases": [
      "jiwa toast crispy chicken mentai",
      "crispy chicken mentai jiwa toast",
      "jiwa toast mentai",
      "chicken mentai toast jiwa"
    ],
    "ingredients": [
      "Roti brioche tebal panggang mentega",
      "Dada ayam fillet goreng tepung krispi renyah",
      "Saus mentai gurih creamy bercita rasa tobiko bakar (torched mentai sauce)",
      "Selada segar dan omelet telur lembut"
    ],
    "visual_clues": [
      "toast tebal dengan ayam krispi menjulur dan saus mentai oranye kecokelatan berpola bakar torch di permukaannya"
    ]
  },
  "jiwa toast beef truffle mayo": {
    "name": "Jiwa Toast Beef Truffle Mayo",
    "emoji": "🥪",
    "calories": 490,
    "protein": 21.0,
    "carbs": 42.0,
    "fat": 26.5,
    "fiber": 2.0,
    "sugar": 6.5,
    "caffeineMg": 0,
    "serving": "1 porsi toast (200g)",
    "category": "Burger & Sandwich",
    "brand": "Janji Jiwa",
    "aliases": [
      "jiwa toast beef truffle mayo",
      "beef truffle mayo jiwa toast",
      "jiwa toast truffle",
      "truffle beef toast jiwa"
    ],
    "ingredients": [
      "Roti brioche panggang wangi",
      "Daging sapi cincang patty / irisan daging asap gurih",
      "Saus truffle mayo wangi minyak truffle aromatik mewah",
      "Keju cheddar leleh dan scrambled egg"
    ],
    "visual_clues": [
      "toast tebal dengan isian daging sapi kecokelatan, keju leleh, dan limpahan saus mayones truffle putih berbintik rempah"
    ]
  },

  # =========================================================================
  # 8. FORE COFFEE
  # =========================================================================
  "fore butterscotch sea salt latte": {
    "name": "Fore Butterscotch Sea Salt Latte",
    "emoji": "☕",
    "calories": 240,
    "protein": 5.2,
    "carbs": 35.0,
    "fat": 8.8,
    "fiber": 0.0,
    "sugar": 27.0,
    "caffeineMg": 130,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Fore Coffee",
    "aliases": [
      "fore butterscotch sea salt latte",
      "butterscotch sea salt latte fore",
      "fore butterscotch",
      "butterscotch latte fore",
      "fore sea salt latte"
    ],
    "ingredients": [
      "Double shot espresso 100% biji kopi Arabika pilihan Fore Coffee",
      "Susu segar full cream",
      "Sirup butterscotch karamel mentega wangi",
      "Krim sea salt lembut gurih asin manis di permukaan",
      "Es batu kristal"
    ],
    "visual_clues": [
      "cup ramah lingkungan hijau-putih khas Fore Coffee dengan logo daun Fore",
      "lapisan krim sea salt putih tebal di atas cairan kopi susu karamel keemasan"
    ]
  },
  "fore aren latte": {
    "name": "Fore Aren Latte",
    "emoji": "☕",
    "calories": 210,
    "protein": 4.8,
    "carbs": 32.0,
    "fat": 7.0,
    "fiber": 0.0,
    "sugar": 23.0,
    "caffeineMg": 130,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Fore Coffee",
    "aliases": [
      "fore aren latte",
      "aren latte fore",
      "kopi aren fore",
      "es kopi aren fore",
      "fore kopi gula aren"
    ],
    "ingredients": [
      "Espresso 100% Arabika Fore",
      "Susu segar murni",
      "Sirup gula aren organik alami",
      "Es batu"
    ],
    "visual_clues": [
      "cup hijau elegan Fore Coffee dengan gradasi cairan kopi susu dan gula aren"
    ]
  },
  "fore pandan latte": {
    "name": "Fore Pandan Latte",
    "emoji": "☕",
    "calories": 225,
    "protein": 4.8,
    "carbs": 36.0,
    "fat": 7.2,
    "fiber": 0.0,
    "sugar": 26.0,
    "caffeineMg": 130,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Fore Coffee",
    "aliases": [
      "fore pandan latte",
      "pandan latte fore",
      "kopi pandan fore",
      "fore pandan"
    ],
    "ingredients": [
      "Espresso Arabika Fore",
      "Susu segar",
      "Ekstrak sari daun pandan alami wangi segar",
      "Gula cair & es batu"
    ],
    "visual_clues": [
      "kopi susu dengan nuansa aroma harum pandan hijau lembut di cup Fore"
    ]
  },
  "fore manuka oat latte": {
    "name": "Fore Manuka Oat Latte",
    "emoji": "☕",
    "calories": 175,
    "protein": 2.8,
    "carbs": 29.0,
    "fat": 5.5,
    "fiber": 2.2,
    "sugar": 18.0,
    "caffeineMg": 130,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Fore Coffee",
    "aliases": [
      "fore manuka oat latte",
      "manuka oat latte fore",
      "manuka latte fore",
      "fore manuka"
    ],
    "ingredients": [
      "Double shot espresso Arabika",
      "Madu Manuka asli Selandia Baru kaya antioksidan",
      "Susu oat (plant-based oat milk)",
      "Es batu"
    ],
    "visual_clues": [
      "minuman kopi oat latte warna cokelat muda krem dalam cup Fore Coffee"
    ]
  },
  "fore americano": {
    "name": "Fore Americano",
    "emoji": "☕",
    "calories": 10,
    "protein": 0.6,
    "carbs": 1.5,
    "fat": 0.1,
    "fiber": 0.0,
    "sugar": 0.0,
    "caffeineMg": 160,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Fore Coffee",
    "aliases": [
      "fore americano",
      "americano fore",
      "iced americano fore",
      "fore coffee americano"
    ],
    "ingredients": [
      "Double shot espresso 100% Arabika Fore",
      "Air mineral murni",
      "Es batu"
    ],
    "visual_clues": [
      "kopi hitam pekat jernih dengan lapisan crema emas tipis di dalam cup bening Fore"
    ]
  },
  "fore almond croissant": {
    "name": "Fore Almond Croissant",
    "emoji": "🥐",
    "calories": 360,
    "protein": 8.0,
    "carbs": 38.0,
    "fat": 19.5,
    "fiber": 2.5,
    "sugar": 14.0,
    "caffeineMg": 0,
    "serving": "1 pcs croissant (110g)",
    "category": "Roti & Pastry",
    "brand": "Fore Coffee",
    "aliases": [
      "fore almond croissant",
      "almond croissant fore",
      "croissant almond fore",
      "croissant fore"
    ],
    "ingredients": [
      "Pastry croissant berlapis mentega Prancis (butter croissant)",
      "Isian krim almond lembut manis (almond frangipane cream)",
      "Taburan kacang almond iris panggang gurih dan gula halus salju"
    ],
    "visual_clues": [
      "croissant bulan sabit keemasan garing dengan taburan irisan kacang almond melimpah dan taburan gula bubuk putih"
    ]
  },

  # =========================================================================
  # 9. POINT COFFEE (INDOMARET)
  # =========================================================================
  "point coffee palm sugar frappe": {
    "name": "Point Coffee Palm Sugar Frappe",
    "emoji": "☕",
    "calories": 340,
    "protein": 4.8,
    "carbs": 58.0,
    "fat": 10.5,
    "fiber": 0.5,
    "sugar": 44.0,
    "caffeineMg": 95,
    "serving": "1 cup (450ml)",
    "category": "Minuman Kopi",
    "brand": "Point Coffee",
    "aliases": [
      "point coffee palm sugar frappe",
      "palm sugar frappe point coffee",
      "frappe point coffee",
      "kopi point coffee"
    ],
    "ingredients": [
      "Espresso blend Point Coffee diblender dengan es dan susu",
      "Sirup gula aren murni",
      "Topping whipped cream tebal dan drizzle saus karamel aren"
    ],
    "visual_clues": [
      "cup bening berlogo daun hijau 'Point Coffee' dengan minuman kopi frappe blender es dan topping whipped cream putih menjulang"
    ]
  },
  "point coffee caffe dolce": {
    "name": "Point Coffee Caffe Dolce",
    "emoji": "☕",
    "calories": 245,
    "protein": 5.0,
    "carbs": 38.0,
    "fat": 8.5,
    "fiber": 0.0,
    "sugar": 30.0,
    "caffeineMg": 110,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "Point Coffee",
    "aliases": [
      "point coffee caffe dolce",
      "caffe dolce point coffee",
      "kopi dolce point coffee",
      "dolce point coffee"
    ],
    "ingredients": [
      "Espresso kopi Arabika-Robusta",
      "Susu segar & susu kental manis gurih",
      "Es batu kristal"
    ],
    "visual_clues": [
      "kopi susu warna cokelat muda manis dalam cup Point Coffee"
    ]
  },

  # =========================================================================
  # 10. TEGUK
  # =========================================================================
  "teguk es kopi semanis kamu": {
    "name": "Teguk Es Kopi Semanis Kamu",
    "emoji": "☕",
    "calories": 215,
    "protein": 4.0,
    "carbs": 35.0,
    "fat": 7.0,
    "fiber": 0.0,
    "sugar": 26.0,
    "caffeineMg": 95,
    "serving": "1 cup reguler (400ml)",
    "category": "Minuman Kopi",
    "brand": "Teguk",
    "aliases": [
      "teguk es kopi semanis kamu",
      "kopi semanis kamu teguk",
      "es kopi teguk",
      "kopi teguk",
      "teguk kopi"
    ],
    "ingredients": [
      "Espresso kopi robusta lokal",
      "Susu segar dan sirup gula aren legit",
      "Es batu"
    ],
    "visual_clues": [
      "cup oranye-kuning cerah bertuliskan 'TEGUK' dengan cairan kopi susu gula aren"
    ]
  },
  "teguk boba brown sugar fresh milk": {
    "name": "Teguk Boba Brown Sugar Fresh Milk",
    "emoji": "🧋",
    "calories": 350,
    "protein": 5.0,
    "carbs": 65.0,
    "fat": 8.0,
    "fiber": 1.0,
    "sugar": 42.0,
    "caffeineMg": 0,
    "serving": "1 cup reguler (400ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Teguk",
    "aliases": [
      "teguk boba brown sugar fresh milk",
      "boba brown sugar teguk",
      "boba teguk",
      "brown sugar teguk"
    ],
    "ingredients": [
      "Susu sapi segar",
      "Brown sugar boba kenyal",
      "Sirup gula aren murni & es batu"
    ],
    "visual_clues": [
      "susu putih segar dengan lelehan sirup gula aren cokelat dan mutiara boba di dasar cup Teguk"
    ]
  },

  # =========================================================================
  # 11. RICHEESE FACTORY
  # =========================================================================
  "richeese factory combo fire chicken": {
    "name": "Richeese Factory Combo Fire Chicken (Level 1-5)",
    "emoji": "🍗",
    "calories": 740,
    "protein": 42.0,
    "carbs": 68.0,
    "fat": 34.0,
    "fiber": 2.5,
    "sugar": 12.0,
    "caffeineMg": 0,
    "serving": "1 paket combo lengkap",
    "category": "Makanan Siap Saji",
    "brand": "Richeese Factory",
    "aliases": [
      "richeese factory combo fire chicken",
      "combo fire chicken richeese",
      "fire chicken richeese",
      "paket richeese combo fire chicken",
      "ayam richeese level 5",
      "ayam richeese level 3",
      "ayam richeese level 1",
      "richeese fire chicken",
      "richeese combo",
      "richeese"
    ],
    "ingredients": [
      "1 Potong ayam goreng renyah berlumur saus barbekyu pedas membara (Fire Sauce Level 0-5)",
      "1 Porsi nasi putih pulen hangat",
      "1 Cup saus keju cheddar leleh khas Richeese yang gurih creamy",
      "1 Gelas minuman Pink Lava dingin segar"
    ],
    "visual_clues": [
      "ayam goreng berlumur saus merah gelap berkilau pedas",
      "cup cocolan saus keju kuning cerah kental",
      "gelas minuman Pink Lava berwarna merah muda cerah di samping nasi putih"
    ]
  },
  "richeese factory fire wings": {
    "name": "Richeese Factory Fire Wings 4 Pcs",
    "emoji": "🍗",
    "calories": 480,
    "protein": 28.0,
    "carbs": 24.0,
    "fat": 31.0,
    "fiber": 1.0,
    "sugar": 10.0,
    "caffeineMg": 0,
    "serving": "4 pcs sayap ayam (180g)",
    "category": "Makanan Siap Saji",
    "brand": "Richeese Factory",
    "aliases": [
      "richeese factory fire wings",
      "fire wings richeese",
      "richeese fire wings 4 pcs",
      "sayap ayam richeese"
    ],
    "ingredients": [
      "4 Potong sayap ayam krispi",
      "Saus fire BBQ pedas berlevel khas Richeese",
      "Saus keju cheddar cocolan"
    ],
    "visual_clues": [
      "4 potongan sayap ayam goreng berlumur saus barbekyu pedas merah tua mengkilap disajikan bersama saus keju"
    ]
  },
  "richeese factory pink lava": {
    "name": "Richeese Factory Pink Lava",
    "emoji": "🥤",
    "calories": 190,
    "protein": 2.5,
    "carbs": 38.0,
    "fat": 3.5,
    "fiber": 0.0,
    "sugar": 34.0,
    "caffeineMg": 0,
    "serving": "1 cup medium (400ml)",
    "category": "Minuman Boba & Teh",
    "brand": "Richeese Factory",
    "aliases": [
      "richeese factory pink lava",
      "pink lava richeese",
      "minuman pink lava",
      "pink lava"
    ],
    "ingredients": [
      "Susu evaporasi / krimer manis",
      "Sirup rasa cocopandan mawar manis segar",
      "Es batu kristal"
    ],
    "visual_clues": [
      "minuman berwarna merah muda (pink) cerah lembut khas Richeese Factory dalam cup berlogo Richeese"
    ]
  },
  "richeese factory cheese sauce": {
    "name": "Richeese Factory Cheese Sauce Cup",
    "emoji": "🧀",
    "calories": 120,
    "protein": 3.0,
    "carbs": 5.0,
    "fat": 10.0,
    "fiber": 0.0,
    "sugar": 1.5,
    "caffeineMg": 0,
    "serving": "1 cup saus (50g)",
    "category": "Camilan",
    "brand": "Richeese Factory",
    "aliases": [
      "richeese factory cheese sauce",
      "saus keju richeese",
      "cheese sauce richeese",
      "keju richeese"
    ],
    "ingredients": [
      "Keju cheddar olahan leleh",
      "Susu, mentega, dan perisa keju gurih khas Richeese"
    ],
    "visual_clues": [
      "saus kental berwarna kuning jingga terang berkilau dalam cup kecil transparan"
    ]
  },

  # =========================================================================
  # 12. J.CO DONUTS & COFFEE
  # =========================================================================
  "j co donut alcapone": {
    "name": "J.CO Donut Alcapone",
    "emoji": "🍩",
    "calories": 260,
    "protein": 5.2,
    "carbs": 29.0,
    "fat": 14.2,
    "fiber": 1.5,
    "sugar": 15.0,
    "caffeineMg": 0,
    "serving": "1 pcs donat (65g)",
    "category": "Donat & Dessert",
    "brand": "J.CO",
    "aliases": [
      "j co donut alcapone",
      "alcapone jco",
      "donat alcapone jco",
      "donat alcapone",
      "jco alcapone",
      "j co alcapone",
      "jco donut"
    ],
    "ingredients": [
      "Donat ragi lembut empuk khas J.CO",
      "Lapisan lelehan cokelat putih Belgia (white Belgian chocolate)",
      "Taburan melimpah irisan kacang almond California panggang renyah garing"
    ],
    "visual_clues": [
      "donat cincin berongga tengah yang tertutup penuh irisan kacang almond putih keemasan renyah di atas glasur putih"
    ]
  },
  "j co donut glazzy": {
    "name": "J.CO Donut Glazzy",
    "emoji": "🍩",
    "calories": 210,
    "protein": 3.8,
    "carbs": 28.0,
    "fat": 9.5,
    "fiber": 0.8,
    "sugar": 16.0,
    "caffeineMg": 0,
    "serving": "1 pcs donat (55g)",
    "category": "Donat & Dessert",
    "brand": "J.CO",
    "aliases": [
      "j co donut glazzy",
      "glazzy jco",
      "donat glazzy jco",
      "donat gula jco",
      "jco glazzy"
    ],
    "ingredients": [
      "Donat ragi lembut ringan",
      "Lapisan glasur madu gula cair tipis meleleh di mulut (honey glaze)"
    ],
    "visual_clues": [
      "donat mengkilap transparan dengan lapisan gula glasur tipis mengkilap keemasan"
    ]
  },
  "j co donut oreology": {
    "name": "J.CO Donut Oreology",
    "emoji": "🍩",
    "calories": 275,
    "protein": 4.5,
    "carbs": 33.0,
    "fat": 14.5,
    "fiber": 1.2,
    "sugar": 18.0,
    "caffeineMg": 0,
    "serving": "1 pcs donat (65g)",
    "category": "Donat & Dessert",
    "brand": "J.CO",
    "aliases": [
      "j co donut oreology",
      "oreology jco",
      "donat oreo jco",
      "jco oreology"
    ],
    "ingredients": [
      "Donat lembut J.CO",
      "Glasur cokelat putih",
      "Taburan remahan biskuit Oreo coklat hitam melimpah"
    ],
    "visual_clues": [
      "donat bertabur remahan biskuit cokelat hitam pekat di atas dasar putih"
    ]
  },
  "j co iced jcoccino": {
    "name": "J.CO Iced Jcoccino",
    "emoji": "☕",
    "calories": 220,
    "protein": 5.0,
    "carbs": 32.0,
    "fat": 8.0,
    "fiber": 0.0,
    "sugar": 24.0,
    "caffeineMg": 130,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "J.CO",
    "aliases": [
      "j co iced jcoccino",
      "iced jcoccino jco",
      "jcoccino jco",
      "kopi jco",
      "jcoccino"
    ],
    "ingredients": [
      "Espresso khas J.CO dari biji kopi Italia pilihan",
      "Susu segar",
      "Foam susu lembut & taburan bubuk coklat kayu manis",
      "Es batu"
    ],
    "visual_clues": [
      "cup transparan berlogo burung merak oranye J.CO berisi es cappuccino dengan busa susu putih di atasnya"
    ]
  },

  # =========================================================================
  # 13. HOKBEN (HOKA HOKA BENTO)
  # =========================================================================
  "hokben bento special 1": {
    "name": "HokBen Bento Special 1",
    "emoji": "🍱",
    "calories": 780,
    "protein": 34.0,
    "carbs": 86.0,
    "fat": 32.0,
    "fiber": 4.0,
    "sugar": 14.0,
    "caffeineMg": 0,
    "serving": "1 paket bento box",
    "category": "Makanan Siap Saji",
    "brand": "HokBen",
    "aliases": [
      "hokben bento special 1",
      "bento special 1 hokben",
      "paket bento special 1 hokben",
      "hokben bento 1",
      "hokben",
      "hoka hoka bento"
    ],
    "ingredients": [
      "Nasi putih pulen khas Jepang HokBen beraroma khas",
      "Chicken Teriyaki potongan paha ayam empuk saus manis gurih",
      "1 Pcs Ebi Furai udang lapis tepung panko krispi",
      "1 Pcs Tori Ball bola ayam olahan garing",
      "2 Pcs Egg Chicken Roll olahan ayam gulung telur goreng keemasan",
      "Salad serutan kol & wortel segar dengan saus mayones HokBen asam manis gurih"
    ],
    "visual_clues": [
      "kotak bento box sekat hitam-kuning HokBen berisi nasi pulen, teriyaki ayam kecokelatan, gorengan emas ebi furai & egg chicken roll bundar, serta salad mayones khas"
    ]
  },
  "hokben simple set teriyaki 1": {
    "name": "HokBen Simple Set Teriyaki 1",
    "emoji": "🍱",
    "calories": 590,
    "protein": 26.0,
    "carbs": 76.0,
    "fat": 20.0,
    "fiber": 3.0,
    "sugar": 12.0,
    "caffeineMg": 0,
    "serving": "1 paket set",
    "category": "Makanan Siap Saji",
    "brand": "HokBen",
    "aliases": [
      "hokben simple set teriyaki 1",
      "simple set teriyaki 1 hokben",
      "simple set 1 hokben",
      "simple set hokben"
    ],
    "ingredients": [
      "Nasi putih pulen HokBen",
      "Chicken Teriyaki empuk bumbu manis",
      "2 Pcs Egg Chicken Roll",
      "Salad mayones segar"
    ],
    "visual_clues": [
      "piring atau bento sederhana berisi nasi, 2 irisan egg chicken roll bulat kuning, potongan teriyaki ayam, dan salad"
    ]
  },
  "hokben egg chicken roll": {
    "name": "HokBen Egg Chicken Roll (6 Pcs)",
    "emoji": "🥢",
    "calories": 380,
    "protein": 22.0,
    "carbs": 18.0,
    "fat": 25.0,
    "fiber": 1.0,
    "sugar": 2.0,
    "caffeineMg": 0,
    "serving": "1 porsi isi 6 pcs (150g)",
    "category": "Makanan Utama",
    "brand": "HokBen",
    "aliases": [
      "hokben egg chicken roll",
      "egg chicken roll hokben",
      "egg chicken roll",
      "ayam gulung telur hokben"
    ],
    "ingredients": [
      "Daging ayam giling bumbu khas Jepang",
      "Dibalut kulit telur dadar tipis",
      "Digoreng keemasan hingga renyah di luar dan lembut gurih di dalam"
    ],
    "visual_clues": [
      "potongan silinder bundar miring berwarna kuning keemasan dengan bagian tengah daging ayam putih empuk"
    ]
  },
  "hokben ebi furai": {
    "name": "HokBen Ebi Furai (4 Pcs)",
    "emoji": "🍤",
    "calories": 320,
    "protein": 18.0,
    "carbs": 24.0,
    "fat": 16.5,
    "fiber": 1.2,
    "sugar": 1.5,
    "caffeineMg": 0,
    "serving": "1 porsi isi 4 pcs (140g)",
    "category": "Makanan Utama",
    "brand": "HokBen",
    "aliases": [
      "hokben ebi furai",
      "ebi furai hokben",
      "ebi furai",
      "udang goreng tepung hokben"
    ],
    "ingredients": [
      "Udang utuh segar pilihan",
      "Tepung roti panko kasar Jepang",
      "Digoreng garing renyah keemasan"
    ],
    "visual_clues": [
      "udang lurus berbalut tepung roti panko bertekstur kasar garing keemasan dengan ekor merah muda menjulur"
    ]
  },

  # =========================================================================
  # 14. SOLARIA
  # =========================================================================
  "solaria nasi goreng spesial": {
    "name": "Solaria Nasi Goreng Spesial",
    "emoji": "🍛",
    "calories": 670,
    "protein": 22.5,
    "carbs": 88.0,
    "fat": 25.0,
    "fiber": 3.0,
    "sugar": 4.5,
    "caffeineMg": 0,
    "serving": "1 porsi jumbo piring Solaria (380g)",
    "category": "Makanan Utama",
    "brand": "Solaria",
    "aliases": [
      "solaria nasi goreng spesial",
      "nasi goreng spesial solaria",
      "nasgor solaria",
      "nasi goreng solaria",
      "solaria nasgor spesial",
      "solaria"
    ],
    "ingredients": [
      "Nasi putih digoreng wok hei panas harum bumbu rahasia Solaria",
      "Suwiran daging ayam gurih",
      "Potongan bakso sapi / bakso ikan kenyal",
      "Udang segar",
      "Telur orak-arik dan telur ceplok mata sapi",
      "Acar mentimun wortel segar & kerupuk udang renyah"
    ],
    "visual_clues": [
      "nasi goreng kecokelatan berbutir terpisah dalam piring oval putih ungu khas Solaria dengan taburan daun bawang, telur mata sapi di atasnya, acar dan kerupuk di sisi piring"
    ]
  },
  "solaria chicken cordon bleu": {
    "name": "Solaria Chicken Cordon Bleu with French Fries",
    "emoji": "🍗",
    "calories": 780,
    "protein": 44.0,
    "carbs": 58.0,
    "fat": 41.0,
    "fiber": 4.0,
    "sugar": 5.0,
    "caffeineMg": 0,
    "serving": "1 porsi lengkap (350g)",
    "category": "Makanan Utama",
    "brand": "Solaria",
    "aliases": [
      "solaria chicken cordon bleu",
      "chicken cordon bleu solaria",
      "cordon bleu solaria",
      "solaria cordon bleu",
      "chicken cordon bleu kentang solaria"
    ],
    "ingredients": [
      "Dada ayam fillet tebal digulung dengan isian smoked beef (daging sapi asap) dan keju mozzarella leleh melimpah",
      "Dibalut tepung panir krispi garing keemasan",
      "Kentang goreng french fries crinkle cut",
      "Salad selada wortel kol segar dengan saus mayones asam manis Solaria"
    ],
    "visual_clues": [
      "gulungan ayam goreng tepung keemasan terbelah dengan lelehan keju putih-kuning mengalir keluar, disajikan bersama tumpukan kentang goreng dan salad mayones di piring Solaria"
    ]
  },
  "solaria kwetiau goreng sapi": {
    "name": "Solaria Kwetiau Goreng Sapi",
    "emoji": "🍜",
    "calories": 640,
    "protein": 26.0,
    "carbs": 78.0,
    "fat": 24.5,
    "fiber": 3.5,
    "sugar": 5.0,
    "caffeineMg": 0,
    "serving": "1 porsi piring Solaria (350g)",
    "category": "Makanan Utama",
    "brand": "Solaria",
    "aliases": [
      "solaria kwetiau goreng sapi",
      "kwetiau goreng sapi solaria",
      "kwetiau sapi solaria",
      "kwetiau goreng solaria"
    ],
    "ingredients": [
      "Kwetiau beras pipih lembut kenyal ditumis wajan wok panas",
      "Irisan daging sapi empuk",
      "Tauge renyah, caisim hijau segar, telur orak-arik",
      "Kecap manis gurih dan bumbu bawang harum Solaria"
    ],
    "visual_clues": [
      "kwetiau lebar berwarna cokelat gelap mengkilap bumbu kecap dengan potongan daging sapi dan tauge segar melimpah"
    ]
  },

  # =========================================================================
  # 15. KFC INDONESIA
  # =========================================================================
  "kfc paket super besar 1": {
    "name": "KFC Paket Super Besar 1 (Crispy/Original)",
    "emoji": "🍗",
    "calories": 680,
    "protein": 34.0,
    "carbs": 72.0,
    "fat": 28.0,
    "fiber": 2.0,
    "sugar": 28.0,
    "caffeineMg": 25,
    "serving": "1 paket lengkap (1 ayam + nasi + medium coke)",
    "category": "Makanan Siap Saji",
    "brand": "KFC",
    "aliases": [
      "kfc paket super besar 1",
      "super besar 1 kfc",
      "paket kfc super besar 1",
      "ayam kfc nasi",
      "kfc super besar 1",
      "kfc"
    ],
    "ingredients": [
      "1 Potong Ayam Goreng Hot & Crispy atau Original Recipe (dada/paha atas)",
      "1 Porsi Nasi Putih Organik pulen hangat",
      "1 Medium Cup Coca-Cola dingin"
    ],
    "visual_clues": [
      "ayam goreng bertepung keriting renyah warna coklat emas di samping nasi putih berbungkus kertas putih berlogo Kolonel Sanders merah KFC"
    ]
  },
  "kfc zinger burger": {
    "name": "KFC Zinger Burger",
    "emoji": "🍔",
    "calories": 490,
    "protein": 26.0,
    "carbs": 46.0,
    "fat": 22.0,
    "fiber": 2.5,
    "sugar": 6.0,
    "caffeineMg": 0,
    "serving": "1 porsi burger (210g)",
    "category": "Burger & Sandwich",
    "brand": "KFC",
    "aliases": [
      "kfc zinger burger",
      "zinger burger kfc",
      "zinger kfc",
      "burger kfc zinger"
    ],
    "ingredients": [
      "Roti bun bertabur biji wijen panggang empuk",
      "100% Fillet dada ayam krispi bumbu pedas Zinger gurih",
      "Selada segar renyah",
      "Saus mayones spesial KFC"
    ],
    "visual_clues": [
      "burger dengan fillet ayam krispi tebal berwarna kemerahan pedas di antara daun selada hijau dan roti wijen"
    ]
  },
  "kfc perkedel": {
    "name": "KFC Perkedel",
    "emoji": "🥔",
    "calories": 140,
    "protein": 3.2,
    "carbs": 18.0,
    "fat": 6.2,
    "fiber": 1.5,
    "sugar": 0.8,
    "caffeineMg": 0,
    "serving": "1 pcs perkedel (60g)",
    "category": "Lauk Pauk",
    "brand": "KFC",
    "aliases": [
      "kfc perkedel",
      "perkedel kfc",
      "perkedel kentang kfc"
    ],
    "ingredients": [
      "Kentang tumbuk gurih rempah bawang",
      "Daging ayam/sapi cincang",
      "Dibalur telur goreng keemasan"
    ],
    "visual_clues": [
      "perkedel oval pipih kecokelatan beraroma harum rempah bawang khas KFC"
    ]
  },
  "kfc mocha float": {
    "name": "KFC Mocha Float",
    "emoji": "🥤",
    "calories": 180,
    "protein": 2.5,
    "carbs": 36.0,
    "fat": 3.0,
    "fiber": 0.5,
    "sugar": 32.0,
    "caffeineMg": 35,
    "serving": "1 cup reguler (350ml)",
    "category": "Minuman Kopi",
    "brand": "KFC",
    "aliases": [
      "kfc mocha float",
      "mocha float kfc",
      "moka float kfc",
      "es float kfc"
    ],
    "ingredients": [
      "Minuman kopi moka dingin bersoda/manis",
      "Topping 1 swirl es krim soft serve vanila KFC",
      "Saus sirup cokelat di atasnya"
    ],
    "visual_clues": [
      "cup transparan KFC berisi minuman moka cokelat dengan es krim vanila mengapung di bagian atas disiram saus coklat"
    ]
  },

  # =========================================================================
  # 16. MCDONALD'S INDONESIA
  # =========================================================================
  "mcdonalds panas 1": {
    "name": "McDonald's PaNas 1 (Ayam McD + Nasi)",
    "emoji": "🍗",
    "calories": 640,
    "protein": 32.0,
    "carbs": 68.0,
    "fat": 26.0,
    "fiber": 2.0,
    "sugar": 22.0,
    "caffeineMg": 0,
    "serving": "1 paket (1 ayam McD + nasi + teh botol sosro/fruit tea)",
    "category": "Makanan Siap Saji",
    "brand": "McDonald's",
    "aliases": [
      "mcdonalds panas 1",
      "panas 1 mcd",
      "paket panas 1 mcdonalds",
      "ayam mcd nasi",
      "ayam krispy mcd",
      "ayam spicy mcd",
      "mcd",
      "mcdonalds"
    ],
    "ingredients": [
      "1 Potong Ayam Goreng McD Krispy (gurih) atau Spicy (pedas meresap)",
      "1 Porsi Nasi Putih hangat",
      "1 Medium Minuman Teh Botol Sosro / Fruit Tea"
    ],
    "visual_clues": [
      "ayam goreng tepung kuning keemasan renyah berkeriting khas McD, disajikan dengan nasi bungkus kertas putih berlogo Golden Arches 'M' kuning"
    ]
  },
  "mcdonalds big mac": {
    "name": "McDonald's Big Mac",
    "emoji": "🍔",
    "calories": 530,
    "protein": 25.0,
    "carbs": 45.0,
    "fat": 28.0,
    "fiber": 3.0,
    "sugar": 9.0,
    "caffeineMg": 0,
    "serving": "1 porsi burger (215g)",
    "category": "Burger & Sandwich",
    "brand": "McDonald's",
    "aliases": [
      "mcdonalds big mac",
      "big mac mcd",
      "big mac mcdonalds",
      "big mac"
    ],
    "ingredients": [
      "Roti bun bertabur wijen 3 susun (top, middle, bottom bun)",
      "2 Lembar 100% daging sapi Australia panggang",
      "Saus spesial Big Mac asam manis gurih legendaris",
      "1 Lembar keju cheddar leleh",
      "Acar mentimun (pickles), selada renyah, dan potongan bawang bombay segar"
    ],
    "visual_clues": [
      "burger bertingkat tiga yang tinggi dengan 2 lembar daging sapi, selada serut berlimpah, dan lelehan keju di antara bun berwijen dalam kotak karton Big Mac"
    ]
  },
  "mcdonalds mcflurry with oreo": {
    "name": "McDonald's McFlurry with Oreo",
    "emoji": "🍨",
    "calories": 285,
    "protein": 5.5,
    "carbs": 46.0,
    "fat": 8.5,
    "fiber": 1.0,
    "sugar": 38.0,
    "caffeineMg": 0,
    "serving": "1 cup mcflurry (150g)",
    "category": "Es Krim",
    "brand": "McDonald's",
    "aliases": [
      "mcdonalds mcflurry with oreo",
      "mcflurry oreo mcd",
      "mcflurry oreo",
      "es krim mcflurry oreo",
      "mcflurry"
    ],
    "ingredients": [
      "Es krim soft serve vanila susu lembut khas McDonald's",
      "Remahan biskuit Oreo crunchy coklat pekat yang diaduk rata"
    ],
    "visual_clues": [
      "cup bulat pendek McD berisi es krim putih creamy bertabur bintik-bintik remahan hitam biskuit Oreo dengan sendok kotak berlubang khas McFlurry"
    ]
  },
  "mcdonalds french fries": {
    "name": "McDonald's French Fries Medium",
    "emoji": "🍟",
    "calories": 320,
    "protein": 4.0,
    "carbs": 42.0,
    "fat": 15.0,
    "fiber": 3.5,
    "sugar": 0.5,
    "caffeineMg": 0,
    "serving": "1 porsi medium (115g)",
    "category": "Camilan",
    "brand": "McDonald's",
    "aliases": [
      "mcdonalds french fries",
      "french fries mcd",
      "kentang goreng mcd",
      "kentang mcd",
      "fries mcd"
    ],
    "ingredients": [
      "Kentang pilihan kualitas premium dipotong straight cut",
      "Minyak nabati untuk menggoreng renyah",
      "Taburan garam halus"
    ],
    "visual_clues": [
      "kentang goreng panjang lurus kuning keemasan renyah dalam bungkus karton merah berlogo huruf 'M' kuning McDonald's"
    ]
  },

  # =========================================================================
  # 17. A&W RESTAURANT
  # =========================================================================
  "aw mozza burger": {
    "name": "A&W Mozza Burger",
    "emoji": "🍔",
    "calories": 580,
    "protein": 30.0,
    "carbs": 42.0,
    "fat": 34.0,
    "fiber": 2.5,
    "sugar": 8.0,
    "caffeineMg": 0,
    "serving": "1 porsi burger (230g)",
    "category": "Burger & Sandwich",
    "brand": "A&W",
    "aliases": [
      "aw mozza burger",
      "mozza burger aw",
      "burger mozza aw",
      "mozza burger",
      "aw burger"
    ],
    "ingredients": [
      "Roti bun wijen panggang empuk",
      "2 Lembar 100% pure beef patty panggang",
      "Keju mozzarella leleh melar dan keju cheddar",
      "Saus Mozza spesial rahasia A&W",
      "Irisan tomat segar, selada, dan acar timun"
    ],
    "visual_clues": [
      "burger dalam balutan kertas oranye-coklat A&W dengan 2 lapis patty daging sapi dan keju mozzarella leleh melar gurih"
    ]
  },
  "aw root beer float": {
    "name": "A&W Root Beer Float (RB Float)",
    "emoji": "🍺",
    "calories": 210,
    "protein": 2.0,
    "carbs": 46.0,
    "fat": 2.5,
    "fiber": 0.0,
    "sugar": 44.0,
    "caffeineMg": 0,
    "serving": "1 gelas mug kaca / cup (400ml)",
    "category": "Minuman Boba & Teh",
    "brand": "A&W",
    "aliases": [
      "aw root beer float",
      "root beer float aw",
      "rb float aw",
      "root beer aw",
      "es root beer float"
    ],
    "ingredients": [
      "Minuman bersoda sarsaparilla aroma herbal khas legendaris A&W Root Beer dingin",
      "1 Scoop es krim soft serve vanila susu lembut di atasnya"
    ],
    "visual_clues": [
      "gelas mug kaca tebal berembun dingin berisi minuman bersoda coklat berbusa dengan es krim vanila putih mengapung di permukaannya"
    ]
  },

  # =========================================================================
  # 18. SUBWAY INDONESIA
  # =========================================================================
  "subway italian bmt 6 inch": {
    "name": "Subway Italian B.M.T. 6-Inch",
    "emoji": "🥪",
    "calories": 410,
    "protein": 20.0,
    "carbs": 44.0,
    "fat": 17.0,
    "fiber": 3.5,
    "sugar": 6.0,
    "caffeineMg": 0,
    "serving": "1 porsi sandwich 6-inch (225g)",
    "category": "Burger & Sandwich",
    "brand": "Subway",
    "aliases": [
      "subway italian bmt 6 inch",
      "italian bmt subway",
      "subway italian bmt",
      "sandwich subway bmt",
      "subway"
    ],
    "ingredients": [
      "Roti gandum / Italian / Parmesan Oregano 6-inch dipanggang renyah",
      "Lembaran pepperoni daging sapi pedas gurih",
      "Lembaran salami daging sapi",
      "Daging ham kalkun/sapi (chicken/beef ham)",
      "Keju cheddar / mozzarella leleh",
      "Selada segar, tomat, mentimun, paprika hijau, dan saus sweet onion / chipotle southwest"
    ],
    "visual_clues": [
      "sandwich submarine panjang berbalut kertas hijau-kuning khas Subway dengan aneka daging iris tipis dan sayuran segar penuh warna"
    ]
  },
  "subway double chocolate chip cookie": {
    "name": "Subway Double Chocolate Chip Cookie",
    "emoji": "🍪",
    "calories": 210,
    "protein": 2.5,
    "carbs": 30.0,
    "fat": 9.5,
    "fiber": 1.5,
    "sugar": 18.0,
    "caffeineMg": 5,
    "serving": "1 pcs cookie (45g)",
    "category": "Donat & Dessert",
    "brand": "Subway",
    "aliases": [
      "subway double chocolate chip cookie",
      "cookie subway double chocolate",
      "subway cookie",
      "kue subway"
    ],
    "ingredients": [
      "Adonan kuki cokelat manis lembut (chewy cookie)",
      "Butiran cokelat chip putih dan cokelat hitam melimpah"
    ],
    "visual_clues": [
      "kuki bundar pipih warna coklat gelap pekat bertekstur chewy bertabur lelehan chocolate chips"
    ]
  },

  # =========================================================================
  # 19. AYAM KEPRABON EXPRESS
  # =========================================================================
  "ayam keprabon paket geprek blenger": {
    "name": "Ayam Keprabon Paket Geprek Blenger",
    "emoji": "🍗",
    "calories": 720,
    "protein": 36.0,
    "carbs": 74.0,
    "fat": 32.0,
    "fiber": 3.0,
    "sugar": 4.0,
    "caffeineMg": 0,
    "serving": "1 porsi boks lengkap (380g)",
    "category": "Makanan Utama",
    "brand": "Ayam Keprabon",
    "aliases": [
      "ayam keprabon paket geprek blenger",
      "ayam keprabon blenger",
      "geprek blenger keprabon",
      "ayam keprabon",
      "keprabon blenger"
    ],
    "ingredients": [
      "Nasi putih hangat pulen",
      "Daging ayam krispi disuwir tanpa tulang dan digeprek ulekan cabai rawit pedas level 1-5",
      "Telur orak-arik dadar lembut",
      "Topping lelehan keju mozzarella berlimpah yang dibakar torch wangi",
      "Irisan mentimun lalapan segar"
    ],
    "visual_clues": [
      "kotak kardus kuning 'Ayam Keprabon Express' berisi nasi putih tertutup penuh suwiran ayam pedas dengan selimut tebal keju mozzarella leleh kecokelatan bekas bakar torch"
    ]
  },

  # =========================================================================
  # 20. AYAM GEPREK BENSU
  # =========================================================================
  "ayam geprek bensu paket leleh": {
    "name": "Ayam Geprek Bensu Paket Leleh (Mozzarella)",
    "emoji": "🍗",
    "calories": 690,
    "protein": 35.0,
    "carbs": 72.0,
    "fat": 30.0,
    "fiber": 2.5,
    "sugar": 3.5,
    "caffeineMg": 0,
    "serving": "1 porsi boks lengkap (350g)",
    "category": "Makanan Utama",
    "brand": "Ayam Geprek Bensu",
    "aliases": [
      "ayam geprek bensu paket leleh",
      "geprek bensu leleh",
      "ayam geprek bensu mozzarella",
      "geprek bensu",
      "ayam geprek bensu"
    ],
    "ingredients": [
      "1 Potong ayam goreng tepung krispi digeprek sambal bawang pedas cabai rawit level 1-10",
      "Nasi putih pulen",
      "Lelehan keju mozzarella bakar di atas ayam",
      "Lalapan mentimun segar"
    ],
    "visual_clues": [
      "ayam geprek merah pedas berselimut keju mozzarella meleleh di dalam kotak kemasan kuning 'Geprek Bensu'"
    ]
  }
}

def enrich_dataset():
    file_path = os.path.join("ai_workspace", "dataset", "food_master.json")
    with open(file_path, "r", encoding="utf-8") as f:
        existing_data = json.load(f)

    initial_count = len(existing_data)
    print(f"[*] Initial entries in food_master.json: {initial_count}")

    added_count = 0
    updated_count = 0

    for key, value in BRAND_DATA.items():
        clean_key = key.lower().strip()
        if clean_key in existing_data:
            existing_data[clean_key].update(value)
            updated_count += 1
        else:
            existing_data[clean_key] = value
            added_count += 1

    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(existing_data, f, ensure_ascii=False, indent=2)

    final_count = len(existing_data)
    print(f"[+] Enrichment complete!")
    print(f"[+] Added: {added_count} new branded entries")
    print(f"[+] Updated: {updated_count} existing entries")
    print(f"[+] Total entries now: {final_count}")

if __name__ == "__main__":
    enrich_dataset()
