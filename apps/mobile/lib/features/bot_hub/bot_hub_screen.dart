// bot_hub_screen.dart
//
// Purpose:
// Landing cover screen for Glico chatbot feature (Iloo).
//
// Used By:
// bottom_nav_shell.dart
//
// Depends On:
// flutter/material, flutter_svg, google_fonts, hooks_riverpod
//
// Impact:
// Entry point for Glico's in-app chatbot conversations.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../chatbot/presentation/chatbot_screen.dart';

class BotHubScreen extends ConsumerWidget {
  const BotHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          // Background Clouds
          Positioned(
            left: 0,
            bottom: MediaQuery.of(context).size.height * 0.35,
            child: SvgPicture.asset(
              'assets/images/bothub/awan_kiri.svg',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.35,
            child: SvgPicture.asset(
              'assets/images/bothub/awan_kanan.svg',
              fit: BoxFit.contain,
            ),
          ),
          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        child: Column(
                          children: [
                            const Spacer(),
                            // Iloo Chat Image (Center Top)
                            SvgPicture.asset(
                              'assets/images/bothub/iloo_chat.svg',
                              height: 250,
                              fit: BoxFit.contain,
                            ),
                            const Spacer(),
                            // Title
                            Text(
                              'Ngobrol\nBareng Iloo',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.rammettoOne(
                                fontSize: 32,
                                color: Colors.black,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Description
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Punya pertanyaan tentang kesehatan atau ingin berbagi aktivitas hari ini? Yuk ngobrol, dan biarkan Iloo membantumu membangun kebiasaan yang lebih sehat.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6D717F),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Button
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB000),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                'Chat Sekarang',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(flex: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
