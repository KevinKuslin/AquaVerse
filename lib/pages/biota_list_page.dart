import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dive_page.dart';
import 'biota_info_sheet.dart';

final supabase = Supabase.instance.client;

class BiotaListPage extends StatefulWidget {
  const BiotaListPage({super.key});

  @override
  State<BiotaListPage> createState() => _BiotaListPageState();
}

class _BiotaListPageState extends State<BiotaListPage> {
  // ==== STORAGE CONFIG ====
  static const String _bucket = 'aquaverse';
  static const String _realFolder = 'biota_real';

  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  // ✅ Scroll controller biar scrollbar “nempel” (wajib)
  final ScrollController _listCtrl = ScrollController();
  final ScrollController _chipCtrl = ScrollController();

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _kategori = [];

  bool _loading = true;
  String? _error;

  int? _selectedKategoriId;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _init();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _listCtrl.dispose();
    _chipCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final text = _searchCtrl.text.trim();
      if (text == _keyword) return;
      setState(() => _keyword = text);
      _loadBiota();
    });
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([_loadKategori(), _loadBiota()]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadKategori() async {
    final res = await supabase
        .from('kategori')
        .select('id,nama')
        .order('nama', ascending: true);

    _kategori = List<Map<String, dynamic>>.from(res);
    if (mounted) setState(() {});
  }

  Future<void> _loadBiota() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final builder = supabase
          .from('biota')
          .select(
            'id,nama,nama_latin,image_path,depth_meters,kategori_id,kategori(nama)',
          );

      dynamic q = builder;

      if (_selectedKategoriId != null) {
        q = q.eq('kategori_id', _selectedKategoriId);
      }

      if (_keyword.isNotEmpty) {
        q = q.or('nama.ilike.%$_keyword%,nama_latin.ilike.%$_keyword%');
      }

      final res = await q.order('depth_meters', ascending: true).limit(300);
      _items = List<Map<String, dynamic>>.from(res);

      // ✅ precache beberapa thumbnail pertama
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = context;
        for (final b in _items.take(10)) {
          final url = _thumbUrlFromRow(b);
          if (url != null) precacheImage(NetworkImage(url), ctx);
        }
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fileNameFromImagePath(dynamic imagePath) {
    final raw = (imagePath ?? '').toString().trim();
    if (raw.isEmpty) return '';
    return raw.split('/').last;
  }

  String? _thumbUrlFromRow(Map<String, dynamic> b) {
    final filename = _fileNameFromImagePath(b['image_path']);
    if (filename.isEmpty) return null;
    final path = '$_realFolder/$filename';
    return ImageUrlCache.publicUrl(bucket: _bucket, path: path);
  }

  void _openDetail(int biotaId) {
    BiotaInfoSheet.show(context, biotaId: biotaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biota Laut')),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari biota (nama / latin)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _keyword.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // Filter kategori (chip) + scrollbar horizontal
            SizedBox(
              height: 46,
              child: RawScrollbar(
                controller: _chipCtrl,
                thumbVisibility: true,
                thickness: 5,
                radius: const Radius.circular(999),
                child: ListView(
                  controller: _chipCtrl,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Semua'),
                        selected: _selectedKategoriId == null,
                        onSelected: (v) {
                          setState(() => _selectedKategoriId = null);
                          _loadBiota();
                        },
                      ),
                    ),
                    ..._kategori.map((k) {
                      final id = k['id'] as int;
                      final nama = (k['nama'] ?? '').toString();
                      final selected = _selectedKategoriId == id;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(nama),
                          selected: selected,
                          onSelected: (v) {
                            setState(() => _selectedKategoriId = v ? id : null);
                            _loadBiota();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ✅ Scrollbar kanan (vertical) untuk list
            Expanded(
              child: RawScrollbar(
                controller: _listCtrl,
                thumbVisibility: true, // always show
                thickness: 7,
                radius: const Radius.circular(999),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DivePage()),
          );
        },
        icon: const Icon(Icons.waves),
        label: const Text('Dive'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error:\n$_error', textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _init,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Data biota kosong.\nIsi dulu di Supabase (Table Editor / SQL).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _listCtrl, // ✅ ini yang bikin scrollbar muncul
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final b = _items[i];

        final id = (b['id'] as int?) ?? 0;
        final nama = (b['nama'] ?? '-').toString();
        final latin = (b['nama_latin'] ?? '').toString();
        final depth = b['depth_meters']?.toString() ?? '0';
        final kategoriNama = (b['kategori']?['nama'] ?? '').toString();

        final thumbUrl = _thumbUrlFromRow(b);

        return InkWell(
          onTap: () => _openDetail(id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: (thumbUrl == null)
                        ? Container(
                            color: Colors.black12,
                            child: const Icon(Icons.image, size: 28),
                          )
                        : Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.none,
                            cacheWidth: 240,
                            cacheHeight: 240,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.black12,
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.black12,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (latin.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            latin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Pill(text: '${depth}m'),
                            const SizedBox(width: 8),
                            if (kategoriNama.isNotEmpty)
                              _Pill(text: kategoriNama),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// =======================
/// GLOBAL URL CACHE (string URL saja)
/// =======================
class ImageUrlCache {
  ImageUrlCache._();

  static final Map<String, String> _cache = {};

  static String publicUrl({required String bucket, required String path}) {
    final key = '$bucket|$path';
    return _cache.putIfAbsent(
      key,
      () => Supabase.instance.client.storage.from(bucket).getPublicUrl(path),
    );
  }

  static void clear() => _cache.clear();
}
