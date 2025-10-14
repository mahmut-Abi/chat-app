import 'package:flutter/material.dart';

/// 关于区域
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('版本'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('开源许可'),
          onTap: () {
            showLicensePage(context: context);
          },
        ),
      ],
    );
  }
}
