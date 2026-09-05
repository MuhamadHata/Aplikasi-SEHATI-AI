import 'package:flutter/material.dart';
import '../inti/model/model_latihan.dart';
import '../../inti/tema/design_tokens.dart';
import '../inti/layanan/layanan_api_latihan.dart';
import '../komponen/kartu_latihan.dart';

class ExerciseDirectoryScreen extends StatefulWidget {
  const ExerciseDirectoryScreen({super.key});

  @override
  State<ExerciseDirectoryScreen> createState() =>
      _ExerciseDirectoryScreenState();
}

class _ExerciseDirectoryScreenState extends State<ExerciseDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<ExerciseModel> _exercises = [];
  List<String> _bodyParts = [];
  String _selectedBodyPart = 'all';

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch body parts for the filter chips
      final parts = await ExerciseApiService.fetchBodyPartList();

      // Fetch initial exercises (all)
      final exercises = await ExerciseApiService.fetchExercises(limit: 50);

      if (mounted) {
        setState(() {
          _bodyParts = ['all', ...parts];
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat data: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _filterByBodyPart(String part) async {
    setState(() {
      _selectedBodyPart = part;
      _isLoading = true;
      _errorMessage = null;
      _searchController.clear(); // Clear search when switching categories
    });

    try {
      List<ExerciseModel> results;
      if (part == 'all') {
        results = await ExerciseApiService.fetchExercises(limit: 50);
      } else {
        results =
            await ExerciseApiService.fetchExercisesByBodyPart(part, limit: 50);
      }

      if (mounted) {
        setState(() {
          _exercises = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memfilter: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchExercises(String query) async {
    if (query.isEmpty) {
      _filterByBodyPart('all');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedBodyPart = ''; // deselect category
    });

    try {
      final results = await ExerciseApiService.fetchExercisesByName(
          query.toLowerCase(),
          limit: 50);
      if (mounted) {
        setState(() {
          _exercises = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Tidak ditemukan atau error: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  void _showExerciseDetail(ExerciseModel exercise) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exercise.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // GIF Image
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    exercise.gifUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chips (Target, Body Part, Equipment)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(exercise.bodyPart),
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold),
                    side: BorderSide.none,
                  ),
                  Chip(
                    label: Text(exercise.target),
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold),
                    side: BorderSide.none,
                  ),
                  Chip(
                    label: Text(exercise.equipment),
                    backgroundColor: Colors.purple.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                        color: Colors.purple, fontWeight: FontWeight.bold),
                    side: BorderSide.none,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'INSTRUKSI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  itemCount: exercise.instructions.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            exercise.instructions[i],
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kamus Latihan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            fontSize: 21,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari latihan...',
                prefixIcon: Icon(Icons.search, color: theme.hintColor),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: theme.hintColor),
                  onPressed: () {
                    _searchController.clear();
                    _filterByBodyPart('all');
                  },
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: _searchExercises,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),

          // Filters
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _bodyParts.length,
              itemBuilder: (context, index) {
                final part = _bodyParts[index];
                final isSelected = _selectedBodyPart == part;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      part.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.hintColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surface,
                    onSelected: (selected) {
                      if (selected) {
                        _filterByBodyPart(part);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Main Content Area
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: theme.colorScheme.primary))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _exercises.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada latihan ditemukan.',
                              style: TextStyle(color: theme.hintColor),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _exercises.length,
                            itemBuilder: (context, index) {
                              final ex = _exercises[index];
                              return ExerciseCard(
                                exercise: ex,
                                onTap: () => _showExerciseDetail(ex),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
