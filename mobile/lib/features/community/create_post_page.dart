import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/community_service.dart';
import 'package:pbn/core/widgets/custom_button.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _service = CommunityService();
  final _controller = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _loading = true);
    try {
      final newPost = await _service.createPost(content);
      if (mounted) {
        Navigator.pop(context, newPost);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share post')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          _loading 
            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            : TextButton(
                onPressed: _submit,
                child: const Text('POST', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 8,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text),
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            
            // Image Placeholder (Implementation of image upload could go here)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Icon(TablerIcons.photo, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Text('Add Image (Coming Soon)', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
