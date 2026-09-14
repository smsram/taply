import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
  ];

  static Locale? parseLocale(String languageSetting) {
    switch (languageSetting) {
      case 'Español':
        return const Locale('es');
      case 'Français':
        return const Locale('fr');
      case 'Deutsch':
        return const Locale('de');
      case '日本語':
        return const Locale('ja');
      case '한국어':
        return const Locale('ko');
      case 'Português':
        return const Locale('pt');
      case 'English (US)':
        return const Locale('en');
      case 'System default':
      default:
        return null;
    }
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Taply',
      'tagline': 'Everything, one tap away.',
      'home': 'Home',
      'apps': 'Apps',
      'tools': 'Tools',
      'customize': 'Customize',
      'settings': 'Settings',
      'quickControls': 'Quick Controls',
      'systemActions': 'System Actions',
      'floatingButton': 'Floating Button',
      'serviceRunning': 'Overlay service is active',
      'serviceStopped': 'Overlay service is inactive',
      'startService': 'Start Service',
      'stopService': 'Stop Service',
      'searchApps': 'Search apps...',
      'noAppsFound': 'No applications found',
      'refresh': 'Refresh',
      'favorites': 'Favorites',
      'allApps': 'All Apps',
      'recent': 'Recent',
      'calculator': 'Calculator',
      'stopwatch': 'Stopwatch',
      'timer': 'Timer',
      'notes': 'Quick Notes',
      'qrStudio': 'QR Code Studio',
      'deviceInfo': 'Device Telemetry',
      'batteryDiagnostics': 'Battery Diagnostics',
      'storageAnalyzer': 'Storage Analyzer',
      'unitConverter': 'Unit Converter',
      'compass': 'Digital Compass',
      'screenMagnifier': 'Screen Magnifier',
      'flashlight': 'Flashlight',
      'brightness': 'Brightness',
      'mediaVolume': 'Media Volume',
      'ringVolume': 'Ring Volume',
      'silent': 'Silent',
      'vibrate': 'Vibrate',
      'normal': 'Normal',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'language': 'Language',
      'hapticFeedback': 'Haptic Feedback',
      'permissions': 'Permissions',
      'about': 'About',
      'version': 'Version',
      'reset': 'Reset',
      'cancel': 'Cancel',
      'save': 'Save',
      'done': 'Done',
      'start': 'Start',
      'pause': 'Pause',
      'resume': 'Resume',
      'clear': 'Clear',
      'copy': 'Copy',
      'share': 'Share',
      'scan': 'Scan',
      'generate': 'Generate',
      'selectLanguage': 'Select Language',
      'lockScreen': 'Lock Screen',
      'recentApps': 'Recent Apps',
      'back': 'Back',
      'volume': 'Volume',
      'screenshot': 'Screenshot',
      'favoriteApps': 'Favorite Apps',
      'recentlyUsed': 'Recently Used',
      'floatingAssistant': 'Floating Assistant',
    },
    'es': {
      'appName': 'Taply',
      'tagline': 'Todo, a un toque de distancia.',
      'home': 'Inicio',
      'apps': 'Aplicaciones',
      'tools': 'Herramientas',
      'customize': 'Personalizar',
      'settings': 'Ajustes',
      'quickControls': 'Controles rápidos',
      'systemActions': 'Acciones del sistema',
      'floatingButton': 'Botón flotante',
      'serviceRunning': 'El servicio superpuesto está activo',
      'serviceStopped': 'El servicio superpuesto está inactivo',
      'startService': 'Iniciar servicio',
      'stopService': 'Detener servicio',
      'searchApps': 'Buscar aplicaciones...',
      'noAppsFound': 'No se encontraron aplicaciones',
      'refresh': 'Actualizar',
      'favorites': 'Favoritos',
      'allApps': 'Todas las apps',
      'recent': 'Recientes',
      'calculator': 'Calculadora',
      'stopwatch': 'Cronómetro',
      'timer': 'Temporizador',
      'notes': 'Notas rápidas',
      'qrStudio': 'Estudio QR',
      'deviceInfo': 'Telemetría del dispositivo',
      'batteryDiagnostics': 'Diagnóstico de batería',
      'storageAnalyzer': 'Analizador de espacio',
      'unitConverter': 'Convertidor de unidades',
      'compass': 'Brújula digital',
      'screenMagnifier': 'Lupa de pantalla',
      'flashlight': 'Linterna',
      'brightness': 'Brillo',
      'mediaVolume': 'Volumen multimedia',
      'ringVolume': 'Volumen de llamada',
      'silent': 'Silencio',
      'vibrate': 'Vibración',
      'normal': 'Normal',
      'appearance': 'Apariencia',
      'theme': 'Tema',
      'language': 'Idioma',
      'hapticFeedback': 'Respuesta háptica',
      'permissions': 'Permisos',
      'about': 'Acerca de',
      'version': 'Versión',
      'reset': 'Restablecer',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'done': 'Listo',
      'start': 'Iniciar',
      'pause': 'Pausa',
      'resume': 'Reanudar',
      'clear': 'Borrar',
      'copy': 'Copiar',
      'share': 'Compartir',
      'scan': 'Escanear',
      'generate': 'Generar',
      'selectLanguage': 'Seleccionar idioma',
    },
    'fr': {
      'appName': 'Taply',
      'tagline': 'Tout, à portée d’un clic.',
      'home': 'Accueil',
      'apps': 'Applications',
      'tools': 'Outils',
      'customize': 'Personnaliser',
      'settings': 'Paramètres',
      'quickControls': 'Contrôles rapides',
      'systemActions': 'Actions système',
      'floatingButton': 'Bouton flottant',
      'serviceRunning': 'Le service flottant est actif',
      'serviceStopped': 'Le service flottant est inactif',
      'startService': 'Démarrer le service',
      'stopService': 'Arrêter le service',
      'searchApps': 'Rechercher une application...',
      'noAppsFound': 'Aucune application trouvée',
      'refresh': 'Actualiser',
      'favorites': 'Favoris',
      'allApps': 'Toutes les applis',
      'recent': 'Récents',
      'calculator': 'Calculatrice',
      'stopwatch': 'Chronomètre',
      'timer': 'Minuteur',
      'notes': 'Notes rapides',
      'qrStudio': 'Studio code QR',
      'deviceInfo': 'Télémétrie de l’appareil',
      'batteryDiagnostics': 'Diagnostic batterie',
      'storageAnalyzer': 'Analyseur de stockage',
      'unitConverter': 'Convertisseur d’unités',
      'compass': 'Boussole numérique',
      'screenMagnifier': 'Loupe d’écran',
      'flashlight': 'Lampe torche',
      'brightness': 'Luminosité',
      'mediaVolume': 'Volume média',
      'ringVolume': 'Volume sonnerie',
      'silent': 'Silencieux',
      'vibrate': 'Vibreur',
      'normal': 'Normal',
      'appearance': 'Apparence',
      'theme': 'Thème',
      'language': 'Langue',
      'hapticFeedback': 'Retour haptique',
      'permissions': 'Autorisations',
      'about': 'À propos',
      'version': 'Version',
      'reset': 'Réinitialiser',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'done': 'Terminé',
      'start': 'Démarrer',
      'pause': 'Pause',
      'resume': 'Reprendre',
      'clear': 'Effacer',
      'copy': 'Copier',
      'share': 'Partager',
      'scan': 'Scanner',
      'generate': 'Générer',
      'selectLanguage': 'Choisir la langue',
    },
    'de': {
      'appName': 'Taply',
      'tagline': 'Alles mit einem Fingertipp.',
      'home': 'Startseite',
      'apps': 'Apps',
      'tools': 'Werkzeuge',
      'customize': 'Anpassen',
      'settings': 'Einstellungen',
      'quickControls': 'Schnellsteuerung',
      'systemActions': 'Systemaktionen',
      'floatingButton': 'Schwebende Taste',
      'serviceRunning': 'Overlay-Dienst ist aktiv',
      'serviceStopped': 'Overlay-Dienst ist inaktiv',
      'startService': 'Dienst starten',
      'stopService': 'Dienst beenden',
      'searchApps': 'Apps durchsuchen...',
      'noAppsFound': 'Keine Apps gefunden',
      'refresh': 'Aktualisieren',
      'favorites': 'Favoriten',
      'allApps': 'Alle Apps',
      'recent': 'Zuletzt',
      'calculator': 'Rechner',
      'stopwatch': 'Stoppuhr',
      'timer': 'Timer',
      'notes': 'Schnellnotizen',
      'qrStudio': 'QR-Code-Studio',
      'deviceInfo': 'Gerätetelemetrie',
      'batteryDiagnostics': 'Batterie-Diagnose',
      'storageAnalyzer': 'Speicheranalyse',
      'unitConverter': 'Einheitenumrechner',
      'compass': 'Digitaler Kompass',
      'screenMagnifier': 'Bildschirmlupe',
      'flashlight': 'Taschenlampe',
      'brightness': 'Helligkeit',
      'mediaVolume': 'Medienlautstärke',
      'ringVolume': 'Klingeltonlautstärke',
      'silent': 'Lautlos',
      'vibrate': 'Vibrieren',
      'normal': 'Normal',
      'appearance': 'Erscheinungsbild',
      'theme': 'Design',
      'language': 'Sprache',
      'hapticFeedback': 'Haptisches Feedback',
      'permissions': 'Berechtigungen',
      'about': 'Über',
      'version': 'Version',
      'reset': 'Zurücksetzen',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'done': 'Fertig',
      'start': 'Start',
      'pause': 'Pause',
      'resume': 'Fortsetzen',
      'clear': 'Löschen',
      'copy': 'Kopieren',
      'share': 'Teilen',
      'scan': 'Scannen',
      'generate': 'Erstellen',
      'selectLanguage': 'Sprache auswählen',
    },
    'ja': {
      'appName': 'Taply',
      'tagline': 'すべてがワンタップで。',
      'home': 'ホーム',
      'apps': 'アプリ',
      'tools': 'ツール',
      'customize': 'カスタマイズ',
      'settings': '設定',
      'quickControls': 'クイック操作',
      'systemActions': 'システム操作',
      'floatingButton': 'フローティングボタン',
      'serviceRunning': 'オーバーレイ実行中',
      'serviceStopped': 'オーバーレイ停止中',
      'startService': 'サービス開始',
      'stopService': 'サービス停止',
      'searchApps': 'アプリを検索...',
      'noAppsFound': 'アプリが見つかりません',
      'refresh': '更新',
      'favorites': 'お気に入り',
      'allApps': 'すべてのアプリ',
      'recent': '最近',
      'calculator': '電卓',
      'stopwatch': 'ストップウォッチ',
      'timer': 'タイマー',
      'notes': 'クイックメモ',
      'qrStudio': 'QRコードスタジオ',
      'deviceInfo': '端末情報',
      'batteryDiagnostics': 'バッテリー診断',
      'storageAnalyzer': 'ストレージ分析',
      'unitConverter': '単位換算',
      'compass': 'デジタルコンパス',
      'screenMagnifier': '拡大鏡',
      'flashlight': '懐中電灯',
      'brightness': '画面の明るさ',
      'mediaVolume': 'メディア音量',
      'ringVolume': '着信音量',
      'silent': 'サイレント',
      'vibrate': 'バイブ',
      'normal': '通常',
      'appearance': '外観',
      'theme': 'テーマ',
      'language': '言語',
      'hapticFeedback': '触覚フィードバック',
      'permissions': '権限',
      'about': 'アプリについて',
      'version': 'バージョン',
      'reset': 'リセット',
      'cancel': 'キャンセル',
      'save': '保存',
      'done': '完了',
      'start': '開始',
      'pause': '一時停止',
      'resume': '再開',
      'clear': 'クリア',
      'copy': 'コピー',
      'share': '共有',
      'scan': 'スキャン',
      'generate': '作成',
      'selectLanguage': '言語を選択',
    },
    'ko': {
      'appName': 'Taply',
      'tagline': '한 번의 탭으로 모든 것을.',
      'home': '홈',
      'apps': '앱',
      'tools': '도구',
      'customize': '맞춤설정',
      'settings': '설정',
      'quickControls': '빠른 제어',
      'systemActions': '시스템 작업',
      'floatingButton': '플로팅 버튼',
      'serviceRunning': '오버레이 서비스 실행 중',
      'serviceStopped': '오버레이 서비스 정지됨',
      'startService': '서비스 시작',
      'stopService': '서비스 중지',
      'searchApps': '앱 검색...',
      'noAppsFound': '설치된 앱이 없습니다',
      'refresh': '새로고침',
      'favorites': '즐겨찾기',
      'allApps': '전체 앱',
      'recent': '최근',
      'calculator': '계산기',
      'stopwatch': '스톱워치',
      'timer': '타이머',
      'notes': '빠른 메모',
      'qrStudio': 'QR 코드 스튜디오',
      'deviceInfo': '기기 원격측정',
      'batteryDiagnostics': '배터리 진단',
      'storageAnalyzer': '저장공간 분석',
      'unitConverter': '단위 변환기',
      'compass': '디지털 나침반',
      'screenMagnifier': '화면 돋보기',
      'flashlight': '손전등',
      'brightness': '화면 밝기',
      'mediaVolume': '미디어 음량',
      'ringVolume': '벨소리 음량',
      'silent': '무음',
      'vibrate': '진동',
      'normal': '보통',
      'appearance': '화면 구성',
      'theme': '테마',
      'language': '언어',
      'hapticFeedback': '진동 피드백',
      'permissions': '권한',
      'about': '앱 정보',
      'version': '버전',
      'reset': '초기화',
      'cancel': '취소',
      'save': '저장',
      'done': '완료',
      'start': '시작',
      'pause': '일시정지',
      'resume': '다시시작',
      'clear': '지우기',
      'copy': '복사',
      'share': '공유',
      'scan': '스캔',
      'generate': '생성',
      'selectLanguage': '언어 선택',
    },
    'pt': {
      'appName': 'Taply',
      'tagline': 'Tudo a um toque de distância.',
      'home': 'Início',
      'apps': 'Apps',
      'tools': 'Ferramentas',
      'customize': 'Personalizar',
      'settings': 'Configurações',
      'quickControls': 'Controles Rápidos',
      'systemActions': 'Ações do Sistema',
      'floatingButton': 'Botão Flutuante',
      'serviceRunning': 'Serviço de sobreposição ativo',
      'serviceStopped': 'Serviço de sobreposição inativo',
      'startService': 'Iniciar Serviço',
      'stopService': 'Parar Serviço',
      'searchApps': 'Pesquisar apps...',
      'noAppsFound': 'Nenhum app encontrado',
      'refresh': 'Atualizar',
      'favorites': 'Favoritos',
      'allApps': 'Todos os apps',
      'recent': 'Recentes',
      'calculator': 'Calculadora',
      'stopwatch': 'Cronômetro',
      'timer': 'Temporizador',
      'notes': 'Notas Rápidas',
      'qrStudio': 'Estúdio QR',
      'deviceInfo': 'Telemetria do Dispositivo',
      'batteryDiagnostics': 'Diagnóstico de Bateria',
      'storageAnalyzer': 'Analisador de Armazenamento',
      'unitConverter': 'Conversor de Unidades',
      'compass': 'Bússola Digital',
      'screenMagnifier': 'Lupa de Tela',
      'flashlight': 'Lanterna',
      'brightness': 'Brilho',
      'mediaVolume': 'Volume de Mídia',
      'ringVolume': 'Volume de Toque',
      'silent': 'Silencioso',
      'vibrate': 'Vibrar',
      'normal': 'Normal',
      'appearance': 'Aparência',
      'theme': 'Tema',
      'language': 'Idioma',
      'hapticFeedback': 'Retorno Tátil',
      'permissions': 'Permissões',
      'about': 'Sobre',
      'version': 'Versão',
      'reset': 'Redefinir',
      'cancel': 'Cancelar',
      'save': 'Salvar',
      'done': 'Concluído',
      'start': 'Iniciar',
      'pause': 'Pausar',
      'resume': 'Continuar',
      'clear': 'Limpar',
      'copy': 'Copiar',
      'share': 'Compartilhar',
      'scan': 'Escanear',
      'generate': 'Gerar',
      'selectLanguage': 'Selecionar Idioma',
    },
  };

  String tr(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  String get appName => tr('appName');
  String get tagline => tr('tagline');
  String get home => tr('home');
  String get apps => tr('apps');
  String get tools => tr('tools');
  String get customize => tr('customize');
  String get settings => tr('settings');
  String get quickControls => tr('quickControls');
  String get systemActions => tr('systemActions');
  String get floatingButton => tr('floatingButton');
  String get serviceRunning => tr('serviceRunning');
  String get serviceStopped => tr('serviceStopped');
  String get startService => tr('startService');
  String get stopService => tr('stopService');
  String get searchApps => tr('searchApps');
  String get noAppsFound => tr('noAppsFound');
  String get refresh => tr('refresh');
  String get favorites => tr('favorites');
  String get allApps => tr('allApps');
  String get recent => tr('recent');
  String get calculator => tr('calculator');
  String get stopwatch => tr('stopwatch');
  String get timer => tr('timer');
  String get notes => tr('notes');
  String get qrStudio => tr('qrStudio');
  String get deviceInfo => tr('deviceInfo');
  String get batteryDiagnostics => tr('batteryDiagnostics');
  String get storageAnalyzer => tr('storageAnalyzer');
  String get unitConverter => tr('unitConverter');
  String get compass => tr('compass');
  String get screenMagnifier => tr('screenMagnifier');
  String get flashlight => tr('flashlight');
  String get brightness => tr('brightness');
  String get mediaVolume => tr('mediaVolume');
  String get ringVolume => tr('ringVolume');
  String get silent => tr('silent');
  String get vibrate => tr('vibrate');
  String get normal => tr('normal');
  String get appearance => tr('appearance');
  String get theme => tr('theme');
  String get language => tr('language');
  String get hapticFeedback => tr('hapticFeedback');
  String get permissions => tr('permissions');
  String get about => tr('about');
  String get version => tr('version');
  String get reset => tr('reset');
  String get cancel => tr('cancel');
  String get save => tr('save');
  String get done => tr('done');
  String get start => tr('start');
  String get pause => tr('pause');
  String get resume => tr('resume');
  String get clear => tr('clear');
  String get copy => tr('copy');
  String get share => tr('share');
  String get scan => tr('scan');
  String get generate => tr('generate');
  String get selectLanguage => tr('selectLanguage');
  String get lockScreen => tr('lockScreen');
  String get recentApps => tr('recentApps');
  String get back => tr('back');
  String get volume => tr('volume');
  String get screenshot => tr('screenshot');
  String get quickActions => tr('quickActions');
  String get favoriteApps => tr('favoriteApps');
  String get recentlyUsed => tr('recentlyUsed');
  String get floatingAssistant => tr('floatingAssistant');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return [
      'en',
      'es',
      'fr',
      'de',
      'ja',
      'ko',
      'pt',
    ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
