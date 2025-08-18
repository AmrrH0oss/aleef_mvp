import 'package:flutter/material.dart';

class SocialRow extends StatelessWidget {
  final List<String> assetPaths;
  const SocialRow({
    super.key,
    this.assetPaths = const [
      'lib/assets/google.png',
      'lib/assets/apple.png',
      'lib/assets/facebook.png',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < assetPaths.length; i++) ...[
          _SocialIcon(path: assetPaths[i]),
          if (i != assetPaths.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final String path;
  const _SocialIcon({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        path,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.account_circle,
            size: 24,
            color: Colors.grey.shade600,
          );
        },
      ),
    );
  }
}
