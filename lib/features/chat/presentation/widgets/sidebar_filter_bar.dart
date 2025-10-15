import 'package:flutter/material.dart';
import '../../domain/conversation.dart';

class SidebarFilterBar extends StatelessWidget {
  final List<ConversationGroup> groups;
  final Set<String> allTags;
  final String? selectedGroupId;
  final String? selectedTag;
  final Function(String?) onGroupSelected;
  final Function(String?) onTagSelected;

  const SidebarFilterBar({
    super.key,
    required this.groups,
    required this.allTags,
    required this.selectedGroupId,
    required this.selectedTag,
    required this.onGroupSelected,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (groups.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: groups.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('全部'),
                        selected: selectedGroupId == null,
                        onSelected: (_) => onGroupSelected(null),
                      ),
                    );
                  }
                  final group = groups[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(group.name),
                      selected: selectedGroupId == group.id,
                      onSelected: (_) => onGroupSelected(group.id),
                    ),
                  );
                },
              ),
            ),
          if (allTags.isNotEmpty) const SizedBox(height: 4),
          if (allTags.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allTags.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('所有标签'),
                        selected: selectedTag == null,
                        onSelected: (_) => onTagSelected(null),
                      ),
                    );
                  }
                  final tag = allTags.elementAt(index - 1);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: const Icon(Icons.tag, size: 16),
                      label: Text(tag),
                      selected: selectedTag == tag,
                      onSelected: (_) => onTagSelected(tag),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
