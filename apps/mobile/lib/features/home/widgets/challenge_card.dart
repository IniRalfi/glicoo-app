// challenge_card.dart
//
// Purpose:
// → Widget "Tantangan Hari Ini" yang merender quest list secara dinamis
//   + tombol "Cek selengkapnya" ke tab Misi.
//
// Used By:
// → home_screen.dart
//
// Depends On:
// → quests_screen (questListProvider, QuestDetailDialog), app_colors, bento_card
//
// Impact:
// → Bagian tantangan/misi di halaman beranda

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bento_card.dart';
import '../../navigation/bottom_nav_shell.dart';
import '../../quests/quests_screen.dart';

class ChallengeCard extends ConsumerWidget {
  const ChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questListProvider);

    return Column(
      children: List.generate(quests.length, (index) {
        final quest = quests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: BentoCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.white,
            borderColor: Colors.white,
            onTap: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Detail Misi',
                barrierColor: Colors.black.withValues(alpha: 0.5),
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, anim1, anim2) {
                  return QuestDetailDialog(quest: quest);
                },
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: quest.themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    quest.iconPath,
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(
                      quest.themeColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              quest.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: quest.themeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            quest.points,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quest.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quest.statusText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (quest.progress != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: quest.progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE5E5EA),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              quest.themeColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class MoreQuestsButton extends ConsumerWidget {
  const MoreQuestsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          // Pindah ke tab Misi (index 1)
          ref.read(bottomNavIndexProvider.notifier).state = 1;
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cek selengkapnya',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
