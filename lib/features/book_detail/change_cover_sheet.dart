import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'change_cover_provider.dart';
import 'book_detail_provider.dart';
import 'widgets/cover/cover_header.dart';
import 'widgets/cover/cover_grid_item.dart';
import 'widgets/cover/cover_manual_input.dart';

class ChangeCoverSheet extends StatefulWidget {
  final String bookName;
  final String author;
  const ChangeCoverSheet({super.key, required this.bookName, required this.author});
  @override State<ChangeCoverSheet> createState() => _ChangeCoverSheetState();
}

class _ChangeCoverSheetState extends State<ChangeCoverSheet> {
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChangeCoverProvider>().init(widget.bookName, widget.author);
    });
  }

  @override void dispose() { _urlController.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        context.read<BookDetailProvider>().updateCover('file://${image.path}');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('選取圖片失敗: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        _buildHandle(),
        CoverHeader(bookName: widget.bookName, author: widget.author),
        Expanded(child: _buildCoverGrid()),
        CoverManualInput(urlController: _urlController, onPickImage: _pickImage),
      ]),
    );
  }

  Widget _buildHandle() => Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))));

  Widget _buildCoverGrid() {
    return Consumer<ChangeCoverProvider>(builder: (context, provider, child) {
      if (provider.covers.isEmpty && !provider.isSearching) return const Center(child: Text('未找到相關封面'));
      return GridView.builder(
        padding: const EdgeInsets.only(top: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 16),
        itemCount: provider.covers.length,
        itemBuilder: (context, index) => CoverGridItem(result: provider.covers[index]),
      );
    });
  }
}

