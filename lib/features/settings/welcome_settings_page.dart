import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'settings_provider.dart';

class WelcomeSettingsPage extends StatelessWidget {
  const WelcomeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('歡迎界面設定')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildImageSection(
                context,
                title: '日間模式圖片',
                imagePath: settings.welcomeImage,
                onSelect: () => _pickImage(context, (path) => settings.setWelcomeImage(path)),
                onDelete: () => settings.setWelcomeImage(''),
              ),
              SwitchListTile(
                title: const Text('日間模式顯示文字'),
                value: settings.welcomeShowText,
                onChanged: settings.welcomeImage.isEmpty ? null : (v) => settings.setWelcomeShowText(v),
              ),
              SwitchListTile(
                title: const Text('日間模式顯示圖標'),
                value: settings.welcomeShowIcon,
                onChanged: settings.welcomeImage.isEmpty ? null : (v) => settings.setWelcomeShowIcon(v),
              ),
              const Divider(),
              _buildImageSection(
                context,
                title: '夜間模式圖片',
                imagePath: settings.welcomeImageDark,
                onSelect: () => _pickImage(context, (path) => settings.setWelcomeImageDark(path)),
                onDelete: () => settings.setWelcomeImageDark(''),
              ),
              SwitchListTile(
                title: const Text('夜間模式顯示文字'),
                value: settings.welcomeShowTextDark,
                onChanged: settings.welcomeImageDark.isEmpty ? null : (v) => settings.setWelcomeShowTextDark(v),
              ),
              SwitchListTile(
                title: const Text('夜間模式顯示圖標'),
                value: settings.welcomeShowIconDark,
                onChanged: settings.welcomeImageDark.isEmpty ? null : (v) => settings.setWelcomeShowIconDark(v),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, {required String title, required String imagePath, required VoidCallback onSelect, required VoidCallback onDelete}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(imagePath.isEmpty ? '預設' : imagePath),
          trailing: imagePath.isNotEmpty ? IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete) : null,
          onTap: onSelect,
        ),
        if (imagePath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(imagePath), fit: BoxFit.cover),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context, Function(String) onPath) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      onPath(result.files.single.path!);
    }
  }
}

