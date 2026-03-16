import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bookshelf_provider.dart';

class GroupSelectDialog extends StatelessWidget {
  final Set<String> bookUrls;
  const GroupSelectDialog({super.key, required this.bookUrls});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookshelfProvider>();
    final groups = provider.groups;

    return AlertDialog(
      title: const Text('移入分組'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: groups.length + 1, // +1 為 "未分組"
          itemBuilder: (ctx, index) {
            final gid = index == 0 ? 0 : groups[index - 1].groupId;
            final name = index == 0 ? '未分組' : groups[index - 1].groupName;

            return ListTile(
              title: Text(name),
              onTap: () async {
                await provider.batchUpdateGroup(bookUrls, gid);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
      ],
    );
  }
}

