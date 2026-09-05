import 'package:flutter/material.dart';

class LayarTentang extends StatelessWidget {
  const LayarTentang({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // ─── Logo BRIN & UPI ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // BRIN Logo
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo_brin.png',
                            height: 64,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/logo BRIN.png',
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'BRIN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                    // UPI Logo
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo_upi.png',
                            height: 64,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/logo UPI.png',
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'UPI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ─── Legal Protection & Names Card ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Shield Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF0EA5E9),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Copyright & Patent Statement (exact user wording)
                    Text(
                      'Aplikasi SEHATI-AI ini dilindungi dengan Hak Cipta No. EC002026070020 dan Paten No. P00202604896',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0F172A),
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 24),
                    Divider(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      thickness: 1.5,
                    ),
                    const SizedBox(height: 20),

                    // Names directly listed (NO subtitle per user request)
                    _InventorNameRow(
                      name: 'Prof. Risnandar, Ph.D.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _InventorNameRow(
                      name: 'Muhamad Hata',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _InventorNameRow(
                      name: 'Dr. Eng. Munawir S.Kom., M.T.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ─── Institutional Collaboration Footnote ─────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.35)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      size: 18,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Kolaborasi Riset BRIN & Universitas Pendidikan Indonesia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventorNameRow extends StatelessWidget {
  final String name;
  final bool isDark;

  const _InventorNameRow({
    required this.name,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
