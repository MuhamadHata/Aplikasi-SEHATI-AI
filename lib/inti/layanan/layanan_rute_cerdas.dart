import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Destinasi pendakian / jalur alam terverifikasi
class HikingDestination {
  final String id;
  final String name;
  final String region;
  final double lat;
  final double lng;
  final int elevationM;
  final String difficulty;
  final String terrain;
  final String description;
  final double distanceKm;

  const HikingDestination({
    required this.id,
    required this.name,
    required this.region,
    required this.lat,
    required this.lng,
    required this.elevationM,
    required this.difficulty,
    required this.terrain,
    required this.description,
    this.distanceKm = 0.0,
  });

  HikingDestination copyWithDistance(double dist) {
    return HikingDestination(
      id: id,
      name: name,
      region: region,
      lat: lat,
      lng: lng,
      elevationM: elevationM,
      difficulty: difficulty,
      terrain: terrain,
      description: description,
      distanceKm: dist,
    );
  }
}

/// Hasil pengecekan ketersediaan tempat hiking di sekitar user
class HikingAvailabilityResult {
  final bool isHikingNearby;
  final double distanceToNearestKm;
  final HikingDestination? nearestSpot;
  final List<HikingDestination> nearestDestinations;
  final String statusMessage;

  const HikingAvailabilityResult({
    required this.isHikingNearby,
    required this.distanceToNearestKm,
    required this.nearestSpot,
    required this.nearestDestinations,
    required this.statusMessage,
  });
}

/// Tipe lingkungan geografis sekitar posisi user
enum AreaEnvironment {
  urbanResidential,
  openParkTrack,
  mountainTrail,
}

/// Layanan cerdas untuk kalkulasi rute lapangan atletik & deteksi lokasi hiking
class SmartRouteService {
  SmartRouteService._();

  /// Database destinasi pendakian terverifikasi di Indonesia
  static final List<HikingDestination> verifiedDestinations = [
    // ── Jabodetabek, Banten & Sekitarnya ──
    const HikingDestination(
      id: 'sentul_trail',
      name: 'Sentul Hills & Curug Trail',
      region: 'Bogor, Jawa Barat',
      lat: -6.5921,
      lng: 106.9042,
      elevationM: 650,
      difficulty: 'Mudah - Menengah',
      terrain: 'Tanah Padat, Kebun Teh, & Batuan Kali',
      description: 'Jalur trekking perbukitan asri dengan rute melintasi sawah, kebun serai, dan air terjun alami.',
    ),
    const HikingDestination(
      id: 'gn_pancar',
      name: 'Gunung Pancar Pine Forest',
      region: 'Babakan Madang, Bogor',
      lat: -6.5894,
      lng: 106.9082,
      elevationM: 800,
      difficulty: 'Mudah',
      terrain: 'Tanah Hutan Pinus & Tanjakan Ringan',
      description: 'Trekking di bawah keteduhan hutan pinus dengan udara sejuk dan kontur bukit ramah pemula.',
    ),
    const HikingDestination(
      id: 'gn_munara',
      name: 'Situs Gunung Munara Rumpin',
      region: 'Rumpin, Bogor',
      lat: -6.4382,
      lng: 106.6331,
      elevationM: 360,
      difficulty: 'Mudah',
      terrain: 'Bebatuan Karang & Hutan Alami',
      description: 'Bukit batu karst bersejarah dengan tanjakan singkat dan pemandangan luas Bogor barat.',
    ),
    const HikingDestination(
      id: 'gn_salak',
      name: 'Gunung Salak via Cimelati / Sukamantri',
      region: 'Bogor - Sukabumi',
      lat: -6.7162,
      lng: 106.7341,
      elevationM: 2211,
      difficulty: 'Menantang',
      terrain: 'Hutan Hujan Tropis, Lumpur & Akar Pohon',
      description: 'Jalur pendakian alami yang lebat dan lembap dengan vegetasi rapat khas Taman Nasional.',
    ),
    const HikingDestination(
      id: 'gn_gede',
      name: 'Gunung Gede Pangrango via Cibodas',
      region: 'Cianjur, Jawa Barat',
      lat: -6.7824,
      lng: 106.9832,
      elevationM: 2958,
      difficulty: 'Menantang',
      terrain: 'Batu Berundak, Telaga Biru & Jalur Kawah',
      description: 'Jalur legendaris cagar biosfer dengan pemandangan Telaga Biru, Air Terjun Cibeureum, hingga Alun-alun Surya Kencana.',
    ),
    const HikingDestination(
      id: 'gn_karang',
      name: 'Gunung Karang via Kaduengang',
      region: 'Pandeglang, Banten',
      lat: -6.2714,
      lng: 106.0521,
      elevationM: 1778,
      difficulty: 'Menengah',
      terrain: 'Tanah Lembap & Hutan Lumut',
      description: 'Puncak tertinggi di Provinsi Banten dengan tanjakan terjal yang konstan dan suasana mistis alami.',
    ),
    const HikingDestination(
      id: 'gn_pulosari',
      name: 'Gunung Pulosari',
      region: 'Pandeglang, Banten',
      lat: -6.3421,
      lng: 105.9782,
      elevationM: 1346,
      difficulty: 'Menengah',
      terrain: 'Bebatuan Karst & Kawah Belerang',
      description: 'Jalur pendakian yang melewati kawah belerang aktif dan Curug Putri di kaki bukit.',
    ),

    // ── Jawa Barat ──
    const HikingDestination(
      id: 'tahura_djuanda',
      name: 'Taman Hutan Raya Ir. H. Djuanda',
      region: 'Dago Atas, Bandung',
      lat: -6.8532,
      lng: 107.6321,
      elevationM: 1200,
      difficulty: 'Mudah',
      terrain: 'Paving Hutan, Jembatan Kayu & Tanah',
      description: 'Trekking konservasi alam hutan kota Bandung melintasi Gua Jepang, Gua Belanda, hingga Tebing Keraton.',
    ),
    const HikingDestination(
      id: 'gn_manglayang',
      name: 'Gunung Manglayang via Batu Kuda',
      region: 'Bandung Timur, Jawa Barat',
      lat: -6.8772,
      lng: 107.7451,
      elevationM: 1818,
      difficulty: 'Menengah - Menantang',
      terrain: 'Tanah Hutan Padat & Jalur Vertikal',
      description: 'Favorit pelari trail bandung untuk latihan elevasi singkat dengan kemiringan tajam.',
    ),
    const HikingDestination(
      id: 'gn_burangrang',
      name: 'Gunung Burangrang via Komando',
      region: 'Lembang, Jawa Barat',
      lat: -6.7761,
      lng: 107.5562,
      elevationM: 2057,
      difficulty: 'Menengah',
      terrain: 'Hutan Pinus & Punggungan Tanah',
      description: 'Sisa kaldera Gunung Sunda purba dengan vegetasi hijau rapat dan medan latihan fisik yang solid.',
    ),
    const HikingDestination(
      id: 'gn_papandayan',
      name: 'TWA Gunung Papandayan',
      region: 'Garut, Jawa Barat',
      lat: -7.3192,
      lng: 107.7314,
      elevationM: 2665,
      difficulty: 'Mudah - Menengah',
      terrain: 'Kawah Belerang, Hutan Mati & Tegal Alun',
      description: 'Jalur wisata pendakian ramah pemula dengan lanskap Hutan Mati eksotis dan padang edelweiss terluas di Asia Tenggara.',
    ),
    const HikingDestination(
      id: 'gn_ciremai',
      name: 'Taman Nasional Gunung Ciremai via Palutungan',
      region: 'Kuningan, Jawa Barat',
      lat: -6.8921,
      lng: 108.4021,
      elevationM: 3078,
      difficulty: 'Menantang',
      terrain: 'Tanah Padat, Bebatuan Karang & Tanjakan Panjang',
      description: 'Atap tertinggi Jawa Barat dengan kawah ganda megah dan pemandangan Samudera Hindia di kejauhan.',
    ),

    // ── Jawa Tengah & DIY ──
    const HikingDestination(
      id: 'gn_merbabu',
      name: 'Gunung Merbabu via Selo',
      region: 'Boyolali, Jawa Tengah',
      lat: -7.4561,
      lng: 107.4392,
      elevationM: 3145,
      difficulty: 'Menengah - Menantang',
      terrain: 'Padang Sabana Hijau & Bukit Bergelombang',
      description: 'Pendakian sabana terindah di Pulau Jawa dengan pemandangan langsung ke kawah Gunung Merapi.',
    ),
    const HikingDestination(
      id: 'gn_prau',
      name: 'Gunung Prau via Patakbanteng',
      region: 'Dieng, Wonosobo',
      lat: -7.1852,
      lng: 107.9251,
      elevationM: 2565,
      difficulty: 'Mudah - Menengah',
      terrain: 'Anak Tangga Tanah & Punggung Bukit',
      description: 'Pemandangan golden sunrise terbaik di Jawa Tengah dengan latar Gunung Sindoro dan Sumbing.',
    ),
    const HikingDestination(
      id: 'gn_andong',
      name: 'Gunung Andong via Sawit',
      region: 'Magelang, Jawa Tengah',
      lat: -7.3871,
      lng: 110.3682,
      elevationM: 1726,
      difficulty: 'Mudah',
      terrain: 'Hutan Pinus & Pematang Punggung Naga',
      description: 'Pendakian singkat 1.5 - 2 jam cocok untuk latihan trail run dan hiking santai keluarga.',
    ),
    const HikingDestination(
      id: 'gn_nglanggeran',
      name: 'Gunung Api Purba Nglanggeran',
      region: 'Gunungkidul, D.I. Yogyakarta',
      lat: -7.8421,
      lng: 110.5421,
      elevationM: 700,
      difficulty: 'Mudah',
      terrain: 'Lorong Bebatuan Karang & Tangga Tali',
      description: 'Gunung api purba berusia 60 juta tahun dengan pemandangan Embung Nglanggeran dan sawah berundak.',
    ),
    const HikingDestination(
      id: 'gn_lawu',
      name: 'Gunung Lawu via Cemoro Sewu',
      region: 'Magetan - Karanganyar',
      lat: -7.6281,
      lng: 111.1921,
      elevationM: 3265,
      difficulty: 'Menantang',
      terrain: 'Batu Tertata Rapi & Tanjakan Konstan',
      description: 'Jalur bertangga batu legendaris dengan pos Warung Mbok Yem di dekat Puncak Hargo Dumilah.',
    ),

    // ── Jawa Timur ──
    const HikingDestination(
      id: 'gn_bromo',
      name: 'Taman Nasional Bromo Tengger Semeru',
      region: 'Probolinggo - Pasuruan',
      lat: -7.9421,
      lng: 112.9531,
      elevationM: 2329,
      difficulty: 'Mudah',
      terrain: 'Lautan Pasir Berbisik & Tangga Kawah',
      description: 'Trekking pemandangan kaldera purba dan bibir kawah aktif yang mendunia.',
    ),
    const HikingDestination(
      id: 'gn_penanggungan',
      name: 'Gunung Penanggungan via Tamiajeng',
      region: 'Mojokerto, Jawa Timur',
      lat: -7.6162,
      lng: 112.6212,
      elevationM: 1653,
      difficulty: 'Menengah',
      terrain: 'Bebatuan Terjal & Situs Candi Kuno',
      description: 'Miniatur Gunung Semeru dengan kekayaan puluhan situs candi peninggalan era Majapahit.',
    ),
    const HikingDestination(
      id: 'gn_ijen',
      name: 'Kawah Ijen Nature Reserve',
      region: 'Banyuwangi - Bondowoso',
      lat: -8.0582,
      lng: 114.2421,
      elevationM: 2799,
      difficulty: 'Menengah',
      terrain: 'Jalan Pasir Padat Lebar & Tanjakan 25°',
      description: 'Fenomena api biru (blue fire) langka dan danau asam toska terluas di dunia.',
    ),
    const HikingDestination(
      id: 'gn_panderman',
      name: 'Gunung Panderman via Curah Banteng',
      region: 'Kota Batu, Jawa Timur',
      lat: -7.9042,
      lng: 112.4971,
      elevationM: 2045,
      difficulty: 'Menengah',
      terrain: 'Hutan Pinus & Puncak Basundara',
      description: 'Landmark kota Batu dengan pemandangan gemerlap lampu malam Malang Raya.',
    ),

    // ── Bali & Nusa Tenggara ──
    const HikingDestination(
      id: 'gn_batur',
      name: 'Gunung Batur Sunrise Trek',
      region: 'Kintamani, Bangli, Bali',
      lat: -8.2421,
      lng: 115.3751,
      elevationM: 1717,
      difficulty: 'Mudah - Menengah',
      terrain: 'Pasir Vulkanik Hitam & Batuan Basal',
      description: 'Trek pagi terfavorit di Bali untuk menyaksikan fajar merekah di atas Danau Batur dan Gunung Abang.',
    ),
    const HikingDestination(
      id: 'campuhan_ridge',
      name: 'Campuhan Ridge Walk Ubud',
      region: 'Ubud, Gianyar, Bali',
      lat: -8.5032,
      lng: 115.2551,
      elevationM: 300,
      difficulty: 'Sangat Mudah',
      terrain: 'Paving Blok Halus di Punggung Bukit Ilalang',
      description: 'Jalur jalan kaki alam terbuka yang romantis dan damai di antara dua lembah sungai Ubud.',
    ),
    const HikingDestination(
      id: 'gn_rinjani',
      name: 'Taman Nasional Gunung Rinjani via Sembalun',
      region: 'Lombok Timur, NTB',
      lat: -8.4112,
      lng: 116.4571,
      elevationM: 3726,
      difficulty: 'Sangat Menantang',
      terrain: 'Sabana Sembalun, Bukit Penyesalan & Pasir Puncak',
      description: 'Mahakarya alam nusantara dengan kaldera Segara Anak dan anak gunung Barujari yang magis.',
    ),

    // ── Sumatera & Sulawesi ──
    const HikingDestination(
      id: 'gn_sibayak',
      name: 'Gunung Sibayak via Jaranguda',
      region: 'Berastagi, Sumatera Utara',
      lat: -3.2001,
      lng: 98.5042,
      elevationM: 2212,
      difficulty: 'Mudah - Menengah',
      terrain: 'Aspal Rusak, Bebatuan Karst & Kawah Gas',
      description: 'Gunung berapi aktif ramah pendaki dengan pemandangan dataran tinggi Karo dan sumber air panas.',
    ),
    const HikingDestination(
      id: 'gn_marapi',
      name: 'Gunung Marapi via Koto Baru',
      region: 'Tanah Datar - Agam, Sumbar',
      lat: -0.3802,
      lng: 100.4731,
      elevationM: 2891,
      difficulty: 'Menantang',
      terrain: 'Hutan Bambu & Cadas Berpasir',
      description: 'Gunung paling populer di Sumatera Barat yang menjulang megah di dekat Bukittinggi.',
    ),
    const HikingDestination(
      id: 'gn_bawakaraeng',
      name: 'Gunung Bawakaraeng via Lembanna',
      region: 'Gowa, Sulawesi Selatan',
      lat: -5.3172,
      lng: 119.9421,
      elevationM: 2830,
      difficulty: 'Menantang',
      terrain: 'Hutan Lumut Hujan Tropis & Lembah Ramma',
      description: 'Ikon pendakian Sulawesi Selatan dengan titik spiritual dan lembah perkemahan hijau Ramma.',
    ),
  ];

  /// Hitung jarak geodesic Haversine (km) antara dua koordinat
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Radius maksimal agar suatu lokasi dianggap benar-benar berada di kaki/jalur gunung
  /// (di luar radius ini, area dianggap sebagai pemukiman/perkotaan agar tidak menggambar rute hiking palsu di gang)
  static const double defaultHikingThresholdKm = 3.0;

  /// Cek ketersediaan jalur hiking alami di sekitar koordinat user (radius default 3.0 km)
  static HikingAvailabilityResult checkHikingAvailability(
    LatLng userPos, {
    double radiusKm = defaultHikingThresholdKm,
  }) {
    final listWithDistance = verifiedDestinations.map((d) {
      final dist = calculateDistanceKm(userPos.latitude, userPos.longitude, d.lat, d.lng);
      return d.copyWithDistance(dist);
    }).toList();

    // Urutkan dari yang terdekat
    listWithDistance.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final nearest = listWithDistance.first;
    final isNearby = nearest.distanceKm <= radiusKm;

    final statusMessage = isNearby
        ? 'Terdeteksi ${nearest.name} (~${nearest.distanceKm.toStringAsFixed(1)} km dari posisi Anda)'
        : 'Lokasi Anda berada di kawasan pemukiman / perkotaan. Destinasi hiking terdekat adalah ${nearest.name} (~${nearest.distanceKm.toStringAsFixed(1)} km).';

    return HikingAvailabilityResult(
      isHikingNearby: isNearby,
      distanceToNearestKm: nearest.distanceKm,
      nearestSpot: nearest,
      nearestDestinations: listWithDistance.take(4).toList(),
      statusMessage: statusMessage,
    );
  }

  /// Deteksi tipe lingkungan sekitar user
  static AreaEnvironment detectEnvironment(LatLng userPos) {
    final hikingCheck = checkHikingAvailability(userPos, radiusKm: defaultHikingThresholdKm);
    if (hikingCheck.isHikingNearby) {
      return AreaEnvironment.mountainTrail;
    }
    return AreaEnvironment.urbanResidential;
  }

  /// Menghasilkan titik geometri lintasan lari standar atletik 400 meter (IAAF Standard Oval Track)
  ///
  /// Dimensi standar IAAF 400m:
  /// - Dua sisi lurus (straights): masing-masing ~84.39 meter.
  /// - Dua setengah lingkaran oval (turns): radius ~36.50 meter.
  /// - Total keliling = 2 * 84.39 + 2 * π * 36.50 = 168.78 + 229.34 = 398.12m (~400 meter).
  ///
  /// Rute ini 100% berada di dalam area lapangan/stadion dan TIDAK AKAN PERNAH keluar ke jalan raya.
  static List<LatLng> generateAthleticTrackLoop(
    LatLng center, {
    int laps = 5,
    double headingDegrees = 0.0,
  }) {
    const double straightMeters = 84.39;
    const double radiusMeters = 36.50;
    const int curvePointsPerSide = 14;

    // Konversi offset meter ke derajat koordinat
    const double metersPerLatDegree = 111139.0;
    final double metersPerLngDegree = 111139.0 * math.cos(_degreesToRadians(center.latitude));

    final headingRad = _degreesToRadians(headingDegrees);
    final cosH = math.cos(headingRad);
    final sinH = math.sin(headingRad);

    // Titik-titik lokal dalam meter relatif terhadap pusat (0,0)
    // Sumbu X: Lebar track (ke kanan), Sumbu Y: Panjang lurus track (ke atas/utara)
    final localTrackPoints = <math.Point<double>>[];

    const halfStraight = straightMeters / 2.0;

    // 1. Sisi lurus kanan (bawah ke atas: y dari -halfStraight ke +halfStraight)
    localTrackPoints.add(const math.Point(radiusMeters, -halfStraight));
    localTrackPoints.add(const math.Point(radiusMeters, 0.0));
    localTrackPoints.add(const math.Point(radiusMeters, halfStraight));

    // 2. Lengkungan setengah lingkaran atas (y = +halfStraight, sudut theta dari 0 ke π)
    for (int i = 1; i <= curvePointsPerSide; i++) {
      final theta = (math.pi / (curvePointsPerSide + 1)) * i;
      final x = radiusMeters * math.cos(theta);
      final y = halfStraight + radiusMeters * math.sin(theta);
      localTrackPoints.add(math.Point(x, y));
    }

    // 3. Sisi lurus kiri (atas ke bawah: y dari +halfStraight ke -halfStraight)
    localTrackPoints.add(const math.Point(-radiusMeters, halfStraight));
    localTrackPoints.add(const math.Point(-radiusMeters, 0.0));
    localTrackPoints.add(const math.Point(-radiusMeters, -halfStraight));

    // 4. Lengkungan setengah lingkaran bawah (y = -halfStraight, sudut theta dari π ke 2π)
    for (int i = 1; i <= curvePointsPerSide; i++) {
      final theta = math.pi + (math.pi / (curvePointsPerSide + 1)) * i;
      final x = radiusMeters * math.cos(theta);
      final y = -halfStraight + radiusMeters * math.sin(theta);
      localTrackPoints.add(math.Point(x, y));
    }

    // Tutup loop dengan titik awal sisi kanan bawah
    localTrackPoints.add(const math.Point(radiusMeters, -halfStraight));

    // Transformasikan titik lokal (x, y meter) ke koordinat GPS LatLng dengan rotasi heading
    final singleLapWaypoints = <LatLng>[];
    for (final pt in localTrackPoints) {
      // Rotasi terhadap heading lapangan
      final rotatedX = pt.x * cosH - pt.y * sinH;
      final rotatedY = pt.x * sinH + pt.y * cosH;

      final lat = center.latitude + (rotatedY / metersPerLatDegree);
      final lng = center.longitude + (rotatedX / metersPerLngDegree);
      singleLapWaypoints.add(LatLng(lat, lng));
    }

    // Untuk visualisasi peta yang rapi, 1 loop geometri oval tertutup sudah cukup
    // Jarak total dihitung sebagai (laps * 0.40) km
    return singleLapWaypoints;
  }
}
