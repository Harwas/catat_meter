import 'package:flutter/material.dart';
import 'pelanggan_screen.dart';
import 'pencatatan_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    PelangganScreen(),
    PencatatanScreen(),
    Placeholder(), // 🟡 Nanti ganti dengan Laporan Keuangan
  ];

  final List<String> _titles = [
    'Pelanggan',
    'Pencatatan Meteran',
    'Laporan Keuangan'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Pelanggan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Pencatatan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Keuangan',
          ),
        ],
      ),
    );
  }
}
