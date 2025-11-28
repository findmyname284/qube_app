import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/models/me.dart';
import 'package:qube/screens/profile/models/tariff.dart';
import 'package:qube/screens/bookings/bookings_screen.dart';
import 'package:qube/screens/computers/computers_screen.dart';
import 'package:qube/screens/news/news_screen.dart';
import 'package:qube/screens/profile/profile_screen.dart';
import 'package:qube/screens/qr_auth_screen.dart';
import 'package:qube/screens/splash_screen.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/utils/app_snack.dart';
import 'package:qube/utils/helper.dart';

final api = ApiService.instance;

void main() => runApp(const QubeApp());

class QubeApp extends StatelessWidget {
  const QubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6C5CE7);

    final colorSchemeDark = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorSchemeDark,
      scaffoldBackgroundColor: const Color(0xFF0E0F13),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: colorSchemeDark.primary.withAlpha(46), // 0.18 ~ 46/255
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorSchemeDark.primary);
          }
          return const IconThemeData();
        }),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0E0F13),
      ),
    );

    return MaterialApp(
      title: 'Qube Cyber lounge',
      //   debugShowCheckedModeBanner: false,
      theme: theme,
      home: const SplashScreen(),
      scaffoldMessengerKey: appMessengerKey,
    );
  }
}

class MainPage extends StatefulWidget {
  final List<Computer>? computers;
  final Profile? profile;
  final List<Tariff>? tariffs;

  const MainPage({super.key, this.computers, this.profile, this.tariffs});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _disableSwipe = false;
  // Сделали профиль реактивным
  late final ValueNotifier<Profile?> _profileNotifier;
  bool _isMapView = false;
  bool _showFab = true;

  bool get _isLoggedIn => _profileNotifier.value != null;

  @override
  void initState() {
    super.initState();
    _profileNotifier = ValueNotifier<Profile?>(widget.profile);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _profileNotifier.dispose();
    super.dispose();
  }

  // --- State mutation helpers ---
  void _setMapMode(bool isMap) {
    setStateSafe(() {
      _isMapView = isMap;
      _disableSwipe = isMap;
    });
  }

  void _setFabVisible(bool visible) {
    setStateSafe(() {
      _showFab = visible;
    });
  }

  void _onLoggedIn(Profile p) {
    // обновляем reactive профиль
    _profileNotifier.value = p;

    // сохраняем индекс и при необходимости переходим
    if (_currentIndex >= (_isLoggedIn ? 4 : 2)) {
      _goToPage(_isLoggedIn ? 4 : 2); // Переходим на профиль
    } else {
      // если нужно — просто обновить UI
      setStateSafe(() {});
    }
  }

  void _onLoggedOut() {
    _profileNotifier.value = null;
    if (_currentIndex >= 2) {
      _goToPage(0);
    } else {
      setStateSafe(() {});
    }
  }

  void _toggleMapView() {
    setStateSafe(() {
      _isMapView = !_isMapView;
      _disableSwipe = _isMapView;
    });
  }

  void _goToPage(int index) {
    if (!mounted) return;
    setStateSafe(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  List<Widget> _buildScreens(Profile? currentProfile) {
    if (_isLoggedIn) {
      // Авторизован: 5 экранов
      return [
        ComputersScreen(
          key: const ValueKey('computers'),
          computers: widget.computers ?? [],
          isMapView: _isMapView,
          onMapModeChanged: _setMapMode,
          onToggleView: _toggleMapView,
          onFabVisibilityChanged: _setFabVisible,
        ),
        const NewsScreen(key: ValueKey('news')),
        QrScanScreen(
          // Новый экран QR-авторизации
          key: const ValueKey('qr_auth'),
        ),
        const BookingsScreen(key: ValueKey('bookings')),
        ProfileScreen(
          key: const ValueKey('profile'),
          profile: currentProfile,
          onLoggedIn: _onLoggedIn,
          onLoggedOut: _onLoggedOut,
        ),
      ];
    } else {
      // Не авторизован: 3 экрана
      return [
        ComputersScreen(
          key: const ValueKey('computers'),
          computers: widget.computers,
          isMapView: _isMapView,
          onMapModeChanged: _setMapMode,
          onToggleView: _toggleMapView,
          onFabVisibilityChanged: _setFabVisible,
        ),
        const NewsScreen(key: ValueKey('news')),
        ProfileScreen(
          key: const ValueKey('profile'),
          profile: currentProfile,
          onLoggedIn: _onLoggedIn,
          onLoggedOut: _onLoggedOut,
        ),
      ];
    }
  }

  List<NavigationDestination> _buildNavDestinations(bool loggedIn) {
    if (loggedIn) {
      // Авторизован: 5 пунктов
      return const [
        NavigationDestination(
          icon: Icon(Icons.computer_outlined),
          selectedIcon: Icon(Icons.computer),
          label: 'Компы',
        ),
        NavigationDestination(
          icon: Icon(Icons.newspaper_outlined),
          selectedIcon: Icon(Icons.newspaper),
          label: 'Новости',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_2_outlined),
          selectedIcon: Icon(Icons.qr_code_2),
          label: 'QR',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_online_outlined),
          selectedIcon: Icon(Icons.book_online),
          label: 'Брони',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ];
    } else {
      // Не авторизован: 3 пункта с QR в центре
      return const [
        NavigationDestination(
          icon: Icon(Icons.computer_outlined),
          selectedIcon: Icon(Icons.computer),
          label: 'Компы',
        ),
        NavigationDestination(
          icon: Icon(Icons.newspaper_outlined),
          selectedIcon: Icon(Icons.newspaper),
          label: 'Новости',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Profile?>(
      valueListenable: _profileNotifier,
      builder: (context, currentProfile, _) {
        final screens = _buildScreens(currentProfile);
        final navDestinations = _buildNavDestinations(currentProfile != null);

        return Scaffold(
          extendBody: true,
          body: SafeArea(
            bottom: false,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0E0F13),
                    Color(0xFF0E0F13),
                    Color(0xFF0B0C10),
                  ],
                ),
              ),
              child: PageView.builder(
                itemCount: screens.length,
                controller: _pageController,
                physics: _disableSwipe
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                onPageChanged: (index) => setStateSafe(() {
                  _currentIndex = index;
                  if (index != 0) {
                    _disableSwipe = false;
                    _isMapView = false;
                  }
                }),
                itemBuilder: (_, i) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: screens[i],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF12131A).withAlpha(74),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(89),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: NavigationBar(
                      selectedIndex: _currentIndex,
                      destinations: navDestinations,
                      onDestinationSelected: (index) => _goToPage(index),
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: _currentIndex == 0 && _showFab
              ? Container(
                  margin: const EdgeInsets.only(bottom: 72),
                  child: FloatingActionButton.extended(
                    onPressed: _toggleMapView,
                    icon: Icon(_isMapView ? Icons.list : Icons.explore),
                    label: Text(
                      _isMapView ? 'Список компьютеров' : 'Обзор клуба',
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
