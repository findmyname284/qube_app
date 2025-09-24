import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/models/me.dart';
import 'package:qube/screens/bookings_screen.dart';
import 'package:qube/screens/computers_screen.dart';
import 'package:qube/screens/news_screen.dart';
import 'package:qube/screens/profile_screen.dart';
import 'package:qube/screens/splash_screen.dart';
import 'package:qube/utils/app_snack.dart';

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
        // color: const Color(0xFF161821),
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
        indicatorColor: colorSchemeDark.primary.withOpacity(.18),
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
  final List<Computer> computers;
  final Profile? profile;
  const MainPage({super.key, required this.computers, this.profile});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _disableSwipe = false;
  Profile? _profile;
  bool _isMapView = false;
  bool _showFab = true;

  bool get _isLoggedIn => _profile != null;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onMapModeChanged(bool isMap) {
    setState(() {
      _isMapView = isMap;
      _disableSwipe = isMap;
    });
  }

  void _onFabVisibilityChanged(bool visible) {
    setState(() {
      _showFab = visible;
    });
  }

  void _onLoggedIn(Profile p) {
    setState(() {
      _profile = p;
      if (_currentIndex >= 3) {
        _currentIndex = 3;
        _pageController.animateToPage(
          3,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _pageController.jumpToPage(3);
      }
    });
  }

  void _onLoggedOut() {
    setState(() {
      _profile = null;
      if (_currentIndex >= 2) {
        _currentIndex = 0;
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _pageController.jumpToPage(0);
      }
    });
  }

  void _toggleMapView() {
    setState(() {
      _isMapView = !_isMapView;
      _disableSwipe = _isMapView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = _isLoggedIn
        ? [
            ComputersScreen(
              computers: widget.computers,
              isMapView: _isMapView,
              onMapModeChanged: _onMapModeChanged,
              onToggleView: _toggleMapView,
              onFabVisibilityChanged: _onFabVisibilityChanged,
            ),
            const NewsScreen(),
            const BookingsScreen(),
            ProfileScreen(
              tariffs: const [],
              profile: widget.profile,
              onLoggedIn: _onLoggedIn,
              onLoggedOut: _onLoggedOut,
            ),
          ]
        : [
            ComputersScreen(
              computers: widget.computers,
              isMapView: _isMapView,
              onMapModeChanged: _onMapModeChanged,
              onToggleView: _toggleMapView,
              onFabVisibilityChanged: _onFabVisibilityChanged,
            ),
            const NewsScreen(),
            ProfileScreen(
              tariffs: const [],
              onLoggedIn: _onLoggedIn,
              onLoggedOut: _onLoggedOut,
            ),
          ];

    final navDestinations = _isLoggedIn
        ? const [
            NavigationDestination(
              icon: Icon(Icons.computer_outlined),
              selectedIcon: Icon(Icons.computer),
              label: 'Компьютеры',
            ),
            NavigationDestination(
              icon: Icon(Icons.newspaper_outlined),
              selectedIcon: Icon(Icons.newspaper),
              label: 'Новости',
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
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.computer_outlined),
              selectedIcon: Icon(Icons.computer),
              label: 'Компьютеры',
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

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0E0F13), Color(0xFF0E0F13), Color(0xFF0B0C10)],
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
            onPageChanged: (index) => setState(() {
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
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _currentIndex == 0 && _showFab
          ? Container(
              margin: const EdgeInsets.only(bottom: 72),
              child: FloatingActionButton.extended(
                onPressed: _toggleMapView,
                icon: Icon(_isMapView ? Icons.list : Icons.explore),
                label: Text(_isMapView ? 'Список компьютеров' : 'Обзор клуба'),
              ),
            )
          : null,
    );
  }
}
