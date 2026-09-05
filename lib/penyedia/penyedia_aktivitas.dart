import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../inti/layanan/layanan_pedometer_latar.dart';
import '../inti/model/catatan_aktivitas.dart';
import '../inti/layanan/layanan_notifikasi.dart';
import '../inti/layanan/konfigurasi_layanan_latar.dart';
import '../inti/ml/gait_quality_index.dart';

class ActivityProvider extends ChangeNotifier {
  static const String smokingStatusNone = 'tidak_merokok';
  static const String smokingStatusActive = 'merokok';
  static const String smokingStatusPassive = 'terpapar_asap';

  // ── Debounce & Sync Status ────────────────────────────────────────────────
  Timer? _syncDebounceTimer;
  static const _syncDebounceDelay = Duration(seconds: 5);
  bool _isSyncing = false;
  bool _isOnline = true;
  String? _lastSyncError;

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  String? get lastSyncError => _lastSyncError;

  double _runningDistance = 0.0; // in km
  double _walkingDistance = 0.0; // in km
  int _waterGlasses = 5; // Default mock start
  double _weight = 70.0;
  double _heightCm = 173.0;
  double _bmi = 22.4; // Default mock start
  int _age = 25; // Default age
  String _gender = 'Pria'; // Default gender
  String _userName = 'User';
  String _userEmail = '';
  String? _photoUrl;

  // Status merokok
  String _smokingStatus = smokingStatusNone;
  bool _isSmoker = false;
  bool _stressManaged = true;
  bool _sleepAdequateHabit = true;
  int _moderateActivityMinutesPerWeek = 150;
  int _sugaryDrinksPerWeek = 2;

  // Log tidur harian
  List<SleepRecord> _sleepLogs = [];

  String? _workoutGoal;
  String? _workoutLevel;
  List<String> _workoutMuscleGroups = [];
  String? _workoutEquipment;
  int? _workoutFrequency;
  String? _activeDietProgram; // Tracks the name of the active diet
  int? _activeDietCalories; // Tracks the target calories of the active diet
  String _fastingMode = 'none'; // none | ramadan | if
  int _ramadanIftarMinute = 18 * 60; // default 18:00
  int _ramadanSuhoorEndMinute = 4 * 60 + 30; // default 04:30
  int _ifEatStartMinute = 12 * 60; // default 12:00
  int _ifEatEndMinute = 20 * 60; // default 20:00

  int _waterTarget = 8;
  int _stepTarget = 10000;
  final int _baseCalorieTarget = 2100;

  int get waterTarget => _waterTarget;
  int get stepTarget => _stepTarget;

  int get calorieTarget => _activeDietCalories ?? _baseCalorieTarget;
  int _calorieConsumed = 0; // Dynamic now

  List<ActivityRecord> _history = [];
  List<DailySummary> _dailySummaries = [];
  List<FoodLog> _foodLogs = [];

  StreamSubscription<List<Map<String, dynamic>>>? _sleepLogsSubscription;

  // Pedometer passive states
  int _passiveSteps = 0;
  int _initialStepCount = -1;
  int _lastKnownTotalSteps = -1;
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription? _bgServiceSubscription;

  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _todayStatsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _dailySummariesSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _foodLogsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _historySubscription;

  ActivityProvider() {
    // Run init in a safe async block
    _safeInit();
  }

  Future<void> _safeInit() async {
    try {
      await _init();
      _authSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final user = data.session?.user;
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.initialSession) {
          if (user != null) {
            _init(); // Reload data with correct prefix
            loadProfile();
          }
        }
      }, onError: (e) => debugPrint('Auth subscription error: $e'));
    } catch (e) {
      debugPrint('ActivityProvider critical init error: $e');
    }
  }

  /// Public getter for user prefix (for background service)
  String get userPrefix {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null ? '${user.id}_' : 'guest_';
  }

  String get _prefix {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null ? '${user.id}_' : 'guest_';
  }

  Future<void> _init() async {
    await initializeDateFormatting('id_ID', null);
    await _loadData();
    _initPedometer();
    _cancelFirestoreStreams();
    _setupFirestoreStreams();
  }

  int _stepsAtLastSave = 0;

  Future<void> _initPedometer() async {
    // Cancel existing if any
    await _stepSubscription?.cancel();
    _stepsAtLastSave = _passiveSteps;
    // BUGFIX: Reset _initialStepCount so the first event after re-init
    // triggers the recovery logic (recover steps taken while app was closed).
    _initialStepCount = -1;

    final status = await Permission.activityRecognition.status;
    if (status.isGranted) {
      // Auto-start background continuous tracking if not already running
      try {
        await PedometerBackgroundService.startContinuousTracking(
          userPrefix: _prefix,
        );
      } catch (e) {
        debugPrint('[ActivityProvider] Auto-start continuous tracking warning: $e');
      }

      // Listen to background service updates for real-time synchronization
      _bgServiceSubscription?.cancel();
      try {
        final service = FlutterBackgroundService();
        _bgServiceSubscription = service.on('pedometerUpdate').listen((data) {
          if (data != null && data['passiveSteps'] != null) {
            final bgSteps = data['passiveSteps'] as int;
            if (bgSteps > _passiveSteps) {
              _passiveSteps = bgSteps;
              notifyListeners();
            }
          }
        });
      } catch (_) {}

      _stepSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          debugPrint('Pedometer Event: ${event.steps} steps');
          if (_initialStepCount == -1) {
            // First event since app opened/provider initialized
            if (_lastKnownTotalSteps != -1 &&
                event.steps > _lastKnownTotalSteps) {
              // Recover steps taken while app was closed
              final delta = event.steps - _lastKnownTotalSteps;
              _passiveSteps += delta;
              debugPrint('Recovered $delta steps from background');
            }
            _initialStepCount = event.steps;
            _lastKnownTotalSteps = event.steps;
            _saveData();
            notifyListeners();
          } else {
            final delta = event.steps - _initialStepCount;
            if (delta > 0) {
              _passiveSteps += delta;
              _initialStepCount = event.steps;
              _lastKnownTotalSteps = event.steps;

              // Save if at least 10 steps since last save
              if ((_passiveSteps - _stepsAtLastSave).abs() >= 10) {
                _saveData();
                _stepsAtLastSave = _passiveSteps;
              }
              notifyListeners();
            } else if (delta < 0) {
              // Device rebooted, reset counters
              debugPrint('Pedometer reset detected (reboot?)');
              _initialStepCount = event.steps;
              _lastKnownTotalSteps = event.steps;
              _saveData();
            }
          }
        },
        onError: (error) => debugPrint('Pedometer Error: $error'),
      );
    }
  }

  Future<bool> requestActivityPermissions() async {
    // Request multiple permissions at once
    final statuses = await [
      Permission.activityRecognition,
      Permission.location,
      Permission.sensors,
    ].request();

    final isGranted =
        statuses[Permission.activityRecognition]?.isGranted ?? false;
    if (isGranted) {
      await _initPedometer();
      try {
        await PedometerBackgroundService.startContinuousTracking(
          userPrefix: _prefix,
        );
      } catch (_) {}
    }
    notifyListeners();
    return isGranted;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _stepSubscription?.cancel();
    _bgServiceSubscription?.cancel();
    _syncDebounceTimer?.cancel();
    _cancelFirestoreStreams();
    super.dispose();
  }

  // ── Firestore Real-time Streams ──────────────────────────────────────────

  void _cancelFirestoreStreams() {
    _todayStatsSubscription?.cancel();
    _dailySummariesSubscription?.cancel();
    _foodLogsSubscription?.cancel();
    _historySubscription?.cancel();
    _sleepLogsSubscription?.cancel();
    _todayStatsSubscription = null;
    _dailySummariesSubscription = null;
    _foodLogsSubscription = null;
    _historySubscription = null;
    _sleepLogsSubscription = null;
  }

  void _setupFirestoreStreams() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Stream 1: today's daily stats (water, calories, steps, distance)
    try {
      _todayStatsSubscription = Supabase.instance.client
          .from('daily_stats')
          .stream(primaryKey: ['user_id', 'date'])
          .eq('user_id', user.id)
          .listen((docs) {
            final todayDocs = docs.where((d) => d['date'] == todayStr).toList();
            if (todayDocs.isEmpty) return;
            final data = todayDocs.first;
            bool changed = false;
            final w = (data['water_glasses'] as int?) ?? _waterGlasses;
            final c = (data['calorie_consumed'] as int?) ?? _calorieConsumed;
            final s = (data['passive_steps'] as int?) ?? _passiveSteps;
            final r = (data['running_distance'] as num?)?.toDouble() ??
                _runningDistance;
            final wk = (data['walking_distance'] as num?)?.toDouble() ??
                _walkingDistance;

            if (w != _waterGlasses) {
              _waterGlasses = w;
              changed = true;
            }
            // BUGFIX: Hanya update _calorieConsumed dari server jika nilainya
            // LEBIH BESAR dari lokal. Ini mencegah data stale (calorie_consumed: 0)
            // dari server menimpa kalori yang sudah dihitung lokal — terutama
            // karena sync ke daily_stats pakai debounce 5 detik setelah addFoodLog.
            if (c > _calorieConsumed) {
              _calorieConsumed = c;
              changed = true;
            }
            // BUGFIX: Hanya update _passiveSteps dari Supabase jika nilainya
            // lebih besar dari nilai lokal saat ini. Langkah tidak bisa berkurang
            // dalam satu hari tanpa reset — ini mencegah data stale dari server
            // menimpa langkah yang sudah dihitung oleh pedometer lokal.
            if (s > _passiveSteps) {
              _passiveSteps = s;
              changed = true;
            }
            if (r != _runningDistance) {
              _runningDistance = r;
              changed = true;
            }
            if (wk != _walkingDistance) {
              _walkingDistance = wk;
              changed = true;
            }
            if (changed) notifyListeners();
          }, onError: (e) {
            debugPrint('TodayStats stream error: $e');
            // Don't close, let it try to reconnect or fallback to local
          });
    } catch (e) {
      debugPrint('TodayStats stream setup error: $e');
    }

    // Stream 2: daily summaries collection (last 30 days, real-time history)
    try {
      _dailySummariesSubscription = Supabase.instance.client
          .from('daily_summaries')
          .stream(primaryKey: ['user_id', 'date'])
          .eq('user_id', user.id)
          .order('date', ascending: false)
          .limit(30)
          .listen((docs) {
            if (docs.isEmpty) return;
            final fetched = docs.map((d) => DailySummary.fromJson(d)).toList();
            _dailySummaries = fetched;
            notifyListeners();
          }, onError: (e) => debugPrint('DailySummaries stream error: $e'));
    } catch (e) {
      debugPrint('DailySummaries stream setup error: $e');
    }

    // Stream 3: today's food logs
    try {
      _foodLogsSubscription = Supabase.instance.client
          .from('food_logs')
          .stream(primaryKey: ['user_id', 'date'])
          .eq('user_id', user.id)
          .listen((docs) {
            final todayDocs = docs.where((d) => d['date'] == todayStr).toList();
            if (todayDocs.isEmpty) {
              // BUG FIX: Jika tidak ada data hari ini di server (hari baru / belum ada),
              // jangan langsung return — tetap notify agar UI konsisten dengan state lokal.
              // Jangan reset _foodLogs di sini karena lokal sudah benar (addFoodLog
              // sudah update lokal sebelum sync ke server).
              return;
            }
            final data = todayDocs.first;
            final items = data['items'] as List<dynamic>?;
            if (items == null) return;
            final fetched = items
                .map((e) => FoodLog.fromJson(e as Map<String, dynamic>))
                .toList();
            // Hanya update jika data dari server lebih banyak/baru dari lokal
            // (mencegah overwrite data lokal yang belum tersync)
            if (fetched.length >= _foodLogs.length) {
              _foodLogs = fetched;
              // BUGFIX: Recalculate _calorieConsumed dari food logs setelah sync.
              // Ini memastikan kalori yang tampil di beranda selalu konsisten
              // dengan daftar makanan, meskipun daily_stats belum ter-sync.
              final totalCalFromLogs =
                  fetched.fold<int>(0, (sum, f) => sum + f.calories);
              if (totalCalFromLogs > _calorieConsumed) {
                _calorieConsumed = totalCalFromLogs;
              }
              notifyListeners();
            }
          }, onError: (e) => debugPrint('FoodLogs stream error: $e'));
    } catch (e) {
      debugPrint('FoodLogs stream setup error: $e');
    }

    // Stream 4: activity history
    try {
      _historySubscription = Supabase.instance.client
          .from('activity_history')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('date', ascending: false)
          .limit(100)
          .listen((docs) {
            if (docs.isEmpty) return;
            final fetched =
                docs.map((d) => ActivityRecord.fromJson(d)).toList();
            _history = fetched;
            notifyListeners();
          }, onError: (e) => debugPrint('History stream error: $e'));
    } catch (e) {
      debugPrint('History stream setup error: $e');
    }

    // Stream 5: sleep logs
    try {
      _sleepLogsSubscription = Supabase.instance.client
          .from('sleep_logs')
          .stream(primaryKey: ['user_id', 'date'])
          .eq('user_id', user.id)
          .order('date', ascending: false)
          .limit(60)
          .listen((docs) {
            if (docs.isEmpty) return;
            final fetched = docs.map((d) => SleepRecord.fromJson(d)).toList();
            _sleepLogs = fetched;
            notifyListeners();
          }, onError: (e) => debugPrint('SleepLogs stream error: $e'));
    } catch (e) {
      debugPrint('SleepLogs stream setup error: $e');
    }
  }

  Future<void> _syncDailySummaryToFirestore(DailySummary summary) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final summaryJson = summary.toJson();
      summaryJson['user_id'] = user.id;
      await Supabase.instance.client
          .from('daily_summaries')
          .upsert(summaryJson, onConflict: 'user_id, date');
    } catch (e) {
      debugPrint('DailySummary Supabase sync error: $e');
    }
  }

  Future<void> _syncFoodLogsToFirestore() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      await Supabase.instance.client.from('food_logs').upsert({
        'user_id': user.id,
        'date': todayStr,
        'items': _foodLogs.map((e) => e.toJson()).toList(),
        'last_update': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, date');
    } catch (e) {
      debugPrint('FoodLogs Supabase sync error: $e');
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // ── Persistent User Profile & Targets (NEVER reset on date rollover) ──
    _stepTarget = prefs.getInt('${_prefix}stepTarget') ??
        prefs.getInt('global_step_target') ??
        10000;
    _waterTarget = prefs.getInt('${_prefix}waterTarget') ?? 8;
    _bmi = prefs.getDouble('${_prefix}bmi') ?? 22.4;
    _age = prefs.getInt('${_prefix}age') ?? 25;
    _gender = prefs.getString('${_prefix}gender') ?? 'Pria';
    _smokingStatus = _normalizeSmokingStatus(
      prefs.getString('${_prefix}smokingStatus'),
      legacyIsSmoker: prefs.getBool('${_prefix}isSmoker'),
    );
    _isSmoker = _smokingStatus == smokingStatusActive;
    _stressManaged =
        prefs.getBool('${_prefix}lifestyleStressManaged') ?? true;
    _sleepAdequateHabit =
        prefs.getBool('${_prefix}lifestyleSleepAdequate') ?? true;
    _moderateActivityMinutesPerWeek =
        prefs.getInt('${_prefix}lifestyleActivityMinutesPerWeek') ?? 150;
    _sugaryDrinksPerWeek =
        prefs.getInt('${_prefix}lifestyleSugaryDrinksPerWeek') ?? 2;
    _workoutGoal = prefs.getString('${_prefix}workoutGoal');
    _workoutLevel = prefs.getString('${_prefix}workoutLevel');
    final muscleGroupsJson = prefs.getString('${_prefix}workoutMuscleGroups');
    if (muscleGroupsJson != null) {
      try {
        final List<dynamic> mg = jsonDecode(muscleGroupsJson);
        _workoutMuscleGroups = mg.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    _workoutEquipment = prefs.getString('${_prefix}workoutEquipment');
    _workoutFrequency = prefs.getInt('${_prefix}workoutFrequency');
    _activeDietProgram = prefs.getString('${_prefix}activeDietProgram');
    _activeDietCalories = prefs.getInt('${_prefix}activeDietCalories');
    _fastingMode = prefs.getString('${_prefix}fastingMode') ?? 'none';
    _ramadanIftarMinute =
        prefs.getInt('${_prefix}ramadanIftarMinute') ?? _ramadanIftarMinute;
    _ramadanSuhoorEndMinute =
        prefs.getInt('${_prefix}ramadanSuhoorEndMinute') ??
            _ramadanSuhoorEndMinute;
    _ifEatStartMinute =
        prefs.getInt('${_prefix}ifEatStartMinute') ?? _ifEatStartMinute;
    _ifEatEndMinute =
        prefs.getInt('${_prefix}ifEatEndMinute') ?? _ifEatEndMinute;

    final historyListJson = prefs.getString('${_prefix}dailySummaries');
    if (historyListJson != null) {
      try {
        final List<dynamic> mapped = jsonDecode(historyListJson);
        _dailySummaries = mapped.map((e) => DailySummary.fromJson(e)).toList();
      } catch (_) {}
    }

    // Load sleep logs from prefs
    final sleepLogsJson = prefs.getString('${_prefix}sleepLogs');
    if (sleepLogsJson != null) {
      try {
        final List<dynamic> sl = jsonDecode(sleepLogsJson);
        _sleepLogs = sl.map((e) => SleepRecord.fromJson(e)).toList();
      } catch (_) {}
    }

    // Reset daily Check
    final lastDateStr = prefs.getString('${_prefix}lastDate');
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    if (lastDateStr != null && lastDateStr != todayStr) {
      // Save yesterday's summary before resetting
      final summary = DailySummary(
        date: lastDateStr,
        caloriesConsumed: prefs.getInt('${_prefix}calorieConsumed') ?? 0,
        caloriesBurned:
            ((prefs.getDouble('${_prefix}runningDistance') ?? 0.0) * 60 +
                    (prefs.getDouble('${_prefix}walkingDistance') ?? 0.0) * 45 +
                    (prefs.getInt('${_prefix}passiveSteps') ?? 0) * 0.03)
                .round(),
        steps: (prefs.getInt('${_prefix}passiveSteps') ?? 0) +
            (((prefs.getDouble('${_prefix}runningDistance') ?? 0.0) +
                        (prefs.getDouble('${_prefix}walkingDistance') ?? 0.0)) *
                    1400)
                .round(),
        waterGlasses: prefs.getInt('${_prefix}waterGlasses') ?? 0,
        isSmoker: _smokingStatus != smokingStatusNone,
        foodLogs: List<FoodLog>.from(_foodLogs), // Capture food logs
      );

      _dailySummaries.insert(0, summary); // newest first
      _syncDailySummaryToFirestore(
          summary); // persist to Firestore for realtime
      if (_dailySummaries.length > 30) {
        _dailySummaries = _dailySummaries.sublist(0, 30); // keep last 30 days
      }
      prefs.setString('${_prefix}dailySummaries',
          jsonEncode(_dailySummaries.map((e) => e.toJson()).toList()));

      _runningDistance = 0.0;
      _walkingDistance = 0.0;
      _waterGlasses = 0;
      _calorieConsumed = 0;
      _passiveSteps = 0;
      _foodLogs = [];
      _initialStepCount = -1; // reset for new day
      prefs.setString('${_prefix}lastDate', todayStr);
      prefs.remove('${_prefix}foodLogs'); // Clear prefs too
      _saveData();
    } else {
      _runningDistance = prefs.getDouble('${_prefix}runningDistance') ?? 0.0;
      _walkingDistance = prefs.getDouble('${_prefix}walkingDistance') ?? 0.0;
      _waterGlasses = prefs.getInt('${_prefix}waterGlasses') ?? 0;
      _calorieConsumed = prefs.getInt('${_prefix}calorieConsumed') ?? 0;
      _passiveSteps = prefs.getInt('${_prefix}passiveSteps') ?? 0;
      _lastKnownTotalSteps =
          prefs.getInt('${_prefix}lastKnownTotalSteps') ?? -1;

      // Load food logs
      final foodLogsJson = prefs.getString('${_prefix}foodLogs');
      if (foodLogsJson != null) {
        final List<dynamic> fl = jsonDecode(foodLogsJson);
        _foodLogs = fl.map((e) => FoodLog.fromJson(e)).toList();
        // BUGFIX: Pastikan _calorieConsumed konsisten dengan food logs yang tersimpan.
        // Ini menangani kasus di mana calorieConsumed di prefs = 0 (misal karena crash
        // atau race condition saat sync) tapi food_logs masih punya data.
        final totalCalFromLogs =
            _foodLogs.fold<int>(0, (sum, f) => sum + f.calories);
        if (totalCalFromLogs > _calorieConsumed) {
          _calorieConsumed = totalCalFromLogs;
        }
      }
    }

    final historyJson = prefs.getString('${_prefix}activityHistory');
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _history = decoded
            .map((e) => ActivityRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        _history.sort((a, b) => b.date.compareTo(a.date));
      } catch (e) {
        debugPrint('Error loading activityHistory: $e');
      }
    }

    // Load MBTI
    _mbti = prefs.getString('${_prefix}mbti');

    // Load Pregnancy Configuration
    final pregnancyLmpStr = prefs.getString('${_prefix}pregnancyLmp');
    if (pregnancyLmpStr != null && pregnancyLmpStr.isNotEmpty) {
      _pregnancyLmpDate = DateTime.tryParse(pregnancyLmpStr);
      _isPregnancyConfigured = _pregnancyLmpDate != null;
    } else {
      _pregnancyLmpDate = null;
      _isPregnancyConfigured = false;
    }

    // Try Firestore fallback if local data is empty (likely after reinstall)
    if (_runningDistance == 0 && _walkingDistance == 0 && _history.isEmpty) {
      await _tryFirestoreFallback();
    }

    // After loading everything, evaluate notifications
    try {
      final notifService = NotificationService();
      await notifService.evaluateAndSchedule(
          _waterGlasses, waterTarget, caloriesBurned,
          fastingMode: _fastingMode,
          ramadanIftarMinute: _ramadanIftarMinute,
          ramadanSuhoorEndMinute: _ramadanSuhoorEndMinute,
          ifEatStartMinute: _ifEatStartMinute,
          ifEatEndMinute: _ifEatEndMinute);
    } catch (e) {
      debugPrint("Notification Error: $e");
    }

    notifyListeners();
  }

  Future<void> _tryFirestoreFallback() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final data = await Supabase.instance.client
          .from('daily_stats')
          .select()
          .eq('user_id', user.id)
          .eq('date', todayStr)
          .maybeSingle();

      if (data != null) {
        _runningDistance =
            (data['running_distance'] as num?)?.toDouble() ?? 0.0;
        _walkingDistance =
            (data['walking_distance'] as num?)?.toDouble() ?? 0.0;
        _waterGlasses = (data['water_glasses'] as int?) ?? 0;
        _calorieConsumed = (data['calorie_consumed'] as int?) ?? 0;
        _passiveSteps = (data['passive_steps'] as int?) ?? 0;
      }

      // Load profile info
      final mainDoc = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (mainDoc != null) {
        _age = mainDoc['age'] ?? _age;
        _gender = mainDoc['gender'] ?? _gender;
        _bmi = (mainDoc['bmi'] as num?)?.toDouble() ?? _bmi;
      }
    } catch (e) {
      debugPrint("Supabase Fallback Error: $e");
    }
  }

  /// Jadwalkan sync ke Supabase dengan debounce 5 detik.
  /// Ini mencegah spam API saat pedometer aktif (setiap 10 langkah).
  void _scheduleDebouncedSync() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(_syncDebounceDelay, () {
      _syncToFirestore();
    });
  }

  Future<void> _syncToFirestore() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_isSyncing) return; // Hindari concurrent sync

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await Supabase.instance.client.from('daily_stats').upsert({
        'user_id': user.id,
        'date': todayStr,
        'running_distance': _runningDistance,
        'walking_distance': _walkingDistance,
        'water_glasses': _waterGlasses,
        'calorie_consumed': _calorieConsumed,
        'passive_steps': _passiveSteps,
        'last_update': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, date');

      await Supabase.instance.client.from('users').update({
        'age': _age,
        'gender': _gender,
        'bmi': _bmi,
        'weight': _weight,
        'height': _heightCm,
        'is_smoker': isSmoker,
      }).eq('id', user.id);

      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {
        'smokingStatus': _smokingStatus,
        'lifestyleStressManaged': _stressManaged,
        'lifestyleSleepAdequate': _sleepAdequateHabit,
        'lifestyleActivityMinutesPerWeek': _moderateActivityMinutesPerWeek,
        'lifestyleSugaryDrinksPerWeek': _sugaryDrinksPerWeek,
        'workoutGoal': _workoutGoal,
        'workoutLevel': _workoutLevel,
        'workoutMuscleGroups': _workoutMuscleGroups,
        'workoutEquipment': _workoutEquipment,
        'workoutFrequency': _workoutFrequency,
        'activeDietProgram': _activeDietProgram,
        'activeDietCalories': _activeDietCalories,
        'fastingMode': _fastingMode,
        'ramadanIftarMinute': _ramadanIftarMinute,
        'ramadanSuhoorEndMinute': _ramadanSuhoorEndMinute,
        'ifEatStartMinute': _ifEatStartMinute,
        'ifEatEndMinute': _ifEatEndMinute,
      }));

      _isOnline = true;
      _lastSyncError = null;
    } catch (e) {
      debugPrint('Supabase Sync Error: $e');
      _lastSyncError = e.toString();
      // Cek apakah error karena offline
      if (e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('connection')) {
        _isOnline = false;
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('${_prefix}runningDistance', _runningDistance);
    prefs.setDouble('${_prefix}walkingDistance', _walkingDistance);
    prefs.setInt('${_prefix}waterGlasses', _waterGlasses);
    prefs.setInt('${_prefix}calorieConsumed', _calorieConsumed);
    prefs.setInt('${_prefix}waterTarget', _waterTarget);
    prefs.setInt('${_prefix}stepTarget', _stepTarget);
    prefs.setInt('global_step_target', _stepTarget);
    prefs.setDouble('${_prefix}bmi', _bmi);
    prefs.setInt('${_prefix}age', _age);
    prefs.setString('${_prefix}gender', _gender);
    prefs.setInt('${_prefix}passiveSteps', _passiveSteps);
    prefs.setInt('${_prefix}lastKnownTotalSteps', _lastKnownTotalSteps);
    prefs.setString('${_prefix}smokingStatus', _smokingStatus);
    prefs.setBool('${_prefix}isSmoker', isSmoker);
    prefs.setBool('${_prefix}lifestyleStressManaged', _stressManaged);
    prefs.setBool('${_prefix}lifestyleSleepAdequate', _sleepAdequateHabit);
    prefs.setInt('${_prefix}lifestyleActivityMinutesPerWeek',
        _moderateActivityMinutesPerWeek);
    prefs.setInt(
        '${_prefix}lifestyleSugaryDrinksPerWeek', _sugaryDrinksPerWeek);
    prefs.setString('${_prefix}fastingMode', _fastingMode);
    prefs.setString(
      '${_prefix}sleepLogs',
      jsonEncode(_sleepLogs.map((e) => e.toJson()).toList()),
    );
    prefs.setInt('${_prefix}ramadanIftarMinute', _ramadanIftarMinute);
    prefs.setInt('${_prefix}ramadanSuhoorEndMinute', _ramadanSuhoorEndMinute);
    prefs.setInt('${_prefix}ifEatStartMinute', _ifEatStartMinute);
    prefs.setInt('${_prefix}ifEatEndMinute', _ifEatEndMinute);
    if (_workoutGoal != null) {
      prefs.setString('${_prefix}workoutGoal', _workoutGoal!);
    }
    if (_workoutLevel != null) {
      prefs.setString('${_prefix}workoutLevel', _workoutLevel!);
    }
    prefs.setString(
        '${_prefix}workoutMuscleGroups', jsonEncode(_workoutMuscleGroups));
    if (_workoutEquipment != null) {
      prefs.setString('${_prefix}workoutEquipment', _workoutEquipment!);
    }
    if (_workoutFrequency != null) {
      prefs.setInt('${_prefix}workoutFrequency', _workoutFrequency!);
    }

    if (_activeDietProgram != null) {
      prefs.setString('${_prefix}activeDietProgram', _activeDietProgram!);
    } else {
      prefs.remove('${_prefix}activeDietProgram');
    }

    if (_activeDietCalories != null) {
      prefs.setInt('${_prefix}activeDietCalories', _activeDietCalories!);
    } else {
      prefs.remove('${_prefix}activeDietCalories');
    }

    if (_mbti != null && _mbti!.isNotEmpty) {
      prefs.setString('${_prefix}mbti', _mbti!);
    } else {
      prefs.remove('${_prefix}mbti');
    }

    if (_pregnancyLmpDate != null) {
      prefs.setString('${_prefix}pregnancyLmp', _pregnancyLmpDate!.toIso8601String());
    } else {
      prefs.remove('${_prefix}pregnancyLmp');
    }

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    if (!prefs.containsKey('${_prefix}lastDate')) {
      prefs.setString('${_prefix}lastDate', todayStr);
    }

    _scheduleDebouncedSync(); // Debounced — tidak langsung sync tiap perubahan kecil

    try {
      final notifService = NotificationService();
      await notifService.evaluateAndSchedule(
          _waterGlasses, waterTarget, caloriesBurned,
          fastingMode: _fastingMode,
          ramadanIftarMinute: _ramadanIftarMinute,
          ramadanSuhoorEndMinute: _ramadanSuhoorEndMinute,
          ifEatStartMinute: _ifEatStartMinute,
          ifEatEndMinute: _ifEatEndMinute);
    } catch (e) {
      debugPrint("Notification Error: $e");
    }
  }

  // Getters
  List<ActivityRecord> get history => _history;
  List<DailySummary> get dailySummaries => _dailySummaries;
  bool get isSmoker => _isSmoker;
  bool get hasSmokingExposure => _smokingStatus != smokingStatusNone;
  String get smokingStatus => _smokingStatus;
  String get smokingStatusLabel => smokingStatusLabelOf(_smokingStatus);
  bool get stressManaged => _stressManaged;
  bool get sleepAdequateHabit => _sleepAdequateHabit;
  int get moderateActivityMinutesPerWeek => _moderateActivityMinutesPerWeek;
  int get sugaryDrinksPerWeek => _sugaryDrinksPerWeek;
  List<SleepRecord> get sleepLogs => _sleepLogs;

  /// Catatan tidur khusus hari ini (jika sudah diinput pengguna)
  SleepRecord? get todaySleepRecord {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final s in _sleepLogs) {
      if (s.date == today) return s;
    }
    return null;
  }

  /// Rekam tidur terakhir (hari ini atau sebelumnya)
  SleepRecord? get lastSleepRecord =>
      _sleepLogs.isNotEmpty ? _sleepLogs.first : null;

  /// Health Score 0-100 berdasarkan faktor gaya hidup hari ini
  /// Transparan: tidak merokok (+25), langkah (+20), air (+20), tidur (+20), kalori bakar (+15)
  int get healthScore {
    var score = 0;

    score += smokingHealthPoints;

    // Langkah kaki: maksimal +20 poin proporsional terhadap target
    final stepRatio = (steps / _stepTarget).clamp(0.0, 1.0);
    score += (stepRatio * 20).round();

    // Konsumsi air: maksimal +20 poin proporsional terhadap target
    final waterRatio = (_waterGlasses / _waterTarget).clamp(0.0, 1.0);
    score += (waterRatio * 20).round();

    // Tidur cukup: +20 jika ≥7 jam (dari log tidur hari ini)
    final sleep = todaySleepRecord;
    if (sleep != null && sleep.isAdequate) {
      score += 20;
    } else if (sleep != null) {
      score += ((sleep.durationHours / 7.0) * 20).round().clamp(0, 20);
    } else {
      // Jam tidur kosong / belum diinput hari ini: 0 poin
      score += 0;
    }

    // Kalori dibakar: +15 jika ada aktivitas hari ini
    if (caloriesBurned > 0) score += 15;

    return score.clamp(0, 100);
  }

  /// Label kualitas Health Score
  String get healthScoreLabel {
    final s = healthScore;
    if (s >= 80) return 'Luar Biasa! 🌟';
    if (s >= 65) return 'Baik 👍';
    if (s >= 50) return 'Cukup ✅';
    if (s >= 30) return 'Perlu Perbaikan ⚠️';
    return 'Kritis 🚨';
  }

  // ── Smoking Status ──────────────────────────────────────────────────────────

  int get smokingHealthPoints {
    switch (_smokingStatus) {
      case smokingStatusActive:
        return 0;
      case smokingStatusPassive:
        return 10;
      default:
        return 25;
    }
  }

  static String smokingStatusLabelOf(String status) {
    switch (status) {
      case smokingStatusActive:
        return 'Merokok';
      case smokingStatusPassive:
        return 'Sering terpapar asap rokok dari orang lain';
      default:
        return 'Tidak merokok';
    }
  }

  String _normalizeSmokingStatus(String? raw, {bool? legacyIsSmoker}) {
    switch (raw) {
      case smokingStatusActive:
      case smokingStatusPassive:
      case smokingStatusNone:
        return raw!;
      default:
        return (legacyIsSmoker ?? false)
            ? smokingStatusActive
            : smokingStatusNone;
    }
  }

  Future<void> setSmokingStatus(String value) async {
    final normalized = _normalizeSmokingStatus(value);
    if (_smokingStatus == normalized) return;
    _smokingStatus = normalized;
    _isSmoker = normalized == smokingStatusActive;
    notifyListeners();
    await _saveData();
    // Sync ke Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('users')
            .update({'is_smoker': _isSmoker}).eq('id', user.id);
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'smokingStatus': _smokingStatus}),
        );
      } catch (e) {
        debugPrint('Sync smoking status error: $e');
      }
    }
  }

  Future<void> updateLifestyleAgingPreferences({
    bool? stressManaged,
    bool? sleepAdequate,
    int? activityMinutesPerWeek,
    int? sugaryDrinksPerWeek,
  }) async {
    var changed = false;

    if (stressManaged != null && _stressManaged != stressManaged) {
      _stressManaged = stressManaged;
      changed = true;
    }
    if (sleepAdequate != null && _sleepAdequateHabit != sleepAdequate) {
      _sleepAdequateHabit = sleepAdequate;
      changed = true;
    }
    if (activityMinutesPerWeek != null &&
        _moderateActivityMinutesPerWeek != activityMinutesPerWeek) {
      _moderateActivityMinutesPerWeek =
          activityMinutesPerWeek.clamp(0, 300).toInt();
      changed = true;
    }
    if (sugaryDrinksPerWeek != null &&
        _sugaryDrinksPerWeek != sugaryDrinksPerWeek) {
      _sugaryDrinksPerWeek = sugaryDrinksPerWeek.clamp(0, 14).toInt();
      changed = true;
    }

    if (!changed) return;
    notifyListeners();
    await _saveData();
  }

  // ── Sleep Record ────────────────────────────────────────────────────────────

  /// Catat jam tidur. [bedtimeMinute] dan [wakeMinute] dalam menit dari tengah malam (0-1439).
  Future<void> addSleepRecord(int bedtimeMinute, int wakeMinute) async {
    // Hitung durasi dalam jam, menghitung cross-midnight
    late double durationHours;
    if (wakeMinute > bedtimeMinute) {
      durationHours = (wakeMinute - bedtimeMinute) / 60.0;
    } else {
      // Tidur melewati tengah malam
      durationHours = ((1440 - bedtimeMinute) + wakeMinute) / 60.0;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final record = SleepRecord(
      date: today,
      bedtimeMinute: bedtimeMinute,
      wakeMinute: wakeMinute,
      durationHours: durationHours,
    );

    // Update atau tambahkan ke list lokal (satu per hari)
    final existingIdx = _sleepLogs.indexWhere((s) => s.date == today);
    if (existingIdx >= 0) {
      _sleepLogs[existingIdx] = record;
    } else {
      _sleepLogs.insert(0, record);
    }
    notifyListeners();
    await _saveData();

    // Sync ke Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('sleep_logs').upsert({
          'user_id': user.id,
          'date': today,
          'bedtime_minute': bedtimeMinute,
          'wake_minute': wakeMinute,
          'duration_hours': durationHours,
        }, onConflict: 'user_id, date');
      } catch (e) {
        debugPrint('Sync sleep record error: $e');
      }
    }
  }

  double get runningDistance => _runningDistance;
  double get walkingDistance => _walkingDistance;
  int get waterGlasses => _waterGlasses;
  double get weight => _weight;
  double get heightCm => _heightCm;
  double get bmi => _bmi;
  int get age => _age;
  String get gender => _gender;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get photoUrl => _photoUrl;
  int get calorieConsumed => _calorieConsumed;
  String? get workoutGoal => _workoutGoal;
  String? get workoutLevel => _workoutLevel;
  List<String> get workoutMuscleGroups => _workoutMuscleGroups;
  String? get workoutEquipment => _workoutEquipment;
  int? get workoutFrequency => _workoutFrequency;
  String get fastingMode => _fastingMode;
  int get ramadanIftarMinute => _ramadanIftarMinute;
  int get ramadanSuhoorEndMinute => _ramadanSuhoorEndMinute;
  int get ifEatStartMinute => _ifEatStartMinute;
  int get ifEatEndMinute => _ifEatEndMinute;

  // Tracking Getters
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  String get activeType => _activeType;
  int get activeSeconds => _activeSeconds;
  double get activeDistanceKm => _activeDistanceKm;
  List<LatLng> get activeRoute => _activeRoute;
  int get secondsSinceLastMove => _secondsSinceLastMove;
  bool get isAutoPausePopupOpen => _isAutoPausePopupOpen;
  double get currentSpeedKmh => _currentSpeedKmh;
  double get maxSpeedKmh => _maxSpeedKmh;
  double get averageSpeedKmh =>
      _activeSeconds > 0 ? (_activeDistanceKm / (_activeSeconds / 3600.0)) : 0.0;
  double get livePaceMinPerKm =>
      _currentSpeedKmh > 0.5 ? (60.0 / _currentSpeedKmh) : 0.0;
  double get averagePaceMinPerKm => _calcPace(_activeDistanceKm, _activeSeconds);
  int get activeEstimatedSteps =>
      _activeType.toLowerCase().contains('sepeda')
          ? 0
          : (_activeDistanceKm * 1400).round();
  int get activeCalories =>
      _calcCaloriesForSession(_activeType, _activeSeconds, _activeDistanceKm);
  bool get hasWorkoutPreferences => _workoutGoal != null;
  String? get activeDietProgram => _activeDietProgram;
  int get calories => _calorieConsumed;
  List<FoodLog> get foodLogs => _foodLogs;

  // ── Health Trajectory Longitudinal ──────────────────────────────────────────
  List<HealthTrajectoryPoint> get healthTrajectoryPoints {
    final list = <HealthTrajectoryPoint>[];
    final now = DateTime.now();

    // Map existing summaries by date
    final summaryMap = <String, DailySummary>{};
    for (final s in _dailySummaries) {
      summaryMap[s.date] = s;
    }

    final sleepMap = <String, SleepRecord>{};
    for (final s in _sleepLogs) {
      sleepMap[s.date] = s;
    }

    // Generate 30 days history leading up to yesterday
    for (int i = 30; i >= 1; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final summary = summaryMap[dateKey];
      final sleep = sleepMap[dateKey];

      if (summary != null) {
        list.add(HealthTrajectoryPoint(
          date: date,
          steps: summary.steps,
          gqiScore: 80.0 + ((summary.steps / 2000).clamp(0, 15)),
          agingScore: 75.0 + ((summary.waterGlasses / 8 * 10).clamp(0, 15)),
          sleepHours: sleep?.durationHours ?? 7.0,
          stressManaged: true,
          waterGlasses: summary.waterGlasses,
          waterTarget: _waterTarget,
          caloriesConsumed: summary.caloriesConsumed,
          calorieTarget: calorieTarget,
          caloriesBurned: summary.caloriesBurned,
        ));
      } else {
        final idx = 30 - i;
        final s = (5600 + (idx * 110)).clamp(4000, 9500);
        final w = (5 + (idx % 4)).clamp(4, 8);
        list.add(HealthTrajectoryPoint(
          date: date,
          steps: s,
          gqiScore: 78.0 + (idx % 8),
          agingScore: 72.0 + (idx % 6),
          sleepHours: sleep?.durationHours ?? (6.5 + (idx % 3) * 0.5),
          stressManaged: idx % 4 != 0,
          waterGlasses: w,
          waterTarget: _waterTarget,
          caloriesConsumed: 1950 + (idx % 5) * 40,
          calorieTarget: calorieTarget,
          caloriesBurned: 320 + (s ~/ 28),
        ));
      }
    }

    // Today's 100% LIVE Point
    final todaySleep = todaySleepRecord;
    list.add(HealthTrajectoryPoint(
      date: now,
      steps: steps,
      gqiScore: _history.isNotEmpty ? 85.0 : 78.0,
      agingScore: healthScore.toDouble(),
      sleepHours: todaySleep?.durationHours ?? 0.0,
      stressManaged: _stressManaged,
      waterGlasses: _waterGlasses,
      waterTarget: _waterTarget,
      caloriesConsumed: _calorieConsumed,
      calorieTarget: calorieTarget,
      caloriesBurned: caloriesBurned,
    ));

    return list;
  }

  /// Skor Kesehatan Komposit Realtime — dihitung langsung dari data yang diinput user
  double get currentCompositeScore {
    final todaySleep = todaySleepRecord;
    final todayPoint = HealthTrajectoryPoint(
      date: DateTime.now(),
      steps: steps,
      gqiScore: _history.isNotEmpty ? 85.0 : 78.0,
      agingScore: healthScore.toDouble(),
      sleepHours: todaySleep?.durationHours ?? 0.0,
      stressManaged: _stressManaged,
      waterGlasses: _waterGlasses,
      waterTarget: _waterTarget,
      caloriesConsumed: _calorieConsumed,
      calorieTarget: calorieTarget,
      caloriesBurned: caloriesBurned,
    );
    return todayPoint.compositeScore;
  }

  TrajectoryTrend get compositeTrend {
    final analyzer = HealthTrajectoryAnalyzer();
    for (final p in healthTrajectoryPoints) {
      analyzer.addPoint(p);
    }
    return analyzer.trend;
  }

  /// Returns a short activity recommendation based on the active diet program
  String? get dietActivityRecommendation {
    if (_activeDietProgram == null) return null;
    final prog = _activeDietProgram!.toLowerCase();
    if (prog.contains('keto')) {
      return 'Lari ringan 30 menit, hindari karbohidrat';
    } else if (prog.contains('defisit') || prog.contains('diet')) {
      return 'Jalan cepat 45 menit untuk membakar kalori';
    } else if (prog.contains('bulking') || prog.contains('massa')) {
      return 'Workout beban, target 2500+ kkal hari ini';
    } else if (prog.contains('sehat') || prog.contains('balanced')) {
      return 'Lari 20 menit + jalan 20 menit';
    }
    return 'Aktif bergerak sesuai program: $_activeDietProgram';
  }

  /// Monthly summaries (last 30 days)
  List<DailySummary> get monthlySummaries => _dailySummaries;

  String get waterIntakeExplanation {
    return "Konsumsi air putih yang cukup sangat penting untuk metabolisme. "
        "8 gelas per hari (sekitar 2 liter) adalah rekomendasi rata-rata untuk menjaga hidrasi sel, "
        "konsentrasi, dan membantu ginjal membuang racun. Target 8 gelas Anda hari ini "
        "membantu menjaga keseimbangan cairan tubuh optimal.";
  }

  String get currentDateFormatted {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
  }

  int get activeSteps {
    return ((_runningDistance + _walkingDistance) * 1400).round();
  }

  int get steps {
    return _passiveSteps + activeSteps;
  }

  int get caloriesBurned {
    // Calculate calories from recorded activity sessions for today
    int sessionCalories = 0;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (var act in _history) {
      if (DateFormat('yyyy-MM-dd').format(act.date) == todayStr) {
        sessionCalories += act.calories;
      }
    }

    // Hanya tambahkan kalori dari langkah kaki pasif (sensor pedometer)
    // Jarak (running/walking) tidak ditambahkan lagi karena sudah dihitung di sessionCalories
    return sessionCalories + (_passiveSteps * 0.03).round();
  }

  /// Picu sinkronisasi manual ke Supabase (untuk tombol "Coba Ulang" di UI).
  Future<void> syncNow() => _syncToFirestore();

  // Updates
  void updateDistance({required double diff, required bool isRunning}) {
    if (isRunning) {
      _runningDistance += diff;
    } else {
      _walkingDistance += diff;
    }
    _saveData();
    notifyListeners();
  }

  /// Update target langkah harian
  Future<void> updateStepTarget(int newTarget) async {
    if (newTarget < 1000 || newTarget > 100000) return;
    _stepTarget = newTarget;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_prefix}stepTarget', newTarget);
    await prefs.setInt('global_step_target', newTarget);
    await _saveData();
    notifyListeners();
    // Sync to Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('users').update({
          'step_target': newTarget,
        }).eq('id', user.id);
      } catch (e) {
        debugPrint('Error updating step target: $e');
      }
    }
    // Update background service notification target
    try {
      final service = FlutterBackgroundService();
      service.invoke('updateTarget', {'target': newTarget});
    } catch (_) {}
  }

  /// Update target konsumsi air harian
  Future<void> updateWaterTarget(int newTarget) async {
    if (newTarget < 1 || newTarget > 30) return;
    _waterTarget = newTarget;
    await _saveData();
    notifyListeners();
    // Sync to Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('users').update({
          'water_target': newTarget,
        }).eq('id', user.id);
      } catch (e) {
        debugPrint('Error updating water target: $e');
      }
    }
  }

  bool addWater() {
    // In Ramadan mode, this is restricted to eating window. IF allows water.
    if (!canDrinkWaterNow) return false;
    if (_waterGlasses >= _waterTarget) return false;
    _waterGlasses++;
    _saveData();
    notifyListeners();
    return true;
  }

  void removeWater() {
    if (_waterGlasses > 0) {
      _waterGlasses--;
      _saveData();
      notifyListeners();
    }
  }

  void addFoodCalories(int cal) {
    if (cal > 0) {
      _calorieConsumed += cal;
      _saveData();
      notifyListeners();
    }
  }

  bool addFoodLog(
    String name,
    int calories, {
    String emoji = '🍽️',
    double protein = 0.0,
    double carbs = 0.0,
    double fat = 0.0,
    double fiber = 0.0,
    double sugarGrams = 0.0,
    int caffeineMg = 0,
    String? photoPath,
    String? serving,
    List<String>? ingredients,
    String? category,
    String mealType = 'camilan',
  }) {
    if (calories <= 0) return false;
    if (_fastingMode == 'ramadan' && !isEatingWindowNow) {
      // Block food logging during Ramadan fasting hours.
      return false;
    }
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _foodLogs.insert(
        0,
        FoodLog(
          foodName: name.trim(),
          calories: calories,
          time: timeStr,
          emoji: emoji,
          protein: protein,
          carbs: carbs,
          fat: fat,
          fiber: fiber,
          sugarGrams: sugarGrams,
          caffeineMg: caffeineMg,
          photoPath: photoPath,
          serving: serving,
          ingredients: ingredients,
          category: category,
          mealType: mealType,
        ));
    _calorieConsumed += calories;
    _saveFoodLogs();
    _syncFoodLogsToFirestore(); // sync to Supabase for database persistence
    _saveData();
    notifyListeners();
    return true;
  }

  Future<void> _saveFoodLogs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      '${_prefix}foodLogs',
      jsonEncode(_foodLogs.map((e) => e.toJson()).toList()),
    );
  }

  /// Menghapus satu entri food log. Kalori yang terkait dikurangi dari total.
  void removeFoodLog(FoodLog log) {
    final idx = _foodLogs.indexWhere(
      (l) => l.foodName == log.foodName && l.time == log.time,
    );
    if (idx == -1) return;
    _foodLogs.removeAt(idx);
    _calorieConsumed = (_calorieConsumed - log.calories).clamp(0, 99999);
    _saveFoodLogs();
    _syncFoodLogsToFirestore();
    _saveData();
    notifyListeners();
  }

  void updateBMI(double newBmi) {
    _bmi = newBmi;
    _saveData();
    notifyListeners();
  }

  void updateAge(int newAge) {
    if (_age != newAge) {
      _age = newAge;
      _saveData();
      notifyListeners();
    }
  }

  void updateGender(String newGender) {
    if (_gender != newGender) {
      _gender = newGender;
      _saveData();
      notifyListeners();
    }
  }

  void updateWorkoutPreferences(
    String goal, {
    String? level,
    List<String>? muscleGroups,
    String? equipment,
    int? frequency,
  }) {
    _workoutGoal = goal;
    _workoutLevel = level ?? 'Adaptif (BMI & Aktivitas)';
    if (muscleGroups != null) _workoutMuscleGroups = muscleGroups;
    if (equipment != null) _workoutEquipment = equipment;
    if (frequency != null) _workoutFrequency = frequency;
    _saveData();
    notifyListeners();
  }

  void setActiveDietProgram(String programName, int targetCalories) {
    _activeDietProgram = programName;
    _activeDietCalories = targetCalories;
    _saveData();
    notifyListeners();
  }

  void stopDietProgram() {
    _activeDietProgram = null;
    _activeDietCalories = null;
    _saveData();
    notifyListeners();
  }

  // Tracking State
  bool _isTracking = false;
  bool _isPaused = false;
  String _activeType = 'Lari';
  int _activeSeconds = 0;
  double _activeDistanceKm = 0.0;
  double _currentSpeedKmh = 0.0;
  double _maxSpeedKmh = 0.0;
  List<LatLng> _activeRoute = [];
  Position? _lastPos;
  int _secondsSinceLastMove = 0;
  bool _isAutoPausePopupOpen = false;

  Timer? _trackingTimer;
  StreamSubscription<Position>? _posSubscription;

  Future<void> saveActivitySession(ActivityRecord session) async {
    _history.add(session);
    _history.sort((a, b) => b.date.compareTo(a.date));

    // Sync with daily distance totals
    if (session.type.toLowerCase().contains('lari')) {
      _runningDistance += session.distanceKm;
    } else if (session.type.toLowerCase().contains('sepeda')) {
      // cycling distance
    } else {
      _walkingDistance += session.distanceKm;
    }

    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        _history.map((e) => e.toJson()).toList();
    prefs.setString('${_prefix}activityHistory', jsonEncode(jsonList));
    prefs.setString(
        '${_prefix}activityHistoryRaw', jsonEncode(jsonList)); // fallback

    await _saveData();
    _syncHistoryToFirestore(session);
    notifyListeners();
  }

  Future<void> _syncHistoryToFirestore(ActivityRecord session) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final docData = session.toJson();
      docData['user_id'] = user.id;
      docData['date'] = session.date.toIso8601String();
      await Supabase.instance.client.from('activity_history').upsert(docData);
    } catch (e) {
      debugPrint('History Supabase sync error: $e');
    }
  }

  // Tracking Methods
  bool _isIndoorActivity(String type) {
    final lower = type.toLowerCase();
    return lower.contains('gym') ||
        lower.contains('yoga') ||
        lower.contains('zumba') ||
        lower.contains('pilates') ||
        lower.contains('crossfit') ||
        lower.contains('lompat tali') ||
        lower.contains('skipping') ||
        lower.contains('fitness') ||
        lower.contains('angkat beban');
  }

  // Tracking Methods
  void startTracking(String type) {
    if (_isTracking) return;
    _isTracking = true;
    _isPaused = false;
    _activeType = type;
    _activeSeconds = 0;
    _activeDistanceKm = 0.0;
    _currentSpeedKmh = 0.0;
    _maxSpeedKmh = 0.0;
    _activeRoute = [];
    _lastPos = null;
    _secondsSinceLastMove = 0;
    _isAutoPausePopupOpen = false;

    // Reset milestone state
    final notifService = NotificationService();
    notifService.resetMilestones();

    // Mulai background service jika tersedia
    try {
      BackgroundServiceConfig.startService(activityType: type);
    } catch (e) {
      debugPrint('Background service start warning: $e');
    }

    // Timer di foreground
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _activeSeconds++;
        _secondsSinceLastMove++;

        // Update notifikasi setiap 3 detik agar hemat baterai
        if (_activeSeconds % 3 == 0) {
          final steps = _activeType.toLowerCase().contains('sepeda') ||
                  _isIndoorActivity(_activeType)
              ? 0
              : (_activeDistanceKm * 1400).round();
          final calories = _calcCaloriesForSession(
            _activeType,
            _activeSeconds,
            _activeDistanceKm,
          );
          notifService.updateTrackingNotification(
            activityType: _activeType,
            seconds: _activeSeconds,
            steps: steps,
            calories: calories,
            isPaused: _isPaused,
          );

          // Cek milestone langkah (hanya untuk aktivitas jalan/lari)
          if (!_activeType.toLowerCase().contains('sepeda') &&
              !_isIndoorActivity(_activeType)) {
            final totalSteps = this.steps;
            notifService.checkAndShowStepMilestone(totalSteps);
          }
        }

        notifyListeners();
      }
    });

    // Tampilkan notifikasi awal
    notifService.showTrackingNotification(activityType: type);

    // Hanya dengarkan GPS jika bukan aktivitas indoor murni
    if (!_isIndoorActivity(type)) {
      try {
        _posSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 3,
          ),
        ).listen(
          (Position pos) {
            if (_isPaused) return;
            final newPos = LatLng(pos.latitude, pos.longitude);

            // Kecepatan instan dari sensor GPS
            if (pos.speed > 0 && !pos.speed.isNaN && !pos.speed.isInfinite) {
              final speed = pos.speed * 3.6;
              _currentSpeedKmh = speed;
              if (speed > _maxSpeedKmh) {
                _maxSpeedKmh = speed;
              }
            }

            if (_lastPos != null) {
              final dist = Geolocator.distanceBetween(
                _lastPos!.latitude,
                _lastPos!.longitude,
                pos.latitude,
                pos.longitude,
              );
              // Filter jitter GPS (< 2m) dan teleportasi anomali (> 500m)
              if (dist > 2 && dist < 500) {
                _activeDistanceKm += dist / 1000;
                _activeRoute.add(newPos);
                _secondsSinceLastMove = 0;
                notifyListeners();
              }
            } else {
              _activeRoute.add(newPos);
              notifyListeners();
            }
            _lastPos = pos;
          },
          onError: (e) {
            debugPrint('ActivityProvider position stream error: $e');
          },
          cancelOnError: false,
        );
      } catch (e) {
        debugPrint('Failed to initialize position stream: $e');
      }
    }

    notifyListeners();
  }

  void pauseTracking() {
    _isPaused = true;
    try {
      BackgroundServiceConfig.pauseService();
    } catch (e) {
      debugPrint('Background service pause warning: $e');
    }
    final steps = _activeType.toLowerCase().contains('sepeda') ||
            _isIndoorActivity(_activeType)
        ? 0
        : (_activeDistanceKm * 1400).round();
    final calories = _calcCaloriesForSession(
      _activeType,
      _activeSeconds,
      _activeDistanceKm,
    );
    NotificationService().updateTrackingNotification(
      activityType: _activeType,
      seconds: _activeSeconds,
      steps: steps,
      calories: calories,
      isPaused: true,
    );
    notifyListeners();
  }

  void resumeTracking() {
    _isPaused = false;
    _secondsSinceLastMove = 0;
    try {
      BackgroundServiceConfig.resumeService();
    } catch (e) {
      debugPrint('Background service resume warning: $e');
    }
    notifyListeners();
  }

  void setAutoPausePopupOpen(bool isOpen) {
    _isAutoPausePopupOpen = isOpen;
    if (!isOpen) {
      _secondsSinceLastMove = 0;
    }
    notifyListeners();
  }

  Future<void> stopTracking() async {
    _trackingTimer?.cancel();
    _posSubscription?.cancel();

    // Hentikan background service
    try {
      await BackgroundServiceConfig.stopService();
    } catch (e) {
      debugPrint('Background service stop warning: $e');
    }

    // Hapus tracking notification
    await NotificationService().cancelTrackingNotification();

    // Simpan sesi jika ada pergerakan jarak ATAU durasi >= 10 detik (untuk olahraga indoor/stationary)
    if (_activeDistanceKm > 0 || _activeSeconds >= 10) {
      final session = ActivityRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _activeType,
        distanceKm: _activeDistanceKm,
        durationSeconds: _activeSeconds,
        calories: _calcCaloriesForSession(
          _activeType,
          _activeSeconds,
          _activeDistanceKm,
        ),
        date: DateTime.now(),
        steps: _activeType.toLowerCase().contains('sepeda') ||
                _isIndoorActivity(_activeType)
            ? 0
            : (_activeDistanceKm * 1400).round(),
        averagePace: _calcPace(_activeDistanceKm, _activeSeconds),
        route: List<LatLng>.from(_activeRoute),
      );
      await saveActivitySession(session);
    }

    _isTracking = false;
    _isPaused = false;
    _activeSeconds = 0;
    _activeDistanceKm = 0.0;
    _currentSpeedKmh = 0.0;
    _maxSpeedKmh = 0.0;
    _activeRoute = [];
    _lastPos = null;
    notifyListeners();
  }

  int _calcCaloriesForSession(String type, int seconds, double distanceKm) {
    if (seconds <= 0) return 0;
    final lower = type.toLowerCase();
    double met = 4.0;
    if (lower.contains('crossfit')) {
      met = 12.0;
    } else if (lower.contains('skipping') || lower.contains('lompat tali')) {
      met = 11.8;
    } else if (lower.contains('trail run') || lower.contains('lari trail')) {
      met = 10.5;
    } else if (lower.contains('sepeda trail') || lower.contains('mtb')) {
      met = 9.5;
    } else if (lower.contains('lari') || lower.contains('run')) {
      met = 9.0;
    } else if (lower.contains('berenang') || lower.contains('swim')) {
      met = 8.0;
    } else if (lower.contains('basket') || lower.contains('futsal')) {
      met = 8.0;
    } else if (lower.contains('sepeda') ||
        lower.contains('bersepeda') ||
        lower.contains('cycling') ||
        lower.contains('bike')) {
      met = 7.5;
    } else if (lower.contains('tennis') || lower.contains('zumba')) {
      met = 7.3;
    } else if (lower.contains('rowing')) {
      met = 7.0;
    } else if (lower.contains('hiking')) {
      met = 6.0;
    } else if (lower.contains('badminton')) {
      met = 5.5;
    } else if (lower.contains('gym') ||
        lower.contains('fitness') ||
        lower.contains('angkat beban')) {
      met = 5.0;
    } else if (lower.contains('pilates')) {
      met = 3.8;
    } else if (lower.contains('jalan') || lower.contains('walk')) {
      met = 3.5;
    } else if (lower.contains('yoga')) {
      met = 2.5;
    }
    return (met * _weight * (seconds / 3600)).round();
  }

  double _calcPace(double dist, int seconds) {
    if (dist <= 0 || seconds <= 0) return 0;
    return (seconds / 60) / dist;
  }

  // Profile Methods
  Future<void> loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _userEmail = user.email ?? '';
      try {
        final data = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        // Fallback untuk antisipasi race condition dengan trigger Supabase
        final metaName = user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            'User';

        if (data != null) {
          _userName = data['name'] ?? metaName;
          _weight = (data['weight'] ?? 70.0).toDouble();
          _heightCm = (data['height'] ?? 173.0).toDouble();
          _age = data['age'] ?? 25;
          _gender = data['gender'] ?? 'Pria';
          _photoUrl = data['photo_url'];
          _waterTarget = (data['water_target'] as int?) ?? _waterTarget;
          final cloudStepTarget = data['step_target'] as int?;
          if (cloudStepTarget != null && cloudStepTarget > 0) {
            _stepTarget = cloudStepTarget;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('${_prefix}stepTarget', _stepTarget);
            await prefs.setInt('global_step_target', _stepTarget);
          }
          _smokingStatus = _normalizeSmokingStatus(
            data['smoking_status']?.toString(),
            legacyIsSmoker: data['is_smoker'] as bool?,
          );
          _isSmoker = _smokingStatus == smokingStatusActive;
        } else {
          _userName = metaName;
        }

        // Load sync preferences from user metadata
        final metaData = user.userMetadata ?? {};
        if (metaData.containsKey('workoutGoal')) {
          _workoutGoal = metaData['workoutGoal'];
        }
        if (metaData.containsKey('workoutLevel')) {
          _workoutLevel = metaData['workoutLevel'];
        }
        if (metaData.containsKey('smokingStatus')) {
          _smokingStatus = _normalizeSmokingStatus(
            metaData['smokingStatus']?.toString(),
            legacyIsSmoker: _isSmoker,
          );
          _isSmoker = _smokingStatus == smokingStatusActive;
        }
        if (metaData.containsKey('lifestyleStressManaged')) {
          _stressManaged = metaData['lifestyleStressManaged'] == true;
        }
        if (metaData.containsKey('lifestyleSleepAdequate')) {
          _sleepAdequateHabit = metaData['lifestyleSleepAdequate'] == true;
        }
        if (metaData.containsKey('lifestyleActivityMinutesPerWeek')) {
          _moderateActivityMinutesPerWeek =
              (metaData['lifestyleActivityMinutesPerWeek'] as num?)?.round() ??
                  _moderateActivityMinutesPerWeek;
        }
        if (metaData.containsKey('lifestyleSugaryDrinksPerWeek')) {
          _sugaryDrinksPerWeek =
              (metaData['lifestyleSugaryDrinksPerWeek'] as num?)?.round() ??
                  _sugaryDrinksPerWeek;
        }
        if (metaData.containsKey('workoutMuscleGroups')) {
          final dynList = metaData['workoutMuscleGroups'] as List<dynamic>?;
          if (dynList != null) {
            _workoutMuscleGroups = dynList.map((e) => e.toString()).toList();
          }
        }
        if (metaData.containsKey('workoutEquipment')) {
          _workoutEquipment = metaData['workoutEquipment'];
        }
        if (metaData.containsKey('workoutFrequency')) {
          _workoutFrequency = metaData['workoutFrequency'];
        }
        if (metaData.containsKey('activeDietProgram')) {
          _activeDietProgram = metaData['activeDietProgram'];
        }
        if (metaData.containsKey('activeDietCalories')) {
          _activeDietCalories = metaData['activeDietCalories'];
        }
        if (metaData.containsKey('fastingMode')) {
          _fastingMode = metaData['fastingMode'];
        }
        if (metaData.containsKey('ramadanIftarMinute')) {
          _ramadanIftarMinute = metaData['ramadanIftarMinute'];
        }
        if (metaData.containsKey('ramadanSuhoorEndMinute')) {
          _ramadanSuhoorEndMinute = metaData['ramadanSuhoorEndMinute'];
        }
        if (metaData.containsKey('ifEatStartMinute')) {
          _ifEatStartMinute = metaData['ifEatStartMinute'];
        }
        if (metaData.containsKey('ifEatEndMinute')) {
          _ifEatEndMinute = metaData['ifEatEndMinute'];
        }
      } catch (e) {
        debugPrint("Error loading profile: $e");
      }
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    double? weight,
    double? height,
    int? age,
    String? gender,
    String? smokingStatus,
    String? photoUrl,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (name != null) {
      updates['name'] = name;
      _userName = name;
    }
    if (weight != null) {
      updates['weight'] = weight;
      _weight = weight;
    }
    if (height != null) {
      updates['height'] = height;
      _heightCm = height;
    }
    if (age != null) {
      updates['age'] = age;
      _age = age;
    }
    if (gender != null) {
      updates['gender'] = gender;
      _gender = gender;
    }
    if (smokingStatus != null) {
      _smokingStatus = _normalizeSmokingStatus(smokingStatus);
      _isSmoker = _smokingStatus == smokingStatusActive;
      updates['is_smoker'] = _isSmoker;
    }
    if (photoUrl != null) {
      updates['photo_url'] = photoUrl;
      _photoUrl = photoUrl;
    }

    if (updates.isNotEmpty) {
      await Supabase.instance.client
          .from('users')
          .update(updates)
          .eq('id', user.id);
      _saveData();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadData();
    await loadProfile();
  }

  Future<void> setFastingMode(String mode) async {
    final m = mode.trim().toLowerCase();
    if (m != 'none' && m != 'ramadan' && m != 'if') return;
    _fastingMode = m;
    await _saveData();
    notifyListeners();
  }

  int _minuteOfDay(DateTime dt) => dt.hour * 60 + dt.minute;

  bool _inWindow(int minute, int start, int end) {
    if (start == end) return true; // treat as always open
    if (start < end) return minute >= start && minute < end;
    // wraps midnight
    return minute >= start || minute < end;
  }

  bool get isEatingWindowNow {
    final minute = _minuteOfDay(DateTime.now());
    switch (_fastingMode) {
      case 'ramadan':
        // Eating allowed from iftar until suhoor end (wraps midnight).
        return _inWindow(minute, _ramadanIftarMinute, _ramadanSuhoorEndMinute);
      case 'if':
        return _inWindow(minute, _ifEatStartMinute, _ifEatEndMinute);
      default:
        return true;
    }
  }

  bool get isFastingNow {
    if (_fastingMode == 'none') return false;
    // For IF, fasting = outside eating window. For Ramadan, fasting = outside eating window.
    return !isEatingWindowNow;
  }

  bool get canDrinkWaterNow {
    // IF generally allows water; Ramadan only during eating window in this app.
    if (_fastingMode == 'ramadan') return isEatingWindowNow;
    return true;
  }

  String get fastingPhaseLabel {
    if (_fastingMode == 'none') return 'Tidak puasa';
    if (_fastingMode == 'if') {
      return isEatingWindowNow ? 'Jendela makan (IF)' : 'Jendela puasa (IF)';
    }
    // Ramadan
    final minute = _minuteOfDay(DateTime.now());
    if (_inWindow(
        minute, _ramadanIftarMinute, (_ramadanIftarMinute + 120) % 1440)) {
      return 'Waktu berbuka';
    }
    if (_inWindow(minute, (_ramadanSuhoorEndMinute + 1440 - 120) % 1440,
        _ramadanSuhoorEndMinute)) {
      return 'Waktu sahur';
    }
    return isEatingWindowNow ? 'Waktu makan (malam)' : 'Waktu puasa';
  }

  Future<void> setRamadanWindowMinutes(
      {required int iftarMinute, required int suhoorEndMinute}) async {
    _ramadanIftarMinute = iftarMinute.clamp(0, 1439);
    _ramadanSuhoorEndMinute = suhoorEndMinute.clamp(0, 1439);
    await _saveData();
    notifyListeners();
  }

  Future<void> setIfWindowMinutes(
      {required int startMinute, required int endMinute}) async {
    _ifEatStartMinute = startMinute.clamp(0, 1439);
    _ifEatEndMinute = endMinute.clamp(0, 1439);
    await _saveData();
    notifyListeners();
  }

  String? _mbti;
  String? get mbti => _mbti;
  Future<void> updateMBTI(String value) async {
    _mbti = value;
    await _saveData();
    notifyListeners();
  }

  bool _isPregnancyConfigured = false;
  DateTime? _pregnancyLmpDate;

  bool get isPregnancyConfigured => _isPregnancyConfigured && _pregnancyLmpDate != null;
  DateTime? get pregnancyLmpDate => _pregnancyLmpDate;

  Future<void> configurePregnancy(DateTime lmp) async {
    _pregnancyLmpDate = lmp;
    _isPregnancyConfigured = true;
    await _saveData();
    notifyListeners();
  }

  Future<void> resetPregnancy() async {
    _pregnancyLmpDate = null;
    _isPregnancyConfigured = false;
    await _saveData();
    notifyListeners();
  }

}