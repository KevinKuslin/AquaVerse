// lib/biota_info_sheet.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BiotaInfoSheet extends StatefulWidget {
  final int biotaId;

  const BiotaInfoSheet({super.key, required this.biotaId});

  static Future<void> show(BuildContext context, {required int biotaId}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => BiotaInfoSheet(biotaId: biotaId),
    );
  }

  @override
  State<BiotaInfoSheet> createState() => _BiotaInfoSheetState();
}

class _BiotaInfoSheetState extends State<BiotaInfoSheet> {
  final _supabase = Supabase.instance.client;

  // bucket kamu
  static const String _bucket = 'aquaverse';

  // folder sprite & real di bucket (sesuai screenshot)
  static const String _spriteFolder = 'biota';
  static const String _realFolder = 'biota_real';

  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDetail();
  }

  Future<Map<String, dynamic>> _loadDetail() async {
    final res = await _supabase
        .from('biota')
        .select('''
          id,
          nama,
          nama_latin,
          deskripsi,
          habitat,
          status_konservasi,
          fakta_unik,
          depth_meters,
          image_path,
          kategori(nama)
        ''')
        .eq('id', widget.biotaId)
        .single();

    return Map<String, dynamic>.from(res);
  }

  void _reload() {
    setState(() {
      _future = _loadDetail();
    });
  }

  String? _publicUrl(String? storagePath) {
    if (storagePath == null) return null;
    final p = storagePath.trim();
    if (p.isEmpty) return null;
    return _supabase.storage.from(_bucket).getPublicUrl(p);
  }

  /// dari "biota/blue_tang.png" => "biota_real/blue_tang.png"
  String? _toRealPathFromSpritePath(String? spritePath) {
    if (spritePath == null) return null;
    final p = spritePath.trim();
    if (p.isEmpty) return null;

    // ambil filename terakhir aja
    final fileName = p.split('/').last;
    if (fileName.isEmpty) return null;

    return '$_realFolder/$fileName';
  }

  /// Pastikan kalau user isi image_path cuma "clownfish.png" (tanpa folder),
  /// tetap kita handle jadi "biota/clownfish.png"
  String? _normalizeSpritePath(String? raw) {
    if (raw == null) return null;
    final p = raw.trim();
    if (p.isEmpty) return null;

    // kalau sudah ada folder, pakai apa adanya
    if (p.contains('/')) return p;

    // kalau cuma filename, anggap sprite folder
    return '$_spriteFolder/$p';
  }

  String _formatMeters(dynamic v) {
    final d = double.tryParse(v.toString());
    if (d == null) return '${v}m';
    if (d % 1 == 0) return '${d.toInt()}m';
    return '${d.toStringAsFixed(1)}m';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _SheetShell(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snap.hasError) {
          return _SheetShell(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Gagal memuat data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snap.error.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        final b = snap.data!;

        final nama = (b['nama'] ?? '-').toString();
        final latin = (b['nama_latin'] ?? '').toString();
        final deskripsi = (b['deskripsi'] ?? '').toString();
        final habitat = (b['habitat'] ?? '').toString();
        final status = (b['status_konservasi'] ?? '').toString();
        final fakta = (b['fakta_unik'] ?? '').toString();

        final kategoriNama = (b['kategori']?['nama'] ?? '').toString();

        final depth = b['depth_meters'];
        final depthText = depth == null ? '-' : _formatMeters(depth);

        // ====== LOGIC URL GAMBAR SESUAI FOLDER KAMU ======
        final spritePath = _normalizeSpritePath(b['image_path']?.toString());
        final realPath = _toRealPathFromSpritePath(spritePath);

        // kita coba real dulu, kalau null ya sprite
        final realUrl = _publicUrl(realPath);
        final spriteUrl = _publicUrl(spritePath);

        return _SheetShell(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SmartThumb(
                        primaryUrl: realUrl, // foto asli
                        fallbackUrl: spriteUrl, // sprite fallback
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (latin.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                latin,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _ChipPill(
                                  icon: Icons.waves,
                                  label: depthText == '-'
                                      ? 'Kedalaman -'
                                      : depthText,
                                ),
                                if (kategoriNama.isNotEmpty)
                                  _ChipPill(
                                    icon: Icons.category_rounded,
                                    label: kategoriNama,
                                  ),
                                if (status.isNotEmpty)
                                  _ChipPill(
                                    icon: Icons.shield_rounded,
                                    label: status,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _reload,
                        tooltip: 'Refresh',
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (habitat.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Habitat',
                      icon: Icons.place_rounded,
                      child: Text(
                        habitat,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  _SectionCard(
                    title: 'Deskripsi',
                    icon: Icons.menu_book_rounded,
                    child: _ExpandableText(
                      text: deskripsi.isEmpty
                          ? 'Belum ada deskripsi.'
                          : deskripsi,
                      trimLines: 4,
                    ),
                  ),

                  if (fakta.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _SectionCard(
                      title: 'Fakta unik',
                      icon: Icons.auto_awesome_rounded,
                      child: Text(
                        fakta,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Tutup'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: buat detail page nanti
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.info_outline_rounded),
                          label: const Text('Detail'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thumb yang coba load primary (real) dulu, kalau error -> fallback (sprite).
class _SmartThumb extends StatefulWidget {
  final String? primaryUrl;
  final String? fallbackUrl;

  const _SmartThumb({required this.primaryUrl, required this.fallbackUrl});

  @override
  State<_SmartThumb> createState() => _SmartThumbState();
}

class _SmartThumbState extends State<_SmartThumb> {
  bool _useFallback = false;

  @override
  void didUpdateWidget(covariant _SmartThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    // kalau id biota berubah / url berubah, reset state
    if (oldWidget.primaryUrl != widget.primaryUrl ||
        oldWidget.fallbackUrl != widget.fallbackUrl) {
      _useFallback = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _useFallback ? widget.fallbackUrl : widget.primaryUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 84,
        height: 84,
        color: Colors.black.withOpacity(0.06),
        child: (url == null)
            ? const Center(child: Icon(Icons.image, size: 26))
            : Image.network(
                url,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.none,

                // ✅ decode sesuai ukuran thumbnail (mis. 80–120px)
                cacheWidth: 240, // coba 200-300
                cacheHeight: 240,

                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image)),
              )
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final Widget child;
  const _SheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChipPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;

  const _ExpandableText({required this.text, this.trimLines = 4});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(fontSize: 14, height: 1.45);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.trimLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final overflow = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : widget.trimLines,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (overflow) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    _expanded ? 'Tutup' : 'Baca selengkapnya',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
