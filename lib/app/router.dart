import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:si_eja/screens/splash_screen.dart';
import 'package:si_eja/screens/select_role_screen.dart';
import 'package:si_eja/screens/student/offline_dashboard_screen.dart';
import 'package:si_eja/screens/student/offline_settings_screen.dart';
import 'package:si_eja/screens/student/offline_profile_screen.dart';
import 'package:si_eja/screens/student/login_student_screen.dart';
import 'package:si_eja/screens/student/student_dashboard_screen.dart';
import 'package:si_eja/screens/student/learn_letter_screen.dart';
import 'package:si_eja/screens/student/stage_map_screen.dart';
import 'package:si_eja/screens/student/spell_word_screen.dart';
import 'package:si_eja/screens/student/select_objek_screen.dart';
import 'package:si_eja/screens/student/spell_guided_screen.dart';
import 'package:si_eja/screens/student/progress_screen.dart';
import 'package:si_eja/screens/student/stage_screen.dart';
import 'package:si_eja/screens/student/reward_screen.dart';
import 'package:si_eja/screens/student/settings_screen.dart';
import 'package:si_eja/screens/student/profile_screen.dart';
import 'package:si_eja/screens/teacher/login_teacher_screen.dart';
import 'package:si_eja/screens/teacher/teacher_dashboard_screen.dart';
import 'package:si_eja/screens/teacher/unlock_level_screen.dart';
import 'package:si_eja/screens/teacher/student_list_screen.dart';
import 'package:si_eja/screens/teacher/progress_report_screen.dart';
import 'package:si_eja/screens/teacher/teacher_settings_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/offline-dashboard',
      builder: (context, state) => const OfflineDashboardScreen(),
    ),
    GoRoute(
      path: '/select-role',
      builder: (context, state) => const SelectRoleScreen(),
    ),
    GoRoute(
      path: '/login-student',
      builder: (context, state) => const LoginStudentScreen(),
    ),
    GoRoute(
      path: '/login-teacher',
      builder: (context, state) => const LoginTeacherScreen(),
    ),
    GoRoute(
      path: '/student-dashboard',
      builder: (context, state) => const StudentDashboardScreen(),
    ),
    GoRoute(
      path: '/learn-letter',
      builder: (context, state) => const LearnLetterScreen(),
    ),
    GoRoute(
      path: '/stage-map',
      builder: (context, state) => const StageMapScreen(),
    ),
    GoRoute(
      path: '/stage',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MaterialPage(
          key: ValueKey('stage_${extra['stageId']}'),
          child: StageScreen(
            stageId: extra['stageId'] as int,
          ),
        );
      },
    ),
    GoRoute(
      path: '/spell-word',
      builder: (context, state) => const SpellWordScreen(),
    ),
    GoRoute(
      path: '/select-objek',
      builder: (context, state) => const SelectObjekScreen(),
    ),
    GoRoute(
      path: '/spell-guided',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MaterialPage(
          key: ValueKey(extra['kata']),
          child: SpellGuidedScreen(
            letter: extra['letter'],
            kata: extra['kata'],
            gambar: extra['gambar'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/reward',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return MaterialPage(
          child: RewardScreen(
            score: extra['score'] as int,
            stageId: extra['stageId'] as int,
          ),
        );
      },
    ),
    GoRoute(
      path: '/teacher-dashboard',
      builder: (context, state) => const TeacherDashboardScreen(),
    ),
    GoRoute(
      path: '/unlock-level',
      builder: (context, state) => const UnlockLevelScreen(),
    ),
    GoRoute(
      path: '/progress-report',
      builder: (context, state) => const ProgressReportScreen(),
    ),
    GoRoute(
      path: '/student-list',
      builder: (context, state) => const StudentListScreen(),
    ),
    GoRoute(
      path: '/teacher-settings',
      builder: (context, state) => const TeacherSettingsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/offline-settings',
      builder: (context, state) => const OfflineSettingsScreen(),
    ),
    GoRoute(
      path: '/offline-profile',
      builder: (context, state) => const OfflineProfileScreen(),
    ),
  ],
);

// Private widget untuk placeholder sementara
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
