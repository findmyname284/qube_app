import 'package:flutter/material.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/models/me.dart';
import 'package:qube/screens/bookings_screen.dart';
import 'package:qube/screens/computers_screen.dart';
import 'package:qube/screens/news_screen.dart';
import 'package:qube/screens/profile_screen.dart';
import 'package:qube/screens/splash_screen.dart';

void main() => runApp(const QubeApp());

class QubeApp extends StatelessWidget {
  const QubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qube Cyber lounge',
      theme: ThemeData.dark(),
      home: const SplashScreen(),
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

  void _onMapModeChanged(bool isMap) {
    setState(() {
      _disableSwipe = isMap && _currentIndex == 0;
    });
  }

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

  void _onLoggedIn(Profile p) {
    setState(() {
      _profile = p;
      if (_currentIndex >= 4) _currentIndex = 4;
    });
  }

  void _onLoggedOut() {
    setState(() {
      _profile = null;
      if (_currentIndex >= 3) _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = _isLoggedIn
        ? [
            ComputersScreen(
              computers: widget.computers,
              onMapModeChanged: _onMapModeChanged,
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
              onMapModeChanged: _onMapModeChanged,
            ),
            const NewsScreen(),
            ProfileScreen(
              tariffs: const [],
              onLoggedIn: _onLoggedIn,
              onLoggedOut: _onLoggedOut,
            ),
          ];

    final navItems = _isLoggedIn
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.computer),
              label: "Компьютеры",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper),
              label: "Новости",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_online),
              label: "Брони",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_box),
              label: "Профиль",
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.computer),
              label: "Компьютеры",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper),
              label: "Новости",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_box),
              label: "Профиль",
            ),
          ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: _disableSwipe
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        children: screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            if (index != 0) {
              _disableSwipe = false;
            }
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index != 0) _disableSwipe = false;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        },
        items: navItems,
      ),
    );
  }
}
