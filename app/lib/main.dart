import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeShell(),
    );
  }
}

enum _HomeTab {
  dashboard,
  laporan,
  notifikasi,
  akun,
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  _HomeTab _tab = _HomeTab.dashboard;

  int get _currentIndex => _HomeTab.values.indexOf(_tab);

  void _onTapNav(int index) {
    final next = _HomeTab.values[index];
    switch (next) {
      case _HomeTab.dashboard:
      case _HomeTab.laporan:
        setState(() => _tab = next);
        return;
      case _HomeTab.notifikasi:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const UnderConstructionPage(title: 'Notifikasi'),
          ),
        );
        return;
      case _HomeTab.akun:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const UnderConstructionPage(title: 'Akun'),
          ),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (_tab) {
      _HomeTab.dashboard => const DashboardPage(),
      _HomeTab.laporan => const LaporanPage(),
      _HomeTab.notifikasi => const SizedBox.shrink(),
      _HomeTab.akun => const SizedBox.shrink(),
    };

    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTapNav,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}

class UnderConstructionPage extends StatelessWidget {
  const UnderConstructionPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Under construction',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Admin Dashboard',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const CircleAvatar(child: Icon(Icons.person_outline)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Selamat pagi, Admin Supervisor',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _DashboardSummaryGrid(),
          const SizedBox(height: 16),
          Text(
            'Rekap Laporan Terkini',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pada bulan ini',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada laporan baru di bulan ini.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Perlu Perhatian Anda',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const _AttentionItem(
            title: 'Laporan Masuk Baru',
            subtitle: 'Membutuhkan verifikasi',
            chipLabel: 'Baru',
          ),
          const SizedBox(height: 8),
          const _AttentionItem(
            title: 'Laporan Perlu Tindak Lanjut',
            subtitle: 'Menunggu status update',
            chipLabel: 'Proses',
          ),
          const SizedBox(height: 8),
          const _AttentionItem(
            title: 'Laporan Prioritas',
            subtitle: 'Perlu segera ditangani',
            chipLabel: 'Tinggi',
          ),
        ],
      ),
    );
  }
}

class _DashboardSummaryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _SummaryCard(
          icon: Icons.inbox_outlined,
          title: 'Laporan Masuk',
          value: '0',
        ),
        _SummaryCard(
          icon: Icons.timelapse_outlined,
          title: 'Dalam Proses',
          value: '0',
        ),
        _SummaryCard(
          icon: Icons.check_circle_outline,
          title: 'Selesai',
          value: '0',
        ),
        _SummaryCard(
          icon: Icons.error_outline,
          title: 'Perlu Ditinjau',
          value: '0',
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem({
    required this.title,
    required this.subtitle,
    required this.chipLabel,
  });

  final String title;
  final String subtitle;
  final String chipLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.report_outlined),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Chip(label: Text(chipLabel)),
      ),
    );
  }
}

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Laporan'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Semua'),
              Tab(text: 'Rendah'),
              Tab(text: 'Sedang'),
              Tab(text: 'Tinggi'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const UnderConstructionPage(title: 'Buat Laporan'),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Cari ID laporan atau lokasi...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: 'Semua Prioritas',
                        items: const [
                          DropdownMenuItem(
                            value: 'Semua Prioritas',
                            child: Text('Semua Prioritas'),
                          ),
                          DropdownMenuItem(
                            value: 'Rendah',
                            child: Text('Rendah'),
                          ),
                          DropdownMenuItem(
                            value: 'Sedang',
                            child: Text('Sedang'),
                          ),
                          DropdownMenuItem(
                            value: 'Tinggi',
                            child: Text('Tinggi'),
                          ),
                        ],
                        onChanged: (_) {},
                        decoration: const InputDecoration(
                          labelText: 'Prioritas',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: 'Semua Kategori',
                        items: const [
                          DropdownMenuItem(
                            value: 'Semua Kategori',
                            child: Text('Semua Kategori'),
                          ),
                          DropdownMenuItem(
                            value: 'Jalan',
                            child: Text('Jalan'),
                          ),
                          DropdownMenuItem(
                            value: 'Penerangan',
                            child: Text('Penerangan'),
                          ),
                          DropdownMenuItem(
                            value: 'Kebersihan',
                            child: Text('Kebersihan'),
                          ),
                        ],
                        onChanged: (_) {},
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Daftar Laporan (0)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.sort),
                      label: const Text('Terbaru'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: List<Widget>.generate(
                      4,
                      (_) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.description_outlined, size: 44),
                              const SizedBox(height: 12),
                              Text(
                                'Belum Ada Laporan',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Daftar laporan akan muncul di sini\nsetelah ada laporan yang masuk.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
