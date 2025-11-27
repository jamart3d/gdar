// lib/ui/screens/about_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About gdar'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // App Icon / Logo Placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  size: 50,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'gdar',
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'A simple, lightweight music player for select live grateful dead shows from Archive.org, featuring gapless playback and random show selection.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildInfoCard(
                context,
                icon: Icons.cloud_download_rounded,
                title: 'Powered by Archive.org',
                description: 'All audio is streamed directly from Archive.org.',
              ),
              const SizedBox(height: 24),
              _buildClickableLink(
                context,
                'Archive.org Terms of Use',
                'https://archive.org/about/terms.php',
                icon: Icons.gavel,
              ),
              const SizedBox(height: 24),
              // _buildSectionTitle(context, 'Contact'),
              ListTile(
                leading: Icon(Icons.email, color: colorScheme.primary),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'jamart3d@gmail.com',
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.content_copy,
                        color: colorScheme.primary, size: 16),
                  ],
                ),
                onTap: () {
                  Clipboard.setData(
                      const ClipboardData(text: 'jamart3d@gmail.com'));
                  _showEmailCopiedSnackBar(context);
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String description}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      // decoration: BoxDecoration(
      //   color: colorScheme.surfaceContainer,
      //   borderRadius: BorderRadius.circular(16),
      //   border: Border.all(color: colorScheme.outlineVariant),
      // ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildClickableLink(BuildContext context, String text, String url,
      {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: icon != null ? Icon(icon, color: colorScheme.primary) : null,
      title: Text(
        text,
        style: TextStyle(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
      onTap: () => _launchUrl(url),
    );
  }

  void _showEmailCopiedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email address copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
