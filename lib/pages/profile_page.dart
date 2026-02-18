// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'terms_page.dart';
import 'edit_profile.dart';
import 'biota_favorite_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;

  static const baseColor = Color.fromRGBO(30, 134, 185, 1);

  static const _homeBannerUrl =
      "https://ccuigpzseuhwietjcyyi.supabase.co/storage/v1/object/public/aquaverse/assets/images/home/Banner-no-logo.jpg";

  late final Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final userId = supabase.auth.currentUser!.id;

    final profileRes = await supabase
        .from('profiles')
        .select('''
          username,
          name,
          user_rank (
            points, 
            ranks (
              id,
              name,
              image_url
            )
          )
        ''')
        .eq('id', userId)
        .single();

    // ✅ quiz attempts count (compatible semua versi supabase_flutter)
    final attempts = await supabase
        .from('quiz_attempts')
        .select('id')
        .eq('user_id', userId);

    final quizCount = (attempts as List).length;

    return {'profile': profileRes, 'quizCount': quizCount};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFFFFFF),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Gagal memuat profil"));
          }

          final data = snapshot.data!;
          final userData = data['profile'] as Map<String, dynamic>;

          final name = (userData['username'] ?? 'Diver').toString();

          final userRank = userData['user_rank'] as Map<String, dynamic>?;
          final points = (userRank?['points'] as int?) ?? 0;

          final rankData = userRank?['ranks'] as Map<String, dynamic>?;
          final rankName = (rankData?['name'] ?? 'DIVER').toString();
          final imageFile = (rankData?['image_url'] ?? '').toString();

          final badgeUrl = supabase.storage
              .from('aquaverse')
              .getPublicUrl('assets/images/ranks/$imageFile');

          final quizCount = data['quizCount'] as int? ?? 0;

          return Stack(
            children: [
              Positioned.fill(child: Container(color: const Color(0xFFFFFFFF))),

              SafeArea(
                top: false,
                bottom: false,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== HEADER: SAMA UKURAN & FEEL KAYAK HOMEPAGE =====
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(35),
                            bottomRight: Radius.circular(-35),
                          ),
                          image: DecorationImage(
                            image: const NetworkImage(_homeBannerUrl),
                            fit: BoxFit.cover,
                            opacity: 0.75,
                            colorFilter: ColorFilter.mode(
                              const Color.fromARGB(
                                255,
                                75,
                                172,
                                251,
                              ).withOpacity(0.5),
                              BlendMode.srcOver,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 4),

                            const Text(
                              'Profil Penjelajah',
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Badge (circle)
                            Container(
                              width: 108,
                              height: 108,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    offset: const Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  badgeUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.emoji_events),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: "Montserrat",
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9D9FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.scuba_diving, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        rankName.toUpperCase(),
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ===== BODY CONTENT (match prototype) =====
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Statistik & Aktivitas',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color.fromRGBO(63, 68, 102, 1),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(height: 1, color: Colors.black12),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _StatPill(
                                    icon: Icons.monetization_on,
                                    iconColor: const Color(0xFFF5B800),
                                    value: '$points',
                                    label: 'Total Poin (Coins)',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _StatPill(
                                    icon: Icons.quiz,
                                    iconColor: baseColor,
                                    value: '$quizCount',
                                    label: 'Jumlah Quiz',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            _OutlineTile(
                              icon: Icons.favorite_border,
                              iconColor: Colors.redAccent,
                              title: 'Biota Favorit',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BiotaFavoritePage(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              'Pengaturan Akun',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color.fromRGBO(63, 68, 102, 1),
                              ),
                            ),
                            const SizedBox(height: 12),

                            _OutlineTile(
                              icon: Icons.person_outline,
                              title: 'Edit Profile & Akun',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfilePage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            _OutlineTile(
                              icon: Icons.help_outline,
                              title: 'Terms and Service',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TermsPage(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await supabase.auth.signOut();
                                  if (!context.mounted) return;

                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD76800),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromARGB(255, 191, 232, 247)),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: iconColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black45,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final VoidCallback onTap;

  const _OutlineTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color.fromARGB(255, 191, 232, 247)),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 6),
                color: Colors.black.withOpacity(0.06),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? Colors.black54),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
