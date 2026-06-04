import 'package:flutter/material.dart';

class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({Key? key}) : super(key: key);

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  // Variabel state untuk filter (chips)
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    "Semua (5)",
    "Belum Dimulai (3)",
    "Sedang Dikerjakan (2)",
    "Mendesak"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // neutral-100 bg
      appBar: _buildOfficerAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodaySummaryCard(),
            _buildFilterChips(),
            _buildSortDropdown(),
            _buildTaskList(),
          ],
        ),
      ),
      // Dummy Bottom Navigation sesuai prompt
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tugas Aktif'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Selesai'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  // Komponen 1: Top App Bar
  AppBar _buildOfficerAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      toolbarHeight: 72, // taller for officer
      elevation: 0,
      title: Row(
        children: [
          const CircleAvatar(
            radius: 20, // 40px circle
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pak Yusuf", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
              Text("Mitra Relawan - Sidoarjo", // Sudah disesuaikan dengan narasi C2C
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  // Komponen 2: Summary Card
  Widget _buildTodaySummaryCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700], // primary blue
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tugas Hari Ini", 
              style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("5", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(width: 8),
              Text("misi kebaikan", style: TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          const Text("🔴 1 Mendesak  |  🟡 3 Sedang  |  🟢 1 Santai", 
              style: TextStyle(fontSize: 12, color: Colors.white)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white),
              foregroundColor: Colors.white,
            ),
            child: const Text("Lihat di Peta →", style: TextStyle(fontSize: 12)),
          )
        ],
      ),
    );
  }

  // Komponen 3: Filter Chips
  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              selectedColor: Colors.blue[700],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
            ),
          );
        },
      ),
    );
  }

  // Komponen 4: Sort Dropdown (Sederhana)
  Widget _buildSortDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text("Urutkan: Jarak Terdekat ⌄", 
            style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Komponen 5: Task List (Dummy Card)
  Widget _buildTaskList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Scroll mengikuti layar utama
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3, // Dummy count
      itemBuilder: (context, index) {
        return _buildTaskCardDummy();
      },
    );
  }

  Widget _buildTaskCardDummy() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Baris Atas: Priority & Deadline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(12)),
                child: const Text("🔴 MENDESAK", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              const Text("⏰ 4 jam lagi", style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          // Isi Tengah: Foto & Info
          Row(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.grey), // Placeholder foto
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Jalan Berlubang", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text("Jl. Diponegoro No. 45, Sidoarjo", style: TextStyle(fontSize: 12, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4),
                    Text("📍 2.3 km dari posisi Anda", style: TextStyle(fontSize: 12, color: Colors.blue)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Baris Bawah: Status & Aksi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Belum Dimulai", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              TextButton(
                onPressed: () {
                   // Aksi untuk membuka detail tugas
                },
                child: const Text("Detail →", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }
}