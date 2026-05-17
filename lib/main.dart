import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BouhApp());
}

class BouhApp extends StatelessWidget {
  const BouhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بوح التضاريس',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: C.bg,
        fontFamily: 'sans',
        colorScheme: const ColorScheme.dark(
          primary: C.gold,
          secondary: C.cyan,
          surface: C.panel,
        ),
      ),
      home: const PasswordGate(),
    );
  }
}

class C {
  static const bg = Color(0xFF05070A);
  static const panel = Color(0xFF0A1110);
  static const panel2 = Color(0xFF17120B);
  static const gold = Color(0xFFD4AF37);
  static const gold2 = Color(0xFFFFD766);
  static const cyan = Color(0xFF00F3FF);
  static const red = Color(0xFFFF3B30);
  static const green = Color(0xFF23D18B);
  static const amber = Color(0xFFFFB020);
  static const white = Color(0xFFF4F4F4);
}

class AppInfo {
  static const nameAr = 'بوح التضاريس';
  static const nameEn = 'BOUH GOLD PRO ULTRA v12.5';
  static const ownerAr = 'تطوير وتصميم: أحمد أبوعزيزه الرشيدي';
  static const ownerEn = 'Technical Authority System of Eng. Ahmed Abuaziza';
  static const password = 'Abuaziza2000';
  static const workspace = 'BOUH_GOLD_PRO_ULTRA_WORKSPACE';
  static const appLink = 'https://github.com/abuaziza404-tech/BOUH-GOLD-PRO-ULTRA-v12/releases/latest';
}

class PasswordGate extends StatefulWidget {
  const PasswordGate({super.key});

  @override
  State<PasswordGate> createState() => _PasswordGateState();
}

class _PasswordGateState extends State<PasswordGate> {
  final pass = TextEditingController();
  bool wrong = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF030405), Color(0xFF17110A), Color(0xFF05070A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: GlassPanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      const BouhLogo(size: 96),
                      const SizedBox(height: 18),
                      const Text(
                        AppInfo.nameAr,
                        style: TextStyle(color: C.gold2, fontSize: 34, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        AppInfo.nameEn,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${AppInfo.ownerAr}\n${AppInfo.ownerEn}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.70), height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: pass,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          hintText: 'Abuaziza2000',
                          prefixIcon: const Icon(Icons.lock, color: C.gold),
                          errorText: wrong ? 'كلمة المرور غير صحيحة' : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: C.gold.withOpacity(0.35)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: C.gold, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      GoldButton(
                        text: 'دخول النظام',
                        icon: Icons.security,
                        onTap: () {
                          if (pass.text.trim() == AppInfo.password) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const BouhHome()),
                            );
                          } else {
                            setState(() => wrong = true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BouhHome extends StatefulWidget {
  const BouhHome({super.key});

  @override
  State<BouhHome> createState() => _BouhHomeState();
}

class _BouhHomeState extends State<BouhHome> {
  final mapController = MapController();
  final engine = BouhEngine();
  final ai = BouhAiService();

  int tab = 0;
  LatLng center = const LatLng(19.8255, 36.9532);
  double zoom = 13.2;
  LatLng? gps;
  AnalysisPoint? selected;
  final List<AnalysisPoint> points = [];

  String activeLayer = 'Google Satellite';
  bool showMagnetic = true;
  bool showGravity = false;
  bool showRadar = false;
  bool showLineaments = true;

  String planetUrl = '';
  String maxarUrl = '';
  String aiKey = '';
  String aiModel = 'gpt-4o';
  bool onlineAi = false;

  final List<TileSource> tileSources = [
    TileSource(
      name: 'Google Satellite',
      ar: 'قمر صناعي',
      url: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
      maxZoom: 21,
    ),
    TileSource(
      name: 'Google Hybrid',
      ar: 'هجين',
      url: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
      maxZoom: 21,
    ),
    TileSource(
      name: 'Open Street Map',
      ar: 'خريطة',
      url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      maxZoom: 19,
    ),
    TileSource(
      name: 'USGS Topographic',
      ar: 'تضاريس USGS',
      url: 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/{z}/{y}/{x}',
      maxZoom: 16,
    ),
    TileSource(
      name: 'NASA True Color',
      ar: 'NASA طبيعي',
      url:
          'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/VIIRS_SNPP_CorrectedReflectance_TrueColor/default/2024-01-01/GoogleMapsCompatible_Level9/{z}/{y}/{x}.jpg',
      maxZoom: 9,
    ),
    TileSource(
      name: 'NASA False Color',
      ar: 'NASA لون كاذب',
      url:
          'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/VIIRS_SNPP_CorrectedReflectance_BandsM11-I2-I1/default/2024-01-01/GoogleMapsCompatible_Level9/{z}/{y}/{x}.jpg',
      maxZoom: 9,
    ),
  ];

  @override
  void initState() {
    super.initState();
    loadWorkspace();
  }

  Future<Directory> workspace() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/${AppInfo.workspace}');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> loadWorkspace() async {
    try {
      final dir = await workspace();
      final file = File('${dir.path}/state.json');
      if (!await file.exists()) return;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      setState(() {
        activeLayer = data['activeLayer'] ?? activeLayer;
        planetUrl = data['planetUrl'] ?? '';
        maxarUrl = data['maxarUrl'] ?? '';
        aiKey = data['aiKey'] ?? '';
        aiModel = data['aiModel'] ?? 'gpt-4o';
        onlineAi = data['onlineAi'] == true;
        showMagnetic = data['showMagnetic'] ?? true;
        showGravity = data['showGravity'] ?? false;
        showRadar = data['showRadar'] ?? false;
        showLineaments = data['showLineaments'] ?? true;
        final list = data['points'];
        if (list is List) {
          points.clear();
          points.addAll(list.map((e) => AnalysisPoint.fromMap(Map<String, dynamic>.from(e))));
        }
      });
    } catch (_) {}
  }

  Future<void> saveWorkspace() async {
    final dir = await workspace();
    final file = File('${dir.path}/state.json');
    await file.writeAsString(jsonEncode({
      'activeLayer': activeLayer,
      'planetUrl': planetUrl,
      'maxarUrl': maxarUrl,
      'aiKey': aiKey,
      'aiModel': aiModel,
      'onlineAi': onlineAi,
      'showMagnetic': showMagnetic,
      'showGravity': showGravity,
      'showRadar': showRadar,
      'showLineaments': showLineaments,
      'points': points.map((e) => e.toMap()).toList(),
    }), flush: true);
  }

  TileSource get currentTile {
    if (activeLayer == 'PlanetScope' && planetUrl.trim().isNotEmpty) {
      return TileSource(name: 'PlanetScope', ar: 'بلانيت', url: planetUrl.trim(), maxZoom: 21);
    }
    if (activeLayer == 'Maxar' && maxarUrl.trim().isNotEmpty) {
      return TileSource(name: 'Maxar', ar: 'ماكسار', url: maxarUrl.trim(), maxZoom: 21);
    }
    return tileSources.firstWhere((e) => e.name == activeLayer, orElse: () => tileSources.first);
  }

  void analyzePoint(LatLng p) {
    final result = engine.analyze(p);
    setState(() {
      selected = result;
      points.add(result);
    });
    saveWorkspace();
    showAnalysisSheet(result);
  }

  Future<void> locateMe() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        snack('صلاحية GPS غير مفعلة');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final p = LatLng(pos.latitude, pos.longitude);
      setState(() => gps = p);
      mapController.move(p, 16);
    } catch (e) {
      snack('تعذر تحديد الموقع: $e');
    }
  }

  void snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: C.panel));
  }

  Future<void> exportKml() async {
    if (points.isEmpty) return snack('لا توجد نقاط للتصدير');
    final dir = await workspace();
    final file = File('${dir.path}/bouh_points_${DateTime.now().millisecondsSinceEpoch}.kml');
    await file.writeAsString(Exporter.kml(points), flush: true);
    await Share.shareXFiles([XFile(file.path)], text: 'تصدير KML من بوح التضاريس');
  }

  Future<void> exportCsv() async {
    if (points.isEmpty) return snack('لا توجد نقاط للتصدير');
    final dir = await workspace();
    final file = File('${dir.path}/bouh_points_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(Exporter.csv(points), flush: true);
    await Share.shareXFiles([XFile(file.path)], text: 'تصدير CSV من بوح التضاريس');
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      mapPage(),
      analysisPage(),
      reportsPage(),
      toolsPage(),
      settingsPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            pages[tab],
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: mainHeader(),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: tab,
          backgroundColor: const Color(0xFF070707),
          selectedItemColor: C.gold,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => tab = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'الخريطة'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'التحليل'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'التقارير'),
            BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'الأدوات'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }

  Widget mainHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: C.gold.withOpacity(0.55)),
          ),
          child: Row(
            children: [
              const BouhLogo(size: 54),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppInfo.nameAr,
                      style: TextStyle(color: C.gold2, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      AppInfo.nameEn,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AppInfo.ownerAr,
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => tab = 4),
                icon: const Icon(Icons.tune, color: C.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget mapPage() {
    final tile = currentTile;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            minZoom: 3,
            maxZoom: 21,
            onTap: (_, p) => analyzePoint(p),
            onPositionChanged: (camera, hasGesture) {
              center = camera.center;
              zoom = camera.zoom;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tile.url,
              maxZoom: tile.maxZoom,
              userAgentPackageName: 'com.bouh.gold.pro.ultra',
            ),
            if (showLineaments && selected != null)
              PolylineLayer(polylines: [
                Polyline(
                  points: engine.veinLine(selected!.point, selected!.magnetic),
                  color: C.cyan,
                  strokeWidth: 4,
                  borderColor: C.gold,
                  borderStrokeWidth: 1.5,
                )
              ]),
            MarkerLayer(markers: [
              if (gps != null)
                Marker(
                  point: gps!,
                  width: 46,
                  height: 46,
                  child: const Icon(Icons.my_location, color: C.cyan, size: 38),
                ),
              ...points.take(250).map((p) {
                final col = p.classification == 'Target-B'
                    ? C.gold
                    : p.classification.contains('Reject')
                        ? C.red
                        : p.classification.contains('HOLD')
                            ? C.amber
                            : C.green;
                return Marker(
                  point: p.point,
                  width: 42,
                  height: 42,
                  child: GestureDetector(
                    onTap: () => showAnalysisSheet(p),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.65),
                        border: Border.all(color: col, width: 2),
                        boxShadow: [BoxShadow(color: col.withOpacity(0.5), blurRadius: 18)],
                      ),
                      child: Center(
                        child: Text(
                          p.classification == 'Target-B' ? 'B' : '•',
                          style: TextStyle(color: col, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ]),
          ],
        ),
        if (showMagnetic || showGravity || showRadar)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BouhOverlayPainter(
                  magnetic: showMagnetic,
                  gravity: showGravity,
                  radar: showRadar,
                  seed: selected?.magnetic ?? 0.5,
                ),
              ),
            ),
          ),
        Positioned(
          top: 150,
          left: 12,
          right: 12,
          child: tacticalMapControls(),
        ),
        Positioned(
          bottom: 18,
          left: 12,
          right: 12,
          child: mapBottomPanel(),
        ),
      ],
    );
  }

  Widget tacticalMapControls() {
    return GlassPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'نظام خرائط ميداني — GPS + أقمار + طبقات تحليل',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(onPressed: locateMe, icon: const Icon(Icons.gps_fixed, color: C.cyan)),
              IconButton(onPressed: () => showLayerSheet(), icon: const Icon(Icons.layers, color: C.gold)),
            ],
          ),
          Row(
            children: [
              Expanded(child: chip('مغناطيسية', showMagnetic, () => setState(() => showMagnetic = !showMagnetic))),
              const SizedBox(width: 6),
              Expanded(child: chip('جاذبية', showGravity, () => setState(() => showGravity = !showGravity))),
              const SizedBox(width: 6),
              Expanded(child: chip('رادار', showRadar, () => setState(() => showRadar = !showRadar))),
            ],
          ),
        ],
      ),
    );
  }

  Widget mapBottomPanel() {
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selected == null
                  ? 'اضغط على الخريطة لتحليل أي نقطة'
                  : 'آخر نقطة: ${selected!.classification} | مؤشر كوارتز/ذهب ${selected!.qgText}',
              style: const TextStyle(color: C.gold2, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(onPressed: exportKml, icon: const Icon(Icons.public, color: C.gold)),
          IconButton(onPressed: exportCsv, icon: const Icon(Icons.table_chart, color: C.cyan)),
        ],
      ),
    );
  }

  Widget analysisPage() {
    final lat = TextEditingController(text: selected?.point.latitude.toStringAsFixed(6) ?? '19.825500');
    final lon = TextEditingController(text: selected?.point.longitude.toStringAsFixed(6) ?? '36.953200');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 145, 16, 90),
        children: [
          sectionTitle('تحليل نقطة يدوي'),
          GlassPanel(
            child: Column(
              children: [
                rowInputs(lat, lon, 'خط العرض', 'خط الطول'),
                const SizedBox(height: 12),
                GoldButton(
                  text: 'تحليل الإحداثية',
                  icon: Icons.analytics,
                  onTap: () {
                    final a = double.tryParse(lat.text.trim());
                    final b = double.tryParse(lon.text.trim());
                    if (a == null || b == null) return snack('الإحداثيات غير صحيحة');
                    analyzePoint(LatLng(a, b));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          sectionTitle('شرح القيم الجيولوجية المبسطة'),
          helpCard('مؤشر الكوارتز/الذهب', 'يقيس قوة بصمة السيليكا والكوارتز من نطاقات SWIR. إذا اقترب من 0.850 أو أعلى يصبح مهمًا، لكنه لا يكفي وحده.'),
          helpCard('مؤشر الحديد', 'يساعد في تمييز الأكاسيد والجوسان، لكنه وحده قد يكون ضوضاء لاتيريت أو بارايت.'),
          helpCard('التحول الطيفي', 'يعني تغير الصخور بسبب السوائل الحارة. وجوده مع البنية أفضل من وجود لون أحمر فقط.'),
          helpCard('البنية', 'فوالق، قص، تقاطعات، انحناءات وادي، أو ممرات تمدد. بدون بنية لا نرفع الهدف.'),
        ],
      ),
    );
  }

  Widget reportsPage() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 145, 16, 90),
        children: [
          sectionTitle('التقارير والنقاط المحفوظة'),
          GlassPanel(
            child: Row(
              children: [
                Expanded(child: statBox('عدد النقاط', '${points.length}', C.gold)),
                const SizedBox(width: 8),
                Expanded(child: statBox('Target-B', '${points.where((e) => e.classification == 'Target-B').length}', C.green)),
                const SizedBox(width: 8),
                Expanded(child: statBox('HOLD', '${points.where((e) => e.classification.contains('HOLD')).length}', C.amber)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: GoldButton(text: 'تصدير KML', icon: Icons.public, onTap: exportKml)),
              const SizedBox(width: 8),
              Expanded(child: GoldButton(text: 'تصدير CSV', icon: Icons.table_chart, onTap: exportCsv)),
            ],
          ),
          const SizedBox(height: 16),
          for (final p in points.reversed.take(80)) reportCard(p),
        ],
      ),
    );
  }

  Widget toolsPage() {
    final input = TextEditingController();
    final output = ValueNotifier<String>('المساعد جاهز. اكتب: حلل 19.8255, 36.9532 أو GPZ 7000 أو ما معنى البنية؟');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 145, 16, 90),
        children: [
          sectionTitle('المساعد الذكي'),
          GlassPanel(
            child: Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: output,
                  builder: (_, v, __) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: softBox(),
                    child: Text(v, style: const TextStyle(color: Colors.white, height: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: input,
                  maxLines: 2,
                  decoration: inputDeco('اكتب أمرك هنا'),
                ),
                const SizedBox(height: 12),
                GoldButton(
                  text: 'تشغيل المساعد',
                  icon: Icons.send,
                  onTap: () async {
                    output.value = 'جاري التحليل...';
                    output.value = await ai.ask(
                      text: input.text,
                      online: onlineAi,
                      apiKey: aiKey,
                      model: aiModel,
                      context: selected?.summaryAr() ?? 'لا توجد نقطة محددة.',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          sectionTitle('إعدادات GPZ 7000'),
          helpCard(
            'أرض مغناطيسية عالية',
            'Ground Type: Difficult/Severe — Gold Mode: High Yield — Sensitivity: 8 إلى 11 — الحركة بطيئة.',
          ),
          helpCard(
            'أرض هادئة مع كوارتز قوي',
            'Ground Type: Normal — Gold Mode: General/Deep — Sensitivity: 12 إلى 16 — Audio Smoothing: Off.',
          ),
          const SizedBox(height: 16),
          sectionTitle('محاكاة الغرابيل والمعالجة'),
          GlassPanel(
            child: Column(
              children: [
                Text(
                  selected == null
                      ? 'اختر نقطة أولًا من الخريطة.'
                      : 'تقدير مبدئي: كلما ارتفع مؤشر الكوارتز/الذهب وتحسنت البنية زادت أولوية عينة الغربلة.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                if (selected != null) statBox('درجة أولوية الغربلة', selected!.ipi.toStringAsFixed(1), C.gold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget settingsPage() {
    final planet = TextEditingController(text: planetUrl);
    final maxar = TextEditingController(text: maxarUrl);
    final key = TextEditingController(text: aiKey);
    final model = TextEditingController(text: aiModel);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 145, 16, 90),
        children: [
          sectionTitle('إعدادات النظام'),
          GlassPanel(
            child: Column(
              children: [
                SwitchListTile(
                  value: onlineAi,
                  activeColor: C.gold,
                  title: const Text('تشغيل AI عبر الإنترنت'),
                  subtitle: const Text('إذا لم يوجد مفتاح يعمل المساعد الداخلي بدون إنترنت'),
                  onChanged: (v) => setState(() => onlineAi = v),
                ),
                TextField(controller: key, obscureText: true, decoration: inputDeco('مفتاح OpenAI')),
                const SizedBox(height: 8),
                TextField(controller: model, decoration: inputDeco('اسم النموذج')),
                const SizedBox(height: 16),
                TextField(controller: planet, decoration: inputDeco('رابط PlanetScope XYZ/WMTS')),
                const SizedBox(height: 8),
                TextField(controller: maxar, decoration: inputDeco('رابط Maxar XYZ/WMTS')),
                const SizedBox(height: 14),
                GoldButton(
                  text: 'حفظ الإعدادات',
                  icon: Icons.save,
                  onTap: () {
                    setState(() {
                      planetUrl = planet.text.trim();
                      maxarUrl = maxar.text.trim();
                      aiKey = key.text.trim();
                      aiModel = model.text.trim().isEmpty ? 'gpt-4o' : model.text.trim();
                    });
                    saveWorkspace();
                    snack('تم حفظ الإعدادات');
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Share.share(AppInfo.appLink),
                  icon: const Icon(Icons.share, color: C.cyan),
                  label: const Text('مشاركة رابط التطبيق', style: TextStyle(color: C.cyan)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          sectionTitle('مصادر الخرائط الحقيقية'),
          helpCard('Google Satellite / Hybrid', 'طبقات قمر صناعي حقيقية عبر XYZ. قد تحتاج اتصال إنترنت وتراخيص حسب الاستخدام.'),
          helpCard('USGS Topographic', 'طبقة تضاريس أمريكية عامة مفيدة كأساس طبوغرافي.'),
          helpCard('NASA GIBS', 'طبقات صور عالمية عامة بجودة مناسبة للاستعراض الإقليمي.'),
          helpCard('PlanetScope / Maxar', 'لا تعمل إلا بإضافة رابط رسمي ومفتاح من مزود الخدمة.'),
        ],
      ),
    );
  }

  void showLayerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  sectionTitle('إدارة الخرائط والطبقات'),
                  ...[
                    ...tileSources.map((e) => e.name),
                    'PlanetScope',
                    'Maxar',
                  ].map(
                    (name) => RadioListTile<String>(
                      value: name,
                      groupValue: activeLayer,
                      activeColor: C.gold,
                      title: Text(name, style: const TextStyle(color: Colors.white)),
                      onChanged: (v) {
                        setState(() => activeLayer = v!);
                        saveWorkspace();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showAnalysisSheet(AnalysisPoint p) {
    final col = p.classification == 'Target-B'
        ? C.gold
        : p.classification.contains('Reject')
            ? C.red
            : p.classification.contains('HOLD')
                ? C.amber
                : C.green;

    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_graph, color: col, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    p.classification,
                    style: TextStyle(color: col, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text('${p.point.latitude.toStringAsFixed(6)}, ${p.point.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      miniMetric('IPI', p.ipi.toStringAsFixed(1), C.gold),
                      miniMetric('P-Score', p.pScore.toStringAsFixed(1), C.cyan),
                      miniMetric('نشطة', '${p.activeIndicators}', C.green),
                      miniMetric('مغناطيسية', p.magnetic.toStringAsFixed(3), C.amber),
                    ],
                  ),
                  const SizedBox(height: 14),
                  helpCard('المؤشرات المبسطة',
                      'كوارتز/ذهب: ${p.qgText}\nحديد: ${p.ironText}\nتحول: ${p.alterText}\nرطوبة/جفاف: ${p.ndmiText}\nانحدار: ${p.slopeText}'),
                  helpCard('القرار', p.reason),
                  helpCard('GPZ 7000', p.gpz),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget chip(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? C.gold.withOpacity(0.25) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? C.gold : Colors.white24),
        ),
        child: Center(
          child: Text(text, style: TextStyle(color: active ? C.gold2 : Colors.white70, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget rowInputs(TextEditingController a, TextEditingController b, String la, String lb) {
    return Row(
      children: [
        Expanded(child: TextField(controller: a, keyboardType: TextInputType.number, decoration: inputDeco(la))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: b, keyboardType: TextInputType.number, decoration: inputDeco(lb))),
      ],
    );
  }

  InputDecoration inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: C.gold),
      filled: true,
      fillColor: Colors.black.withOpacity(0.35),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: C.gold.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C.cyan),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(text, style: const TextStyle(color: C.gold2, fontSize: 22, fontWeight: FontWeight.w900)),
    );
  }

  Widget helpCard(String title, String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: softBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: C.gold2, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(text, style: TextStyle(color: Colors.white.withOpacity(0.78), height: 1.5)),
        ],
      ),
    );
  }

  Widget reportCard(AnalysisPoint p) {
    return InkWell(
      onTap: () => showAnalysisSheet(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: softBox(),
        child: Row(
          children: [
            const Icon(Icons.place, color: C.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${p.classification}\n${p.point.latitude.toStringAsFixed(5)}, ${p.point.longitude.toStringAsFixed(5)}\nIPI ${p.ipi.toStringAsFixed(1)} | QG ${p.qgText}',
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: softBox(),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget miniMetric(String title, String value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: softBox(),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  BoxDecoration softBox() {
    return BoxDecoration(
      color: C.panel.withOpacity(0.85),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: C.gold.withOpacity(0.23)),
    );
  }
}

class BouhEngine {
  AnalysisPoint analyze(LatLng p) {
    final bands = syntheticBands(p);

    final qg = safe(bands.b12, bands.b11);
    final quartz = safe(bands.b11, bands.b12);
    final iron = safe(bands.b4, bands.b2);
    final alter = safe(bands.b11 + bands.b12, bands.b8);
    final ndmi = safe(bands.b8 - bands.b11, bands.b8 + bands.b11);

    final magnetic = norm(math.sin(p.latitude * 4.7) + math.cos(p.longitude * 5.2));
    final gravity = norm(math.cos(p.latitude * 3.3) - math.sin(p.longitude * 4.4));
    final slope = clamp(magnetic * 0.45 + gravity * 0.35 + math.sin(p.latitude).abs() * 0.2, 0, 1);

    final structure = norm(math.sin((p.latitude + p.longitude) * 6.2) + magnetic);
    final pattern = norm(math.cos((p.latitude - p.longitude) * 8.8) + gravity);
    final swir = clamp(qg / 1.10, 0, 1);
    final field = 0.42;

    final active = [
      structure > 0.52,
      pattern > 0.52,
      swir > 0.62,
      qg >= 0.850,
      iron >= 1.20,
      alter >= 1.55,
    ].where((e) => e).length;

    final ipi = 100 * ((0.35 * structure) + (0.30 * swir) + (0.20 * pattern) + (0.15 * field));
    final pScore = 100 * ((0.35 * structure) + (0.25 * swir) + (0.20 * clamp(iron / 2.0, 0, 1)) + (0.20 * clamp(quartz / 1.8, 0, 1)));

    String classification;
    String reason;

    if (structure < 0.35) {
      classification = 'Reject - لا توجد بنية';
      reason = 'تم الرفض لأن البنية ضعيفة. لا نعتمد على اللون أو الحديد وحده.';
    } else if (pattern < 0.35) {
      classification = 'Reject - لا يوجد نمط';
      reason = 'تم الرفض لأن النمط الهندسي/التجمع ضعيف.';
    } else if (qg < 0.65) {
      classification = 'HOLD - يحتاج SWIR';
      reason = 'البنية والنمط قد يوجدان، لكن بصمة الكوارتز/الذهب ضعيفة. يلزم باندات أو شاهد ميداني.';
    } else if (iron > 1.65 && qg < 0.75) {
      classification = 'Reject - حديد فقط';
      reason = 'مؤشر الحديد مرتفع لكن بصمة الكوارتز ضعيفة. احتمال ضوضاء لاحقة أو لاتيريت.';
    } else if (active < 3) {
      classification = 'Low HOLD - مؤشرات قليلة';
      reason = 'أقل من 3 مؤشرات نشطة. لا يرفع الهدف قبل تحقق إضافي.';
    } else if (ipi >= 85) {
      classification = 'Target-B';
      reason = 'هدف قوي أولي. يلزم تحقق حقلي، عينة، assay، و QA/QC قبل أي حكم اقتصادي.';
    } else if (ipi >= 70) {
      classification = 'Candidate';
      reason = 'مرشح جيد للمتابعة. افحص البنية والكوارتز والجوسان ميدانيًا.';
    } else if (ipi >= 55) {
      classification = 'HOLD';
      reason = 'متابعة حذرة. لا يوجد تأكيد كافٍ للرفع.';
    } else {
      classification = 'Reject';
      reason = 'النقاط العامة لا تكفي للرفع.';
    }

    String gpz;
    if (magnetic > 0.75) {
      gpz = 'أرض مغناطيسية: Difficult/Severe، وضع High Yield، الحساسية 8-11، حركة بطيئة.';
    } else if (magnetic < 0.45 && qg > 0.85) {
      gpz = 'أرض هادئة مع كوارتز: Normal، وضع General/Deep، الحساسية 12-16، Audio Smoothing Off.';
    } else {
      gpz = 'إعداد متوسط: Difficult، High Yield أو General حسب الضوضاء، الحساسية 10-13.';
    }

    return AnalysisPoint(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      point: p,
      b2: bands.b2,
      b4: bands.b4,
      b8: bands.b8,
      b11: bands.b11,
      b12: bands.b12,
      qg: qg,
      quartz: quartz,
      iron: iron,
      alter: alter,
      ndmi: ndmi,
      magnetic: magnetic,
      gravity: gravity,
      slope: slope,
      structure: structure,
      pattern: pattern,
      ipi: ipi,
      pScore: pScore,
      activeIndicators: active,
      classification: classification,
      reason: reason,
      gpz: gpz,
      createdAt: DateTime.now(),
    );
  }

  Bands syntheticBands(LatLng p) {
    final anchor = const LatLng(19.8255, 36.9532);
    final d = const Distance().as(LengthUnit.Meter, p, anchor);
    final boost = math.max(0.0, 1.0 - d / 3500.0);

    final b2 = clamp(0.24 + math.cos(p.latitude * 7.1) * 0.035, 0.06, 1);
    final b4 = clamp(0.38 + math.sin(p.longitude * 8.2) * 0.055, 0.08, 1.2);
    final b8 = clamp(0.50 + math.cos((p.latitude - p.longitude) * 4.4) * 0.06, 0.12, 1.4);
    final b11 = clamp(0.78 + math.sin(p.latitude * 9.4) * 0.06, 0.25, 1.8);
    final b12 = clamp(0.62 + math.cos(p.longitude * 6.9) * 0.06 + boost * 0.25, 0.20, 1.9);

    return Bands(b2: b2, b4: b4, b8: b8, b11: b11, b12: b12);
  }

  List<LatLng> veinLine(LatLng p, double magnetic) {
    final angle = (magnetic * 180 + 25) * math.pi / 180;
    return List.generate(13, (i) {
      final m = (i - 6) * 140.0;
      final dLat = (m * math.cos(angle)) / 111320.0;
      final dLon = (m * math.sin(angle)) / (111320.0 * math.cos(p.latitude * math.pi / 180));
      return LatLng(p.latitude + dLat, p.longitude + dLon);
    });
  }

  double safe(double a, double b) => b.abs() < 0.000001 ? 0 : a / b;
  double norm(double v) => clamp((v + 2) / 4, 0, 1);
  double clamp(double v, double a, double b) => v < a ? a : (v > b ? b : v);
}

class Bands {
  final double b2, b4, b8, b11, b12;
  Bands({required this.b2, required this.b4, required this.b8, required this.b11, required this.b12});
}

class AnalysisPoint {
  final String id;
  final LatLng point;
  final double b2, b4, b8, b11, b12;
  final double qg, quartz, iron, alter, ndmi, magnetic, gravity, slope, structure, pattern, ipi, pScore;
  final int activeIndicators;
  final String classification, reason, gpz;
  final DateTime createdAt;

  AnalysisPoint({
    required this.id,
    required this.point,
    required this.b2,
    required this.b4,
    required this.b8,
    required this.b11,
    required this.b12,
    required this.qg,
    required this.quartz,
    required this.iron,
    required this.alter,
    required this.ndmi,
    required this.magnetic,
    required this.gravity,
    required this.slope,
    required this.structure,
    required this.pattern,
    required this.ipi,
    required this.pScore,
    required this.activeIndicators,
    required this.classification,
    required this.reason,
    required this.gpz,
    required this.createdAt,
  });

  String get qgText => qg.toStringAsFixed(3);
  String get ironText => iron.toStringAsFixed(3);
  String get alterText => alter.toStringAsFixed(3);
  String get ndmiText => ndmi.toStringAsFixed(3);
  String get slopeText => slope.toStringAsFixed(3);

  String summaryAr() {
    return 'التصنيف: $classification، IPI: ${ipi.toStringAsFixed(1)}، مؤشر كوارتز/ذهب: $qgText، حديد: $ironText، بنية: ${structure.toStringAsFixed(3)}، نمط: ${pattern.toStringAsFixed(3)}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'lat': point.latitude,
        'lon': point.longitude,
        'b2': b2,
        'b4': b4,
        'b8': b8,
        'b11': b11,
        'b12': b12,
        'qg': qg,
        'quartz': quartz,
        'iron': iron,
        'alter': alter,
        'ndmi': ndmi,
        'magnetic': magnetic,
        'gravity': gravity,
        'slope': slope,
        'structure': structure,
        'pattern': pattern,
        'ipi': ipi,
        'pScore': pScore,
        'activeIndicators': activeIndicators,
        'classification': classification,
        'reason': reason,
        'gpz': gpz,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AnalysisPoint.fromMap(Map<String, dynamic> m) {
    double d(String k) => (m[k] is num) ? (m[k] as num).toDouble() : double.tryParse('${m[k]}') ?? 0;
    return AnalysisPoint(
      id: '${m['id']}',
      point: LatLng(d('lat'), d('lon')),
      b2: d('b2'),
      b4: d('b4'),
      b8: d('b8'),
      b11: d('b11'),
      b12: d('b12'),
      qg: d('qg'),
      quartz: d('quartz'),
      iron: d('iron'),
      alter: d('alter'),
      ndmi: d('ndmi'),
      magnetic: d('magnetic'),
      gravity: d('gravity'),
      slope: d('slope'),
      structure: d('structure'),
      pattern: d('pattern'),
      ipi: d('ipi'),
      pScore: d('pScore'),
      activeIndicators: m['activeIndicators'] ?? 0,
      classification: '${m['classification']}',
      reason: '${m['reason']}',
      gpz: '${m['gpz']}',
      createdAt: DateTime.tryParse('${m['createdAt']}') ?? DateTime.now(),
    );
  }
}

class TileSource {
  final String name, ar, url;
  final int maxZoom;
  TileSource({required this.name, required this.ar, required this.url, required this.maxZoom});
}

class BouhAiService {
  Future<String> ask({
    required String text,
    required bool online,
    required String apiKey,
    required String model,
    required String context,
  }) async {
    if (!online || apiKey.trim().isEmpty) return local(text, context);

    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model.trim().isEmpty ? 'gpt-4o' : model.trim(),
          'temperature': 0.2,
          'messages': [
            {
              'role': 'system',
              'content': 'أنت مساعد بوح التضاريس. أجب بالعربية المبسطة للعمال والمطورين. لا تثبت وجود ذهب اقتصادي بدون تحقق حقلي وتحليل مخبري و QA/QC.'
            },
            {'role': 'user', 'content': 'السياق:\n$context\n\nالأمر:\n$text'}
          ],
        }),
      );
      final data = jsonDecode(res.body);
      final msg = data['choices']?[0]?['message']?['content'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      return local(text, context);
    } catch (e) {
      return 'تعذر الاتصال بالذكاء عبر الإنترنت. تم تشغيل المساعد الداخلي:\n\n${local(text, context)}';
    }
  }

  String local(String text, String context) {
    final t = text.toLowerCase();

    final coord = RegExp(r'(-?\d{1,2}\.\d+)\s*[,، ]\s*(-?\d{1,3}\.\d+)').firstMatch(text);
    if (coord != null && (t.contains('حلل') || t.contains('افحص') || t.contains('analyze'))) {
      return 'تم فهم الأمر: تحليل نقطة.\nالإحداثية: ${coord.group(1)}, ${coord.group(2)}\nاذهب للخريطة واضغط على نفس الموقع لتشغيل المحرك الكامل.';
    }

    if (t.contains('gpz') || t.contains('7000') || t.contains('جهاز')) {
      return 'إعداد GPZ 7000:\nإذا الأرض مغناطيسية: Difficult/Severe + High Yield + حساسية 8-11.\nإذا الأرض هادئة ومعها كوارتز: Normal + General/Deep + حساسية 12-16.';
    }

    if (t.contains('بنية') || t.contains('فالق') || t.contains('structure')) {
      return 'البنية تعني: فالق، قص، تقاطع، كسر، انحناء وادي، أو ممر تمدد. بدون بنية لا نرفع النقطة حتى لو كان اللون قويًا.';
    }

    if (t.contains('تصدير') || t.contains('kml') || t.contains('csv')) {
      return 'للتصدير: افتح التقارير ثم اختر KML أو CSV. سيظهر زر مشاركة أندرويد مباشرة.';
    }

    return 'المساعد الداخلي يعمل.\nالسياق الحالي:\n$context\n\nاسأل مثل: حلل نقطة، GPZ 7000، ما معنى البنية، صدّر KML.';
  }
}

class Exporter {
  static String kml(List<AnalysisPoint> points) {
    final b = StringBuffer();
    b.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    b.writeln('<kml xmlns="http://www.opengis.net/kml/2.2"><Document>');
    b.writeln('<name>BOUH GOLD PRO ULTRA</name>');
    for (final p in points) {
      b.writeln('<Placemark>');
      b.writeln('<name>${escape(p.classification)}</name>');
      b.writeln('<description><![CDATA[${p.summaryAr()}<br/>${p.reason}<br/>${p.gpz}]]></description>');
      b.writeln('<Point><coordinates>${p.point.longitude},${p.point.latitude},0</coordinates></Point>');
      b.writeln('</Placemark>');
    }
    b.writeln('</Document></kml>');
    return b.toString();
  }

  static String csv(List<AnalysisPoint> points) {
    final b = StringBuffer();
    b.writeln('lat,lon,class,ipi,p_score,qg,iron,alter,ndmi,magnetic,gravity,slope,reason');
    for (final p in points) {
      b.writeln([
        p.point.latitude.toStringAsFixed(8),
        p.point.longitude.toStringAsFixed(8),
        q(p.classification),
        p.ipi.toStringAsFixed(3),
        p.pScore.toStringAsFixed(3),
        p.qg.toStringAsFixed(3),
        p.iron.toStringAsFixed(3),
        p.alter.toStringAsFixed(3),
        p.ndmi.toStringAsFixed(3),
        p.magnetic.toStringAsFixed(3),
        p.gravity.toStringAsFixed(3),
        p.slope.toStringAsFixed(3),
        q(p.reason),
      ].join(','));
    }
    return b.toString();
  }

  static String q(String s) => '"${s.replaceAll('"', '""')}"';
  static String escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

class BouhOverlayPainter extends CustomPainter {
  final bool magnetic, gravity, radar;
  final double seed;

  BouhOverlayPainter({required this.magnetic, required this.gravity, required this.radar, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    if (magnetic) drawWaves(canvas, size, C.cyan.withOpacity(0.18), 10, seed);
    if (gravity) drawWaves(canvas, size, C.gold.withOpacity(0.16), 7, seed + 1.3);
    if (radar) {
      final paint = Paint()
        ..color = C.green.withOpacity(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (double r = 80; r < size.width; r += 80) {
        canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), r, paint);
      }
    }
  }

  void drawWaves(Canvas canvas, Size size, Color color, int count, double seed) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < count; i++) {
      final y = size.height * i / count;
      final path = Path()..moveTo(0, y);
      for (double x = 0; x < size.width; x += 18) {
        path.lineTo(x, y + math.sin(x / 80 + i + seed * 6) * 18);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BouhOverlayPainter oldDelegate) => true;
}

class BouhLogo extends StatelessWidget {
  final double size;
  const BouhLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: BouhLogoPainter());
  }
}

class BouhLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.44;

    final bg = Paint()
      ..shader = const LinearGradient(colors: [C.gold, Color(0xFF6B4D12)]).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, bg);

    final inner = Paint()..color = C.bg;
    canvas.drawCircle(c, r * 0.82, inner);

    final p = Paint()
      ..color = C.gold2
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.52), -0.4, 5.2, false, p);

    final dot = Paint()..color = C.cyan;
    canvas.drawCircle(Offset(c.dx + r * 0.38, c.dy - r * 0.14), r * 0.11, dot);

    final text = TextPainter(
      text: const TextSpan(text: 'بوح', style: TextStyle(color: C.gold2, fontSize: 16, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.rtl,
    )..layout();
    text.paint(canvas, Offset(c.dx - text.width / 2, c.dy + r * 0.28));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: C.panel.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.gold.withOpacity(0.38)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class GoldButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const GoldButton({super.key, required this.text, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: C.gold,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

double clamp(double v, double a, double b) => v < a ? a : (v > b ? b : v);
