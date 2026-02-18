import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../image/image_url_cache.dart';
import 'biota_info_sheet.dart';

class BiotaFavoritePage extends StatefulWidget {
  const BiotaFavoritePage({super.key});

  @override
  State<BiotaFavoritePage> createState() => _BiotaFavoritePageState();
}

class _BiotaFavoritePageState extends State<BiotaFavoritePage> {
  final supabase = Supabase.instance.client;

  // ==== CONFIG & STYLE (Konsisten dengan News & Biota List) ====
  static const String _bucket = 'aquaverse';
  static const String _realFolder = 'biota_real';
  static const Color _headerBlue = Color.fromRGBO(148, 214, 245, 1);
  static const Color _titleNavy = Color.fromRGBO(63, 68, 102, 1);

  List<Map<String, dynamic>> _favoriteItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Query join ke table biota
      final res = await supabase
          .from('favorit')
          .select(
            'biota_id, biota(id, nama, nama_latin, image_path, depth_meters, kategori(nama))',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _favoriteItems = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Load favorites error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _getThumbUrl(Map<String, dynamic> biotaRow) {
    final rawPath = (biotaRow['image_path'] ?? '').toString().trim();
    if (rawPath.isEmpty) return null;
    final filename = rawPath.split('/').last;
    return ImageUrlCache.publicUrl(
      bucket: _bucket,
      path: '$_realFolder/$filename',
    );
  }

  @override
  Widget build(BuildContext context) {
    final aquaVerseLogoUrl = supabase.storage
        .from('aquaverse')
        .getPublicUrl('assets/images/logo/Logo-AquaVerse.png');

    final favoriteTextLogoUrl = supabase.storage
        .from('aquaverse')
        .getPublicUrl('assets/images/fav/Text-AquaVerseFavorit.png');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              padding: const EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                color: _headerBlue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Image.network(
                      aquaVerseLogoUrl,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Image.network(
                      favoriteTextLogoUrl,
                      height: 35,
                      width: 230,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _favoriteItems.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _favoriteItems.length,
                      itemBuilder: (context, index) {
                        final biota = _favoriteItems[index]['biota'];
                        return _FavoriteGridTile(
                          biota: biota,
                          imageUrl: _getThumbUrl(biota),
                          onTap: () => BiotaInfoSheet.show(
                            context,
                            biotaId: biota['id'],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Kembali'),
        backgroundColor: const Color.fromRGBO(30, 134, 185, 1),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Belum ada biota favorit",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteGridTile extends StatelessWidget {
  final Map<String, dynamic> biota;
  final String? imageUrl;
  final VoidCallback onTap;

  const _FavoriteGridTile({
    required this.biota,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String nama = (biota['nama'] ?? '-').toString();
    final String kategori = (biota['kategori']?['nama'] ?? 'UMUM')
        .toString()
        .toUpperCase();

    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      // ✅ KUNCI WARNA PUTIH BERSIH: Matikan rona ungu Material 3
      surfaceTintColor: Colors.transparent,
      // ✅ SHADOW HALUS: Mengikuti gaya news_page
      shadowColor: Colors.blue.withOpacity(0.1),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        cacheWidth: 300,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kategori,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color.fromRGBO(63, 68, 102, 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
