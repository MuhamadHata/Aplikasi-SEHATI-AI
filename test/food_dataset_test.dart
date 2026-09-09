import 'package:flutter_test/flutter_test.dart';
import 'package:sehati_ai/inti/layanan/layanan_dataset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await DatasetService.instance.loadNutritionDataset();
  });

  group('Food Dataset & Smart Addon Tests', () {
    test('Mie Gacoan nutrition and ingredients verified', () async {
      final gacoan = await DatasetService.instance.findNutrition('mie gacoan');
      expect(gacoan, isNotNull);
      expect(gacoan!['name'], 'Mie Gacoan');
      expect(gacoan['calories'], 621);
      expect(gacoan['protein'], 20.5);
      expect(gacoan['ingredients'], isNotNull);

      final ingredients = List<String>.from(gacoan['ingredients']);
      final hasPangsit = ingredients.any((ing) => ing.toLowerCase().contains('2 pangsit'));
      expect(hasPangsit, true, reason: 'Mie Gacoan harus memiliki 2 pangsit dalam daftar bahan');
    });

    test('Aliases search works for Mie Gacoan variants', () async {
      final hompimpa = await DatasetService.instance.findNutrition('mie hompimpa');
      expect(hompimpa, isNotNull);

      final searchResults = await DatasetService.instance.search('gacoan');
      expect(searchResults.isNotEmpty, true);
      expect(searchResults.any((s) => s.toLowerCase().contains('gacoan')), true);
    });

    test('Smart Addon Parser: Mie Gacoan + Telur Ceplok', () async {
      final parsed = await DatasetService.instance.parseFoodWithAddons('Mie Gacoan + Telur Ceplok');
      expect(parsed.totalCalories, 713);
      expect(parsed.addons.length, 1);
      expect(parsed.addons.first.name.toLowerCase().contains('telur'), true);
      expect(parsed.combinedIngredients.any((ing) => ing.toLowerCase().contains('2 pangsit')), true);
      expect(parsed.combinedIngredients.any((ing) => ing.toLowerCase().contains('telur ceplok')), true);
    });

    test('Smart Addon Parser: Mie Gacoan + 2 Telur Ceplok + Kerupuk Putih', () async {
      final parsed = await DatasetService.instance.parseFoodWithAddons('Mie Gacoan + 2 Telur Ceplok + Kerupuk Putih');
      // 621 + (2 * 92) + 65 = 870
      expect(parsed.totalCalories, 870);
      expect(parsed.addons.length, 2);
      expect(parsed.combinedIngredients.any((ing) => ing.toLowerCase().contains('2x') || ing.toLowerCase().contains('2 ')), true);
    });

    test('Nasi Padang Rendang and Beverage verified', () async {
      final padang = await DatasetService.instance.findNutrition('nasi padang rendang');
      expect(padang, isNotNull);
      expect(padang!['calories'], 680);

      final esteh = await DatasetService.instance.findNutrition('es teh manis');
      expect(esteh, isNotNull);
      expect(esteh!['sugar'], greaterThanOrEqualTo(25));
    });

    test('Brand: Teazzi variants and nutrition verified', () async {
      final oolong = await DatasetService.instance.findNutrition('teazzi four seasons oolong milk tea');
      expect(oolong, isNotNull);
      expect(oolong!['calories'], 245);
      expect(oolong['caffeineMg'], 65);

      final search = await DatasetService.instance.search('teazzi');
      expect(search.length, greaterThanOrEqualTo(5));
      expect(search.any((s) => s.toLowerCase().contains('deep roasted')), true);
      expect(search.any((s) => s.toLowerCase().contains('lemon aiyu')), true);
    });

    test('Brand: Mixue variants and nutrition verified', () async {
      final sundae = await DatasetService.instance.findNutrition('mixue boba sundae');
      expect(sundae, isNotNull);
      expect(sundae!['calories'], 285);
      expect(sundae['ingredients'], isNotNull);

      final lemonade = await DatasetService.instance.findNutrition('mixue fresh squeezed lemonade');
      expect(lemonade, isNotNull);
      expect(lemonade!['calories'], 165);

      final search = await DatasetService.instance.search('mixue');
      expect(search.length, greaterThanOrEqualTo(8));
      expect(search.any((s) => s.toLowerCase().contains('sundae')), true);
    });

    test('Brand: Chatime variants and nutrition verified', () async {
      final milkTea = await DatasetService.instance.findNutrition('chatime milk tea');
      expect(milkTea, isNotNull);
      expect(milkTea!['calories'], 360);

      final search = await DatasetService.instance.search('chatime');
      expect(search.length, greaterThanOrEqualTo(5));
      expect(search.any((s) => s.toLowerCase().contains('roasted milk tea')), true);
    });

    test('Brand: Kopi Kenangan & Cerita Roti & Toast verified', () async {
      final mantan = await DatasetService.instance.findNutrition('kopi kenangan mantan');
      expect(mantan, isNotNull);
      expect(mantan!['calories'], 210);
      expect(mantan['caffeineMg'], 120);

      final roti = await DatasetService.instance.findNutrition('cerita roti coklat klasik');
      expect(roti, isNotNull);
      expect(roti!['calories'], 270);

      final search = await DatasetService.instance.search('kenangan');
      expect(search.length, greaterThanOrEqualTo(6));
    });

    test('Brand: Burger Bangor variants and nutrition verified', () async {
      final juragan = await DatasetService.instance.findNutrition('burger bangor juragan');
      expect(juragan, isNotNull);
      expect(juragan!['calories'], 590);
      expect(juragan['protein'], 32.0);

      final search = await DatasetService.instance.search('bangor');
      expect(search.length, greaterThanOrEqualTo(6));
      expect(search.any((s) => s.toLowerCase().contains('jelata')), true);
      expect(search.any((s) => s.toLowerCase().contains('sultan')), true);
    });

    test('Brand: Haus! variants and nutrition verified', () async {
      final kopiKampung = await DatasetService.instance.findNutrition('haus es kopi susu kampung');
      expect(kopiKampung, isNotNull);
      expect(kopiKampung!['calories'], 220);

      final search = await DatasetService.instance.search('haus');
      expect(search.length, greaterThanOrEqualTo(5));
      expect(search.any((s) => s.toLowerCase().contains('coklat lava')), true);
    });

    test('Brand: Janji Jiwa & Jiwa Toast verified', () async {
      final kopiJiwa = await DatasetService.instance.findNutrition('kopi janji jiwa mantan');
      expect(kopiJiwa, isNotNull);
      expect(kopiJiwa!['calories'], 220);

      final toastMentai = await DatasetService.instance.findNutrition('jiwa toast crispy chicken mentai');
      expect(toastMentai, isNotNull);
      expect(toastMentai!['calories'], 520);

      final search = await DatasetService.instance.search('jiwa');
      expect(search.length, greaterThanOrEqualTo(5));
    });

    test('Brand: Fore Coffee & Croissant verified', () async {
      final butterscotch = await DatasetService.instance.findNutrition('fore butterscotch sea salt latte');
      expect(butterscotch, isNotNull);
      expect(butterscotch!['calories'], 240);

      final croissant = await DatasetService.instance.findNutrition('fore almond croissant');
      expect(croissant, isNotNull);
      expect(croissant!['calories'], 360);

      final search = await DatasetService.instance.search('fore');
      expect(search.length, greaterThanOrEqualTo(5));
    });

    test('Other popular brands: Solaria, HokBen, Richeese, JCO, KFC, McD verified', () async {
      final solaria = await DatasetService.instance.findNutrition('solaria nasi goreng spesial');
      expect(solaria, isNotNull);
      expect(solaria!['calories'], 670);

      final hokben = await DatasetService.instance.findNutrition('hokben bento special 1');
      expect(hokben, isNotNull);
      expect(hokben!['calories'], 780);

      final richeese = await DatasetService.instance.findNutrition('richeese factory combo fire chicken');
      expect(richeese, isNotNull);
      expect(richeese!['calories'], 740);

      final jco = await DatasetService.instance.findNutrition('j co donut alcapone');
      expect(jco, isNotNull);
      expect(jco!['calories'], 260);

      final kfc = await DatasetService.instance.findNutrition('kfc paket super besar 1');
      expect(kfc, isNotNull);
      expect(kfc!['calories'], 680);

      final mcd = await DatasetService.instance.findNutrition('mcdonalds big mac');
      expect(mcd, isNotNull);
      expect(mcd!['calories'], 530);
    });
  });
}
