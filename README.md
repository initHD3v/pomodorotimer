# Pomodoro+

**Pomodoro+ : Atur ritmemu, nikmati fokusmu.**

Aplikasi Pomodoro+ adalah evolusi dari Pomodoro Timer tradisional, dibangun dengan Flutter. Aplikasi ini membantu Anda mengelola waktu kerja dan istirahat menggunakan teknik Pomodoro yang disempurnakan.

## Filosofi Penamaan: Pomodoro+

Nama "Pomodoro+" dipilih untuk merefleksikan esensi aplikasi ini sebagai pengembangan dan peningkatan dari teknik Pomodoro klasik. Tanda "+" (plus) melambangkan:

*   **Penambahan Fitur:** Aplikasi ini memperkenalkan fungsionalitas baru seperti manajemen tugas multi-sesi dan jeda cepat (quick break), yang memperkaya pengalaman Pomodoro tradisional.
*   **Penyempurnaan:** Kami telah menyempurnakan aspek-aspek inti Pomodoro, seperti pelacakan riwayat yang lebih detail dan fleksibilitas dalam pengaturan, untuk memenuhi kebutuhan pengguna modern.
*   **Evolusi:** "Pomodoro+" menandakan bahwa ini bukan sekadar replika, melainkan langkah maju dalam adaptasi teknik Pomodoro agar lebih relevan dan efisien di lingkungan kerja saat ini.

Dengan "Pomodoro+", kami bertujuan untuk memberikan alat yang lebih komprehensif dan adaptif bagi siapa saja yang ingin meningkatkan fokus dan produktivitas mereka, sambil tetap menghormati prinsip dasar Pomodoro.

## Fitur

*   **Timer Pomodoro:** Atur durasi kerja dan istirahat.
*   **Manajemen Tugas Multi-Sesi:** Tentukan dan kelola beberapa tugas dalam satu sesi Pomodoro, dengan durasi yang dapat disesuaikan per tugas.
*   **Jeda Cepat (Quick Break):** Fitur jeda singkat yang dapat dikonfigurasi, memungkinkan jeda tanpa mengganggu sesi kerja utama. Sesi kerja akan dilanjutkan secara otomatis setelah jeda cepat berakhir.
*   **Notifikasi:** Dapatkan notifikasi saat sesi kerja atau istirahat berakhir.
*   **Manajemen Sesi:** Catat riwayat sesi Pomodoro Anda.
*   **Manajemen Riwayat yang Ditingkatkan:**
    *   Lihat riwayat sesi yang telah selesai, termasuk detail tugas individu, durasi aktual, dan status.
    *   Hapus sesi individu dari riwayat.
    *   Hapus semua riwayat sesi.
*   **Dukungan Tema:** Mendukung tema terang dan gelap.
*   **Penyempurnaan UI/UX:** Logika tampilan tombol telah disempurnakan untuk pengalaman pengguna yang lebih intuitif, termasuk menyembunyikan tombol 'Stop' selama jeda cepat.

## Instalasi

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