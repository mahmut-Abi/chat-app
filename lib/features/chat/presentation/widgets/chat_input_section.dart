import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../shared/widgets/glass_container.dart';
import 'image_picker_widget.dart';
import 'chat_function_menu.dart';
import '../../../agent/domain/agent_tool.dart';
import '../../../mcp/domain/mcp_config.dart';
import '../../../models/domain/model.dart';

/// 聊天输入区域组件
class ChatInputSection extends StatefulWidget {
  final TextEditingController messageController;
  final List<File> selectedImages;
  final List<File> selectedFiles;
  final bool isLoading;
  final VoidCallback onSend;
  final Function(List<File>) onImagesSelected;
  final Function(List<File>) onFilesSelected;
  final AgentConfig? selectedAgent;
  final McpConfig? selectedMcp;
  final AiModel? selectedModel;
  final Function(AgentConfig?)? onAgentSelected;
  final Function(McpConfig?)? onMcpSelected;
  final Function(AiModel)? onModelSelected;

  const ChatInputSection({
    super.key,
    required this.messageController,
    required this.selectedImages,
    this.selectedFiles = const [],
    required this.isLoading,
    required this.onSend,
    required this.onImagesSelected,
    required this.onFilesSelected,
    this.selectedAgent,
    this.selectedMcp,
    this.selectedModel,
    this.onAgentSelected,
    this.onMcpSelected,
    this.onModelSelected,
  });

  @override
  State<ChatInputSection> createState() => _ChatInputSectionState();
}

class _ChatInputSectionState extends State<ChatInputSection> {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 15.0,
      opacity: 0.15,
      padding: const EdgeInsets.all(16),
      border: Border(
        top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ImagePickerWidget(
                selectedImages: widget.selectedImages,
                onImagesSelected: widget.onImagesSelected,
              ),
            ),
          if (widget.selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildFilesList(),
            ),
          Row(
            children: [
              ChatFunctionMenu(
                onImagesSelected: (images) {
                  widget.onImagesSelected([
                    ...widget.selectedImages,
                    ...images,
                  ]);
                },
                onFilesSelected: (files) {
                  widget.onFilesSelected([...widget.selectedFiles, ...files]);
                },
                onAgentSelected: widget.onAgentSelected,
                onMcpSelected: widget.onMcpSelected,
                onModelSelected: widget.onModelSelected,
                selectedAgent: widget.selectedAgent,
                selectedMcp: widget.selectedMcp,
                selectedModel: widget.selectedModel,
              ),
              Expanded(
                child: TextField(
                  controller: widget.messageController,
                  maxLines: null,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => widget.onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                onPressed: widget.isLoading ? null : widget.onSend,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        itemCount: widget.selectedFiles.length,
        itemBuilder: (context, index) {
          final file = widget.selectedFiles[index];
          final fileName = file.path.split('/').last;
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: InkWell(
                    onTap: () {
                      final newFiles = List<File>.from(widget.selectedFiles)
                        ..removeAt(index);
                      widget.onFilesSelected(newFiles);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
