# ⏱️ Pomodoro+

**Atur ritmemu, nikmati fokusmu.**  
Pomodoro+ adalah evolusi dari Pomodoro Timer tradisional, dibangun menggunakan [Flutter](https://flutter.dev) untuk platform desktop macOS (chip ARM). Dirancang untuk meningkatkan produktivitas dan menjaga keseimbangan antara kerja dan istirahat.

---

## 🌟 Fitur Utama

- 🔔 **Timer Pomodoro** – Atur durasi kerja dan istirahat sesuai kebutuhan.
- 🧠 **Manajemen Tugas Multi-Sesi** – Kelola beberapa tugas dalam satu sesi Pomodoro.
- ☕ **Jeda Cepat (Quick Break)** – Ambil jeda singkat tanpa mengganggu sesi kerja utama.
- 📌 **Notifikasi** – Notifikasi otomatis saat waktu kerja atau istirahat berakhir.
- 📈 **Manajemen Riwayat Sesi** – Lihat dan kelola riwayat sesi secara detail.
- 🎨 **Dukungan Tema** – Mode terang dan gelap untuk kenyamanan visual.
- 💡 **UX yang Disempurnakan** – Tampilan tombol dinamis dan intuitif.

---

## 🔍 Filosofi Penamaan

Nama **Pomodoro+** mencerminkan:
- **➕ Penambahan fitur baru**
- **✨ Penyempurnaan dari metode klasik**
- **🚀 Evolusi metode manajemen waktu**

Pomodoro+ bukan hanya alat bantu, tapi rekan kerja untuk produktivitas modern.

---

## 📸 Tampilan Aplikasi

> *Tambahkan screenshot atau screen recording di sini untuk menarik perhatian pengguna.*

---

## 💻 Teknologi

- Flutter 3.x
- Dart
- macOS (Apple Silicon support)

---

## 🚀 Instalasi

Untuk menjalankan aplikasi ini, pastikan Anda telah menginstal Flutter SDK.

1.  **Clone repositori ini:**
    ```bash
    git clone https://github.com/initialh/pomodoro_timer.git
    ```
2.  **Masuk ke direktori proyek:**
    ```bash
    cd pomodoro_plus
    ```
3.  **Dapatkan dependensi:**
    ```bash
    flutter pub get
    ```
4.  **Jalankan aplikasi:**
    ```bash
    flutter run
    ```
    Untuk macOS:
    ```bash
    flutter run -d macos
    ```

## Struktur Proyek

```
pomodoro_plus/
├── lib/
│   ├── database_helper.dart       # Mengelola interaksi dengan database SQLite
│   ├── main.dart                  # Logika utama aplikasi dan UI Pomodoro Timer
│   ├── notification_service.dart  # Mengelola notifikasi lokal
│   ├── session_history_screen.dart# Layar untuk menampilkan riwayat sesi
│   ├── settings_screen.dart       # Layar untuk pengaturan aplikasi
│   └── system_tray_manager.dart   # Mengelola integrasi dengan system tray (khusus desktop)
├── assets/
│   └── icon.png                   # Aset ikon aplikasi
├── macos/                         # Konfigurasi khusus macOS
├── pubspec.yaml                   # Definisi proyek dan dependensi
├── README.md                      # Berkas ini
└── ...
```

## Kontribusi

Kontribusi sangat dihargai! Jika Anda memiliki saran atau menemukan bug, silakan buka issue atau kirim pull request.

## Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT. Lihat berkas `LICENSE` untuk detail lebih lanjut.
