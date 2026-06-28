// activity_cards.dart
//
// Purpose:
// → Widget kartu aktivitas harian (langkah, tidur, screen time) + MiniBarChart.
//
// Used By:
// → home_screen.dart
//
// Depends On:
// → activity_provider, app_colors, bento_card, flutter_svg, google_fonts
//
// Impact:
// → Bagian "Aktivitas Harian" di halaman beranda

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bento_card.dart';
import '../providers/activity_provider.dart';

class ActivityCards extends ConsumerWidget {
  const ActivityCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityDataProvider);

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    String formatSteps(int val) {
      if (val >= 1000) {
        final thousands = val ~/ 1000;
        final remainder = val % 1000;
        return '$thousands.${remainder.toString().padLeft(3, '0')}';
      }
      return val.toString();
    }

    return Column(
      children: [
        // 1. LANGKAH CARD
        _BentoActivityCard(
          iconPath: 'assets/images/home/footstep.svg',
          iconColor: const Color(0xFF24B35F),
          title: 'Langkah',
          titleColor: const Color(0xFF24B35F),
          dateStr: dateStr,
          richText: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.black, fontSize: 13),
              children: [
                TextSpan(
                  text: formatSteps(activity.steps),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: ' / ${formatSteps(activity.stepsGoal)} ',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const TextSpan(
                  text: 'Jalan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          historyValues:
              activity.stepsHistory.map((s) => s / activity.stepsGoal).toList(),
          activeColor: const Color(0xFF24B35F),
        ),
        const SizedBox(height: 12),

        // 2. TIDUR CARD
        _BentoActivityCard(
          iconPath: 'assets/images/home/sleep.svg',
          iconColor: const Color(0xFF007AFF),
          title: 'Tidur',
          titleColor: const Color(0xFF007AFF),
          dateStr: dateStr,
          richText: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.black, fontSize: 13),
              children: [
                TextSpan(
                  text: '${activity.sleepMinutes ~/ 60}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const TextSpan(
                  text: 'j ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: '${activity.sleepMinutes % 60}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const TextSpan(
                  text: 'mnt',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          historyValues: activity.sleepHistory.map((m) => m / 480.0).toList(),
          activeColor: const Color(0xFF007AFF),
          onTap: () => _showSleepLogBottomSheet(context, ref),
        ),
        const SizedBox(height: 12),

        // 3. SCREEN TIME CARD
        _BentoActivityCard(
          iconPath: 'assets/images/home/smartphone-device.svg',
          iconColor: const Color(0xFFFF3B30),
          title: 'Waktu Paparan Layar',
          titleColor: const Color(0xFFFF3B30),
          dateStr: dateStr,
          richText: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.black, fontSize: 13),
              children: [
                TextSpan(
                  text: '${activity.screenTimeMinutes ~/ 60}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const TextSpan(
                  text: 'j ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: '${activity.screenTimeMinutes % 60}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const TextSpan(
                  text: 'mnt',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          historyValues:
              activity.screenTimeHistory.map((m) => m / 480.0).toList(),
          activeColor: const Color(0xFFFF3B30),
        ),
      ],
    );
  }

  void _showSleepLogBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        int hours = 7;
        int minutes = 0;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                24, 24, 24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.nights_stay_rounded,
                          color: Color(0xFF007AFF), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Catat Durasi Tidur',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan estimasi lama tidur berkualitas Anda tadi malam atau hari ini.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TimeUnit(
                        value: hours,
                        label: 'Jam',
                        color: const Color(0xFF007AFF),
                        onDecrement: hours > 0
                            ? () => setModalState(() => hours--)
                            : null,
                        onIncrement: hours < 24
                            ? () => setModalState(() => hours++)
                            : null,
                      ),
                      const SizedBox(width: 48),
                      _TimeUnit(
                        value: minutes,
                        label: 'Menit',
                        color: const Color(0xFF007AFF),
                        padded: true,
                        onDecrement: minutes > 0
                            ? () => setModalState(() => minutes -= 5)
                            : null,
                        onIncrement: minutes < 55
                            ? () => setModalState(() => minutes += 5)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final totalMinutes = (hours * 60) + minutes;
                            await ref
                                .read(activityDataProvider.notifier)
                                .setSleepMinutes(totalMinutes);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Durasi tidur berhasil disimpan.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Simpan',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

class _BentoActivityCard extends StatelessWidget {
  const _BentoActivityCard({
    required this.iconPath,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.dateStr,
    required this.richText,
    required this.historyValues,
    required this.activeColor,
    this.onTap,
  });

  final String iconPath;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final String dateStr;
  final RichText richText;
  final List<double> historyValues;
  final Color activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        borderColor: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        iconPath,
                        width: 18,
                        height: 18,
                        colorFilter:
                            ColorFilter.mode(iconColor, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  richText,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.subtitleGray,
                  ),
                ),
                const SizedBox(height: 8),
                MiniBarChart(
                  values: historyValues,
                  activeColor: activeColor,
                  activeIndex: 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  const _TimeUnit({
    required this.value,
    required this.label,
    required this.color,
    required this.onDecrement,
    required this.onIncrement,
    this.padded = false,
  });

  final int value;
  final String label;
  final Color color;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          padded ? value.toString().padLeft(2, '0') : '$value',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              color: Colors.grey,
              onPressed: onDecrement,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: color,
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget mini grafik batang (6 kolom historis).
class MiniBarChart extends StatelessWidget {
  final List<double> values;
  final Color activeColor;
  final int activeIndex;

  const MiniBarChart({
    super.key,
    required this.values,
    required this.activeColor,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (index) {
        final isHighlighted = index == activeIndex;
        final height = 12.0 + (values[index].clamp(0.0, 1.0) * 48.0);
        return Container(
          width: 6,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            color: isHighlighted ? activeColor : const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
