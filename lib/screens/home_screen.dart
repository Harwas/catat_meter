import 'package:flutter/material.dart';
import 'pelanggan_screen.dart';
import 'pencatatan_screen.dart';
import 'keuangan_screen.dart';
import 'tambah_cater_screen.dart';
import 'tambah_tarif_screen.dart';
import 'edit_tarif_screen.dart';
import 'edit_cater_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    PelangganScreen(),
    PencatatanScreen(),
    KeuanganScreen(),
  ];

  final List<String> _titles = [
    'Pelanggan',
    'Pencatatan Meteran',
    'Keuangan'
  ];

  void _onDrawerTap(Widget page) {
    Navigator.pop(context); // Close the drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Menu Tambahan', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Tambah Catat Meter (Cater)'),
              onTap: () => _onDrawerTap(const TambahCaterScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Tambah Tarif Manual'),
              onTap: () => _onDrawerTap(const TambahTarifScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Edit Tarif'),
              onTap: () => _onDrawerTap(const EditTarifScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Edit Cater'),
              onTap: () => _onDrawerTap(const EditCaterScreen()),
            ),
          ],
        ),
      ),
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