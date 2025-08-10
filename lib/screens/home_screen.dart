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
    'PELANGGAN',
    'PENCATATAN',
    'KEUANGAN'
  ];

  void _onDrawerTap(Widget page) {
    Navigator.pop(context); // Close the drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color(0xFF2196F3),
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            _titles[_currentIndex],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.yellow,
                shape: BoxShape.circle,
              ),
              child: ClipOval( // biar gambar ikut bentuk lingkaran
                child: Image.asset(
                  'assets/images/PROFIL.PNG',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF42A5F5), // Light blue at top
                Color(0xFF2196F3), // Main blue
              ],
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
                child: Row(
                  children: [
                    Text(
                      'Menu Tambahan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
              
              // Divider line
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                height: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              
              // Menu items
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      _buildDrawerItem(
                        icon: Icons.add_box_outlined,
                        title: 'Tambah Catat Meter (Cater)',
                        onTap: () => _onDrawerTap(const TambahCaterScreen()),
                      ),
                      SizedBox(height: 20),
                      _buildDrawerItem(
                        icon: Icons.monetization_on_outlined,
                        title: 'Tambah Tarif Manual',
                        onTap: () => _onDrawerTap(const TambahTarifScreen()),
                      ),
                      SizedBox(height: 20),
                      _buildDrawerItem(
                        icon: Icons.edit_outlined,
                        title: 'Edit Tarif',
                        onTap: () => _onDrawerTap(const EditTarifScreen()),
                      ),
                      SizedBox(height: 20),
                      _buildDrawerItem(
                        icon: Icons.edit_document,
                        title: 'Edit Catat Meter (Cater)',
                        onTap: () => _onDrawerTap(const EditCaterScreen()),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Wave decoration at bottom
              CustomPaint(
                size: Size(double.infinity, 120),
                painter: DrawerWavePainter(),
              ),
            ],
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: Stack(
        children: [
          // Bottom navigation background (white box)
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   right: 0,
          //   child: Container(
          //     height: 70,
          //     color: Colors.white,
          //   ),
          // ),
          // Wave decorations
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 100),
            painter: WavePainter(),
          ),
          // Navigation items
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.people,
                    index: 0,
                    isSelected: currentIndex == 0,
                  ),
                  _buildNavItem(
                    icon: Icons.assignment,
                    index: 1,
                    isSelected: currentIndex == 1,
                  ),
                  _buildNavItem(
                    icon: Icons.attach_money,
                    index: 2,
                    isSelected: currentIndex == 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: isSelected ? 60 : 50,
        height: isSelected ? 60 : 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black,
          size: isSelected ? 32 : 24,
        ),
      ),
    );
  }
}

class DrawerWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Light blue wave (back layer)
    final lightBluePaint = Paint()
      ..color = Color(0xFF90CAF9)
      ..style = PaintingStyle.fill;

    final lightBluePath = Path();
    lightBluePath.moveTo(0, size.height * 0.3);
    lightBluePath.quadraticBezierTo(
      size.width * 0.25, size.height * 0.1,
      size.width * 0.5, size.height * 0.4,
    );
    lightBluePath.quadraticBezierTo(
      size.width * 0.75, size.height * 0.7,
      size.width, size.height * 0.2,
    );
    lightBluePath.lineTo(size.width, size.height);
    lightBluePath.lineTo(0, size.height);
    lightBluePath.close();

    canvas.drawPath(lightBluePath, lightBluePaint);

    // Yellow wave (front layer)
    final yellowPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    final yellowPath = Path();
    yellowPath.moveTo(0, size.height * 0.6);
    yellowPath.quadraticBezierTo(
      size.width * 0.2, size.height * 0.3,
      size.width * 0.4, size.height * 0.7,
    );
    yellowPath.quadraticBezierTo(
      size.width * 0.6, size.height * 0.9,
      size.width * 0.8, size.height * 0.5,
    );
    yellowPath.quadraticBezierTo(
      size.width * 0.9, size.height * 0.3,
      size.width, size.height * 0.6,
    );
    yellowPath.lineTo(size.width, size.height);
    yellowPath.lineTo(0, size.height);
    yellowPath.close();

    canvas.drawPath(yellowPath, yellowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Yellow wave (back layer)
    final yellowPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    final yellowPath = Path();
    yellowPath.moveTo(0, size.height * 0.7);
    
    // Create flowing wave for yellow
    yellowPath.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.4);
    yellowPath.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.3);
    
    yellowPath.lineTo(size.width, size.height);
    yellowPath.lineTo(0, size.height);
    yellowPath.close();

    canvas.drawPath(yellowPath, yellowPaint);

    // Blue wave (front layer)
    final bluePaint = Paint()
      ..color = const Color(0xFF64B5F6) // Lighter blue for contrast
      ..style = PaintingStyle.fill;

    final bluePath = Path();
    bluePath.moveTo(0, size.height * 0.8);
    
    // Create flowing wave for blue (different curve)
    bluePath.quadraticBezierTo(size.width * 0.2, size.height * 0.2, size.width * 0.4, size.height * 0.6);
    bluePath.quadraticBezierTo(size.width * 0.6, size.height, size.width * 0.8, size.height * 0.4);
    bluePath.quadraticBezierTo(size.width * 0.9, size.height * 0.1, size.width, size.height * 0.5);
    
    bluePath.lineTo(size.width, size.height);
    bluePath.lineTo(0, size.height);
    bluePath.close();

    canvas.drawPath(bluePath, bluePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}