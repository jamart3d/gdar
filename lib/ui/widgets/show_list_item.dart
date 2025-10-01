// lib/ui/widgets/show_list_item.dart

import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';

class ShowListItem extends StatelessWidget {
  final Show show;
  final VoidCallback onTap;

  const ShowListItem({
    super.key,
    required this.show,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(
          show.venue,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(show.formattedDate),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }
}