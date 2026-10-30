import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _handleLogout(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Call logout
    await appState.logout();
    
    if (!context.mounted) return;
    
    // Navigate back to login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Berhasil keluar dari akun'),
        backgroundColor: AppTheme.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final user = appState.currentUser;
          
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Avatar Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.indigo.withOpacity(0.04),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.15) : Colors.indigo.withOpacity(0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryIndigo.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'M',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        user?.name ?? 'Mahasiswa Universitas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // NIM & Major
                      Text(
                        'NIM: ${user?.nim ?? '24312120'}  |  Prodi: ${user?.major ?? 'Informatika'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Email chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.indigo.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          user?.email ?? 'email@student.univ.ac.id',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 2. UTS Academic Submission Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.school_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Informasi UTS Pemrograman Mobile',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 14),
                      _buildWhiteInfoRow('Nama Mahasiswa', 'Yudistyo Herlambang'),
                      const SizedBox(height: 8),
                      _buildWhiteInfoRow('Nomor Induk Mahasiswa (NIM)', '24312120'),
                      const SizedBox(height: 8),
                      _buildWhiteInfoRow('Judul Project', 'Eventify Campus'),
                      const SizedBox(height: 8),
                      _buildWhiteInfoRow('Teknologi Backend', 'Firebase Firestore'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 3. Settings Toggle
                Text(
                  'Pengaturan Aplikasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.indigo.withOpacity(0.04),
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryIndigo.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: AppTheme.primaryIndigo,
                            size: 20,
                          ),
                        ),
                        title: const Text('Notifikasi Event', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          appState.notificationsEnabled ? 'Aktif (Menerima pengingat event)' : 'Tidak Aktif (Notifikasi dimatikan)',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Switch(
                          value: appState.notificationsEnabled,
                          onChanged: (val) {
                            appState.toggleNotifications(val);
                            _showNotificationSwitchMessage(context, val);
                          },
                          activeColor: AppTheme.primaryIndigo,
                        ),
                      ),
                      const Divider(height: 1, indent: 60),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_done_rounded,
                            color: AppTheme.successGreen,
                            size: 20,
                          ),
                        ),
                        title: const Text('Status Koneksi Firebase', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text(
                          'Terhubung secara real-time ke Firestore',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 4. Log Out Action
                ElevatedButton(
                  onPressed: () => _handleLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPink.withOpacity(0.12),
                    foregroundColor: AppTheme.accentPink,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: AppTheme.accentPink, width: 1),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Keluar Akun (Log Out)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNotificationSwitchMessage(BuildContext context, bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled 
              ? 'Notifikasi berhasil diaktifkan.'
              : 'Notifikasi berhasil dimatikan.',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: enabled ? AppTheme.successGreen : AppTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildWhiteInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
