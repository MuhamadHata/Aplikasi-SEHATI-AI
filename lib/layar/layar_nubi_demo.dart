import 'package:flutter/material.dart';
import '../widget/nubi_mascot.dart';

// ============================================================
// NUBI MASCOT DEMO SCREEN
// Tampilan galeri semua pose Nubi dengan animasi
// ============================================================

class NubiDemoScreen extends StatefulWidget {
  const NubiDemoScreen({super.key});

  @override
  State<NubiDemoScreen> createState() => _NubiDemoScreenState();
}

class _NubiDemoScreenState extends State<NubiDemoScreen> {
  NubiPose? _selectedPose;

  final Map<NubiPose, _PoseInfo> _poseInfoMap = {
    NubiPose.meditate: _PoseInfo(
      label: 'Meditasi',
      icon: Icons.self_improvement_rounded,
      description: 'Tenangkan pikiran\ndan jiwa',
      color: const Color(0xFF7FFFD4),
      bgColor: const Color(0xFFE8FFF8),
    ),
    NubiPose.run: _PoseInfo(
      label: 'Berlari',
      icon: Icons.directions_run_rounded,
      description: 'Yuk olahraga\nsetiap hari!',
      color: const Color(0xFFFFD700),
      bgColor: const Color(0xFFFFFDE8),
    ),
    NubiPose.sleep: _PoseInfo(
      label: 'Tidur',
      icon: Icons.bedtime_rounded,
      description: 'Tidur cukup\nuntuk kesehatan',
      color: const Color(0xFF87CEEB),
      bgColor: const Color(0xFFE8F4FF),
    ),
    NubiPose.study: _PoseInfo(
      label: 'Belajar',
      icon: Icons.menu_book_rounded,
      description: 'Pelajari kebiasaan\nhidup sehat',
      color: const Color(0xFFFFA500),
      bgColor: const Color(0xFFFFF4E8),
    ),
    NubiPose.success: _PoseInfo(
      label: 'Sukses',
      icon: Icons.emoji_events_rounded,
      description: 'Target kesehatan\ntercapai!',
      color: const Color(0xFFFFD700),
      bgColor: const Color(0xFFFFFAE8),
    ),
    NubiPose.wave: _PoseInfo(
      label: 'Halo!',
      icon: Icons.health_and_safety_rounded,
      description: 'Selamat datang\ndi SEHATI!',
      color: const Color(0xFF98FB98),
      bgColor: const Color(0xFFEEFFEE),
    ),
    NubiPose.doctor: _PoseInfo(
      label: 'Dokter',
      icon: Icons.health_and_safety_rounded,
      description: 'Konsultasi\nkesehatan',
      color: const Color(0xFFFF6B6B),
      bgColor: const Color(0xFFFFEEEE),
    ),
    NubiPose.drink: _PoseInfo(
      label: 'Minum Air',
      icon: Icons.water_drop_rounded,
      description: 'Cukupi asupan\nair harianmu',
      color: const Color(0xFF87CEEB),
      bgColor: const Color(0xFFE8F8FF),
    ),
    NubiPose.eat: _PoseInfo(
      label: 'Makan Sehat',
      icon: Icons.eco_rounded,
      description: 'Konsumsi buah\ndan sayuran',
      color: const Color(0xFFFF8C69),
      bgColor: const Color(0xFFFFF0EC),
    ),
    NubiPose.fit: _PoseInfo(
      label: 'Fitness',
      icon: Icons.fitness_center_rounded,
      description: 'Jaga kebugaran\ntubuhmu',
      color: const Color(0xFF90EE90),
      bgColor: const Color(0xFFEEFFEE),
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (_selectedPose != null) {
      return _buildDetailView();
    }
    return _buildGalleryView();
  }

  Widget _buildGalleryView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7FFFD4).withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🌿', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nubi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D7A5F),
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Maskot SEHATI-AI',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Pilih pose untuk melihat animasi',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.88,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: NubiPose.values.length,
              itemBuilder: (context, index) {
                final pose = NubiPose.values[index];
                final info = _poseInfoMap[pose]!;
                return _NubiPoseCard(
                  pose: pose,
                  info: info,
                  onTap: () => setState(() => _selectedPose = pose),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    final pose = _selectedPose!;
    final info = _poseInfoMap[pose]!;

    return Scaffold(
      backgroundColor: info.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: info.color),
          ),
          onPressed: () => setState(() => _selectedPose = null),
        ),
        title: Text(
          '${info.icon} ${info.label}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.lerp(info.color, Colors.black, 0.4),
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main animated mascot
          Center(
            child: NubiMascot(
              pose: pose,
              size: 220,
              autoPlay: true,
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: info.color.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    info.icon,
                    size: 40, color: info.color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info.label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.lerp(info.color, Colors.black, 0.35),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AnimationBadge(color: info.color, pose: pose),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Navigate between poses
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                color: info.color,
                onTap: () {
                  final idx = NubiPose.values.indexOf(pose);
                  setState(() {
                    _selectedPose = NubiPose.values[
                        (idx - 1 + NubiPose.values.length) %
                            NubiPose.values.length];
                  });
                },
              ),
              const SizedBox(width: 16),
              // Dot indicators
              ...NubiPose.values.map((p) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: p == pose ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: p == pose ? info.color : Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
              const SizedBox(width: 16),
              _NavButton(
                icon: Icons.chevron_right,
                color: info.color,
                onTap: () {
                  final idx = NubiPose.values.indexOf(pose);
                  setState(() {
                    _selectedPose =
                        NubiPose.values[(idx + 1) % NubiPose.values.length];
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPER WIDGETS
// ============================================================

class _PoseInfo {
  final String label;
  final IconData icon;
  final String description;
  final Color color;
  final Color bgColor;
  const _PoseInfo({
    required this.label,
    required this.icon,
    required this.description,
    required this.color,
    required this.bgColor,
  });
}

class _NubiPoseCard extends StatelessWidget {
  final NubiPose pose;
  final _PoseInfo info;
  final VoidCallback onTap;

  const _NubiPoseCard({
    required this.pose,
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: info.bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: info.color.withOpacity(0.12),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: info.color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated mascot preview
            NubiMascot(
              pose: pose,
              size: 100,
              autoPlay: true,
            ),
            const SizedBox(height: 4),
            Icon(info.icon, size: 16, color: info.color,
            ),
            const SizedBox(height: 2),
            Text(
              info.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color.lerp(info.color, Colors.black, 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimationBadge extends StatelessWidget {
  final Color color;
  final NubiPose pose;
  const _AnimationBadge({required this.color, required this.pose});

  String get _animDesc {
    switch (pose) {
      case NubiPose.meditate:
        return 'Float • Glow Pulse • Orbit Particles';
      case NubiPose.run:
        return 'Bounce • Tilt • Sparkles';
      case NubiPose.sleep:
        return 'Gentle Rock • ZZZ Float';
      case NubiPose.study:
        return 'Soft Bob • Star Pulse';
      case NubiPose.success:
        return 'Scale Bounce • Confetti';
      case NubiPose.wave:
        return 'Swing • Diamond Sparkles';
      case NubiPose.doctor:
        return 'Float • Heartbeat ECG';
      case NubiPose.drink:
        return 'Tilt • Water Droplets';
      case NubiPose.eat:
        return 'Bite Bob • Food Shine';
      case NubiPose.fit:
        return 'Curl Up-Down • Energy Burst';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _animDesc,
              style: TextStyle(
                fontSize: 10,
                color: Color.lerp(color, Colors.black, 0.35),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NavButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
