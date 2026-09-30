class AppImages {
  // Background
  static const String bgSplash = 'assets/images/background/bg_splash.png';
  static const String bgSelectRole = 'assets/images/background/bg_select_role.png';
  static const String bgDashboardStudent = 'assets/images/background/bg_dashboard_student.png';
  static const String bgDashboardTeacher = 'assets/images/background/bg_dashboard_teacher.png';
  static const String bgLearnLetter = 'assets/images/background/bg_learn_letter.png';
  static const String bgStageMap = 'assets/images/background/bg_stage_map.png';
  static const String bgInStage = 'assets/images/background/bg_in_stage.png';
  static const String bgSpellWord = 'assets/images/background/bg_spell_word.png';
  static const String bgProgress = 'assets/images/background/bg_progress.png';
  static const String bgReward = 'assets/images/background/bg_reward.png';
  static const String bgSettingsStudent = 'assets/images/background/bg_dashboard_student.png';

  // Buttons
  static const String btnRoleStudent = 'assets/images/buttons/btn_role_student.png';
  static const String btnRoleTeacher = 'assets/images/buttons/btn_role_teacher.png';
  static const String btnStartNormal = 'assets/images/buttons/btn_start_normal.png';
  static const String btnStartPressed = 'assets/images/buttons/btn_start_pressed.png';
  static const String btnNextNormal = 'assets/images/buttons/btn_next_normal.png';
  static const String btnNextPressed = 'assets/images/buttons/btn_next_pressed.png';
  static const String btnBackNormal = 'assets/images/buttons/btn_back_normal.png';
  static const String btnBackPressed = 'assets/images/buttons/btn_back_pressed.png';
  static const String btnContinueNormal = 'assets/images/buttons/btn_continue_normal.png';
  static const String btnContinuePressed = 'assets/images/buttons/btn_continue_pressed.png';
  static const String btnFinishNormal = 'assets/images/buttons/btn_finish_normal.png';
  static const String btnFinishPressed = 'assets/images/buttons/btn_finish_pressed.png';
  static const String btnLoginNormal = 'assets/images/buttons/btn_login_normal.png';
  static const String btnLoginPressed = 'assets/images/buttons/btn_login_pressed.png';
  static const String btnCheckNormal = 'assets/images/buttons/btn_check_normal.png';
  static const String btnCheckPressed = 'assets/images/buttons/btn_check_pressed.png';
  static const String btnDeleteNormal = 'assets/images/buttons/btn_delete_normal.png';
  static const String btnDeletePressed = 'assets/images/buttons/btn_delete_pressed.png';
  static const String btnExitNormal = 'assets/images/buttons/btn_exit_normal.png';
  static const String btnExitPressed = 'assets/images/buttons/btn_exit_pressed.png';
  static const String btnCheckConnectionNormal = 'assets/images/buttons/btn_check_connection_normal.png';
  static const String btnCheckConnectionPressed = 'assets/images/buttons/btn_check_connection_pressed.png';
  static const String btnOfflineNormal = 'assets/images/buttons/btn_offline_normal.png';
  static const String btnOfflinePressed = 'assets/images/buttons/btn_offline_pressed.png';

  // Icons navigasi
  static const String icHome = 'assets/images/icons/navigasi/ic_home.png';
  static const String icBack = 'assets/images/icons/navigasi/ic_back.png';
  static const String icSettings = 'assets/images/icons/navigasi/ic_settings.png';
  static const String icProfileManDefault = 'assets/images/icons/navigasi/ic_profile_man_default.png';
  static const String icProfileWomanDefault = 'assets/images/icons/navigasi/ic_profile_woman_default.png';
  static const String icProfile = icProfileManDefault;
  static const String icSound = 'assets/images/icons/navigasi/ic_sound.png';
  static const String icConnection = 'assets/images/icons/navigasi/ic_connection.png';
  static const String icHelp = 'assets/images/icons/navigasi/ic_help.png';
  static const String icPlay = 'assets/images/icons/navigasi/ic_play.png';
  static const String icMaterial = 'assets/images/icons/navigasi/ic_material.png';

  // Icons beranda siswa
  static const String icLearnLetter = 'assets/images/icons/beranda/ic_learn_letter.png';
  static const String icSpellWord = 'assets/images/icons/beranda/ic_spell_word.png';
  static const String icGame = 'assets/images/icons/beranda/ic_game.png';
  static const String icMyProgress = 'assets/images/icons/beranda/ic_my_progress.png';

  // Icons game
  static const String icCorrect = 'assets/images/icons/game/ic_correct.png';
  static const String icWrong = 'assets/images/icons/game/ic_wrong.png';
  static const String icStar = 'assets/images/icons/game/ic_star.png';
  static const String icTrophy = 'assets/images/icons/game/ic_trophy.png';
  static const String icLock = 'assets/images/icons/game/ic_lock.png';
  static const String icUnlock = 'assets/images/icons/game/ic_unlock.png';
  static const String icLevel = 'assets/images/icons/game/ic_level.png';
  static const String icReport = 'assets/images/icons/game/ic_report.png';
  static const String icNext = 'assets/images/icons/game/ic_next.png';

  // Icons guru
  static const String icHomeTeacher = 'assets/images/icons/guru/ic_home_teacher.png';
  static const String icUnlockLevel = 'assets/images/icons/guru/ic_unlock_level.png';
  static const String icStudentList = 'assets/images/icons/guru/ic_student_list.png';
  static const String icSchedule = 'assets/images/icons/guru/ic_schedule.png';
  static const String icLogout = 'assets/images/icons/guru/ic_logout.png';
  static const String icProgressReport = 'assets/images/icons/guru/ic_progress_report.png';
  static const String icLearning = 'assets/images/icons/guru/ic_learning.png';
  static const String icGrade = 'assets/images/icons/guru/ic_grade.png';
  static const String icNotification = 'assets/images/icons/guru/ic_notification.png';
  static const String icLevelSettings = 'assets/images/icons/guru/ic_level_settings.png';
  static const String icReset = 'assets/images/icons/guru/ic_reset.png';
  static const String icStudentStuck = 'assets/images/icons/guru/ic_student_stuck.png';
  static const String icAddStudent = 'assets/images/icons/guru/ic_add_student.png';

  // Stage icons (per nomor stage 1–6)
  static String stageLocked(int stageId) =>
      'assets/images/stage/stage_locked_$stageId.png';
  static String stageUnlocked(int stageId) =>
      'assets/images/stage/stage_unlocked_$stageId.png';
  static String stageCompleted(int stageId) =>
      'assets/images/stage/stage_completed_$stageId.png';
  static String stageIcon(String status, int stageId) {
    if (status == 'completed') return stageCompleted(stageId);
    if (status == 'unlocked') return stageUnlocked(stageId);
    return stageLocked(stageId);
  }

  // Popup
  static const String popupCorrect = 'assets/images/popup/popup_correct.png';
  static const String popupTryAgain = 'assets/images/popup/popup_try_again.png';

  // Template kartu & frame
  static const String cardTemplateBlue = 'assets/images/template/card_template_blue.png';
  static const String cardTemplateGreen = 'assets/images/template/card_template_green.png';
  static const String frameLogin = 'assets/images/template/frame_login.png';
  static const String frameStudentList = 'assets/images/template/frame_student_list.png';
  static const String logoAplikasiInfo = 'assets/images/template/logo_aplikasi_info.png';

  // Mapping huruf ke gambar kata
  static const Map<String, String> hurufKeGambar = {
    'a': 'assets/images/kata/a_ayam.png',
    'b': 'assets/images/kata/b_bebek.png',
    'c': 'assets/images/kata/c_cicak.png',
    'd': 'assets/images/kata/d_domba.png',
    'e': 'assets/images/kata/e_elang.png',
    'f': 'assets/images/kata/f_feri.png',
    'g': 'assets/images/kata/g_gajah.png',
    'h': 'assets/images/kata/h_harimau.png',
    'i': 'assets/images/kata/i_ikan.png',
    'j': 'assets/images/kata/j_jerapah.png',
    'k': 'assets/images/kata/k_kucing.png',
    'l': 'assets/images/kata/l_lebah.png',
    'm': 'assets/images/kata/m_monyet.png',
    'n': 'assets/images/kata/n_nanas.png',
    'o': 'assets/images/kata/o_onta.png',
    'p': 'assets/images/kata/p_panda.png',
    'q': 'assets/images/kata/q_quran.png',
    'r': 'assets/images/kata/r_rusa.png',
    's': 'assets/images/kata/s_singa.png',
    't': 'assets/images/kata/t_tikus.png',
    'u': 'assets/images/kata/u_ulat.png',
    'v': 'assets/images/kata/v_vas.png',
    'w': 'assets/images/kata/w_wortel.png',
    'x': 'assets/images/kata/x_xilofon.png',
    'y': 'assets/images/kata/y_yoyo.png',
    'z': 'assets/images/kata/z_zebra.png',
  };

  // Mapping huruf ke nama kata
  static const Map<String, String> hurufKeKata = {
    'a': 'Ayam', 'b': 'Bebek', 'c': 'Cicak',
    'd': 'Domba', 'e': 'Elang', 'f': 'Feri',
    'g': 'Gajah', 'h': 'Harimau', 'i': 'Ikan',
    'j': 'Jerapah', 'k': 'Kucing', 'l': 'Lebah',
    'm': 'Monyet', 'n': 'Nanas', 'o': 'Onta',
    'p': 'Panda', 'q': 'Quran', 'r': 'Rusa',
    's': 'Singa', 't': 'Tikus', 'u': 'Ulat',
    'v': 'Vas', 'w': 'Wortel', 'x': 'Xilofon',
    'y': 'Yoyo', 'z': 'Zebra',
  };
}

class AppAudio {
  // Method untuk huruf dan kata
  static String huruf(String letter) => 'assets/audio/huruf/$letter.mp3';
  static String kata(String word) => 'assets/audio/kata/$word.mp3';

  // Instruksi
  static const String introHuruf = 'assets/audio/instruksi/intro_huruf.mp3';
  static const String introDengar = 'assets/audio/instruksi/intro_dengar.mp3';
  static const String introSusun = 'assets/audio/instruksi/intro_susun.mp3';
  static const String introPilih = 'assets/audio/instruksi/intro_pilih.mp3';
  static const String introPilihGambar = 'assets/audio/instruksi/intro_pilihgambar.mp3';
  static const String introGameHurufHilang = 'assets/audio/instruksi/intro_game_hurufhilang.mp3';
  static const String introHurufBesarKecil = 'assets/audio/instruksi/intro_huruf_besar_kecil.mp3';
  static const String introAwalKata = 'assets/audio/instruksi/intro_awal_kata.mp3';
  static const String introUrutkan = 'assets/audio/instruksi/intro_urutkan.mp3';
  static const String feedbackBenar = 'assets/audio/instruksi/feedback_benar.mp3';
  static const String feedbackBenar2 = 'assets/audio/instruksi/feedback_benar2.mp3';
  static const String feedbackBenar3 = 'assets/audio/instruksi/feedback_benar3.mp3';
  static const String feedbackSalah = 'assets/audio/instruksi/feedback_salah.mp3';
  static const String feedbackSalah2 = 'assets/audio/instruksi/feedback_salah2.mp3';
  static const String feedbackSalah3 = 'assets/audio/instruksi/feedback_salah3.mp3';
  static const String levelNaik = 'assets/audio/instruksi/level_naik.mp3';
  static const String levelSelesai = 'assets/audio/instruksi/level_selesai.mp3';
  static const String mulaiBelajar = 'assets/audio/instruksi/mulai_belajar.mp3';
  static const String selamatDatang = 'assets/audio/instruksi/selamat_datang.mp3';
  static const String semangat = 'assets/audio/instruksi/semangat.mp3';
  static const String bintang1 = 'assets/audio/instruksi/bintang_1.mp3';
  static const String bintang2 = 'assets/audio/instruksi/bintang_2.mp3';
  static const String bintang3 = 'assets/audio/instruksi/bintang_3.mp3';

  // BGM
  static const String bgmHome = 'assets/audio/music/bgm_home.mp3';
  static const String bgmStage = 'assets/audio/music/bgm_stage.mp3';
  static const String bgmResultGood = 'assets/audio/music/bgm_result_good.mp3';
  static const String bgmLevelUp = 'assets/audio/music/bgm_level_up.mp3';
  static const String bgmResultFail = 'assets/audio/music/bgm_result_fail.mp3';
}
