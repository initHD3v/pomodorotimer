
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';

class SystemTrayManager {
  final SystemTray _systemTray = SystemTray();

  Future<void> init(Function onStart, Function onPause, Function onReset) async {
    // TODO: Ganti dengan path ikon Anda
    // Pastikan Anda telah menambahkan file ikon ke folder assets di pubspec.yaml
    await _systemTray.initSystemTray(iconPath: 'assets/icon.png');

    final Menu menu = Menu()
      ..buildFrom([
        MenuItemLabel(label: 'Mulai', onClicked: (menuItem) => onStart()),
        MenuItemLabel(label: 'Jeda', onClicked: (menuItem) => onPause()),
        MenuItemLabel(label: 'Atur Ulang', onClicked: (menuItem) => onReset()),
      ]);

    await _systemTray.setContextMenu(menu);

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        // Aksi saat ikon di klik
      }
    });
  }

  void setToolTip(String toolTip) {
    _systemTray.setToolTip(toolTip);
  }
}
