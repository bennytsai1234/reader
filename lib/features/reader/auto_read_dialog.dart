import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'widgets/reader_settings_sheets.dart';


class AutoReadDialog extends StatelessWidget {
  const AutoReadDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const AutoReadDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderProvider>();
    final theme = provider.currentTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('翻頁速度', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${provider.autoPageSpeed.toInt()}s', style: TextStyle(color: theme.textColor)),
            ],
          ),
          Slider(
            value: provider.autoPageSpeed,
            min: 5.0,
            max: 300.0,
            onChanged: (v) => provider.setAutoPageSpeed(v),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAction(
                context,
                icon: Icons.menu,
                label: '主選單',
                onTap: () {
                  Navigator.pop(context);
                  provider.toggleControls();
                },
              ),
              _buildAction(
                context,
                icon: Icons.list,
                label: '目錄',
                onTap: () {
                  Navigator.pop(context);
                  Scaffold.of(context).openDrawer();
                },
              ),
              _buildAction(
                context,
                icon: Icons.stop_circle_outlined,
                label: '停止',
                onTap: () {
                  provider.stopAutoPage();
                  Navigator.pop(context);
                },
              ),
              _buildAction(
                context,
                icon: Icons.settings,
                label: '設定',
                onTap: () {
                  Navigator.pop(context);
                  ReaderSettingsSheets.showPageTurnMode(context, provider);
                },

              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = context.read<ReaderProvider>().currentTheme;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.textColor),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: theme.textColor, fontSize: 12)),
        ],
      ),
    );
  }
}

