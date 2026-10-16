import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';

/// Port of components/doctor/SimulatedCallScreen.tsx (demo only — no real call).
class SimulatedCallScreen extends StatefulWidget {
  const SimulatedCallScreen({super.key, required this.doctorName});
  final String doctorName;

  @override
  State<SimulatedCallScreen> createState() => _SimulatedCallScreenState();
}

class _SimulatedCallScreenState extends State<SimulatedCallScreen> {
  bool _mic = true;
  bool _cam = true;
  int _secs = 0;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _secs++));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _time =>
      '${(_secs ~/ 60).toString().padLeft(2, '0')}:${(_secs % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey900,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.doctorName, style: ts(15, weight: bold, color: Colors.white)),
                  Row(children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('লাইভ ভিডিও কনসালটেশন (ডেমো)', style: ts(11, color: Colors.white70)),
                  ]),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
                child: Text(toBnDigits(_time), style: ts(13, weight: bold, color: Colors.white)),
              ),
            ]),
          ),
          Expanded(
            child: Stack(children: [
              Center(
                child: _cam
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        ClipOval(
                          child: NetImage(
                            'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150&auto=format&fit=crop&q=80',
                            width: 130,
                            height: 130,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(widget.doctorName, style: ts(16, weight: bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('"আপনার শিশুর পুষ্টি ও ঘুম নিয়ে বলুন, আমি শুনছি..."', style: ts(12, color: Colors.white70)),
                      ])
                    : Text('ক্যামেরা বন্ধ রয়েছে', style: ts(13, color: Colors.white54)),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  width: 96,
                  height: 128,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Text(_cam ? 'আপনার ক্যামেরা' : 'ভিডিও বন্ধ', style: ts(10, color: Colors.white70)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _ctrl(_mic ? LucideIcons.mic : LucideIcons.micOff, Colors.white24, () => setState(() => _mic = !_mic)),
              const SizedBox(width: 18),
              _ctrl(_cam ? LucideIcons.video : LucideIcons.videoOff, Colors.white24, () => setState(() => _cam = !_cam)),
              const SizedBox(width: 18),
              _ctrl(LucideIcons.phoneOff, AppColors.red600, () => Navigator.pop(context)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('জরুরি চিকিৎসার জন্য এই সিমুলেটেড সেশনের অপেক্ষা করবেন না।', style: ts(10.5, color: Colors.white54)),
          ),
        ]),
      ),
    );
  }

  Widget _ctrl(IconData icon, Color bg, VoidCallback onTap) => Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(16), child: Icon(icon, color: Colors.white, size: 24)),
        ),
      );
}
