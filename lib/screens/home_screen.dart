import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'pelanggan_screen.dart';
import 'pencatatan_screen.dart';
import 'keuangan_screen.dart';
import 'tambah_cater_screen.dart';
import 'tambah_tarif_screen.dart';
import 'edit_tarif_screen.dart';
import 'edit_cater_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const HomeScreen({required this.currentUser, Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, color: Colors.red[600], size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Konfirmasi Logout',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (Route<dynamic> route) => false,
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 35,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.currentUser['role'];
    final username = widget.currentUser['username'] ?? 'User';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color(0xFF2196F3),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEB3B),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/PROFIL.PNG',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Selamat Datang',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            StreamBuilder(
              stream: FirebaseDatabase.instance.ref(".info/connected").onValue,
              builder: (context, snapshot) {
                bool online = snapshot.data?.snapshot.value as bool? ?? false;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    online ? Icons.wifi : Icons.wifi_off,
                    color: online ? Colors.green : Colors.red,
                    size: 28,
                  ),
                );
              },
            ),
            IconButton(
              onPressed: _showLogoutConfirmation,
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: SafeArea(
        bottom: true, // Menghindari overlap dengan system navigation
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2196F3).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF2196F3)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pilih menu untuk melanjutkan',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Main Menu Grid
                const Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 20,
                    ), // Extra padding untuk system navigation
                    children: [
                      _buildMenuCard(
                        icon: Icons.people,
                        title: 'PELANGGAN',
                        subtitle: 'Kelola data pelanggan',
                        color: const Color(0xFF4CAF50),
                        onTap: () => _navigateToScreen(
                          PelangganScreen(currentUser: widget.currentUser),
                        ),
                      ),
                      _buildMenuCard(
                        icon: Icons.assignment,
                        title: 'PENCATATAN',
                        subtitle: 'Catat transaksi',
                        color: const Color(0xFFFF9800),
                        onTap: () => _navigateToScreen(
                          PencatatanScreen(currentUser: widget.currentUser),
                        ),
                      ),
                      _buildMenuCard(
                        icon: Icons.attach_money,
                        title: 'KEUANGAN',
                        subtitle: 'Laporan keuangan',
                        color: const Color(0xFF9C27B0),
                        onTap: () => _navigateToScreen(
                          KeuanganScreen(currentUser: widget.currentUser),
                        ),
                      ),
                      if (role == 'admin')
                        _buildMenuCard(
                          icon: Icons.settings,
                          title: 'ADMIN MENU',
                          subtitle: 'Menu administrasi',
                          color: const Color(0xFFE91E63),
                          onTap: () => _showAdminMenu(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showAdminMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Menu Admin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildAdminMenuItem(
                          icon: Icons.add_box_outlined,
                          title: 'Tambah Cater',
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(TambahCaterScreen(currentUser: widget.currentUser));
                          },
                        ),
                        _buildAdminMenuItem(
                          icon: Icons.monetization_on_outlined,
                          title: 'Tambah Tarif Manual',
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(TambahTarifScreen(currentUser: widget.currentUser));
                          },
                        ),
                        _buildAdminMenuItem(
                          icon: Icons.edit_outlined,
                          title: 'Edit Tarif',
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(EditTarifScreen(currentUser: widget.currentUser));
                          },
                        ),
                        _buildAdminMenuItem(
                          icon: Icons.edit_document,
                          title: 'Edit Cater',
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(EditCaterScreen(currentUser: widget.currentUser));
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAdminMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF2196F3).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF2196F3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}