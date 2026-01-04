// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../theme.dart';
import '../widgets/loading_button.dart';

class ChatScreen extends StatefulWidget {
  final Project project;
  const ChatScreen({super.key, required this.project});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  List<Comment> get _messages => widget.project.comments;

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final newComment = Comment(
      id: DateTime.now().toIso8601String(),
      author: 'You',
      text: _controller.text.trim(),
      timestamp: DateTime.now(),
      likes: 0,
    );

    setState(() {
      _messages.insert(0, newComment);
      _controller.clear();
      _isTyping = true;
    });

    // Simulated reply
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.insert(
          0,
          Comment(
            id: DateTime.now().toIso8601String(),
            author: 'Team Member',
            text: 'Thanks! Got your message.',
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
    });
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Team Chat • ${_messages.length} messages',
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
          ],
        ),
        actions: [
          CircleAvatar(
            backgroundColor: AppTheme.accentGold,
            child: Text(
              widget.project.title[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
        child: Column(
          children: [
            // Messages
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == 0 && _isTyping) return _typingBubble();
                  final msg = _messages[_isTyping ? i - 1 : i];
                  final isMe = msg.author == 'You';
                  return _messageBubble(
                    msg.text,
                    isMe,
                    _formatTime(msg.timestamp),
                  );
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [AppTheme.shadowMd],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppTheme.bgWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: AppTheme.accentGold,
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.accentGold,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.accentGold : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AppTheme.shadowMd],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : AppTheme.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AppTheme.shadowMd],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [_dot(), _dot(delay: 0.2), _dot(delay: 0.4)],
        ),
      ),
    );
  }

  Widget _dot({double delay = 0}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (delay * 1000).toInt()),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        color: AppTheme.textLight,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Edit Project Page
class EditProjectPage extends StatefulWidget {
  final Project project;
  const EditProjectPage({super.key, required this.project});

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _data;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _data = {
      'title': widget.project.title,
      'description': widget.project.description ?? '',
      'status': _capitalize(widget.project.status),
      'visibility': _capitalize(widget.project.visibility),
      'showFunds': widget.project.showFunds,
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // TODO: Convert dropdown values back to lowercase for backend when implementing actual save
    // final saveData = {
    //   ..._data,
    //   'status': _data['status']?.toString().toLowerCase(),
    //   'visibility': _data['visibility']?.toString().toLowerCase(),
    // };

    await Future.delayed(const Duration(seconds: 2));
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project updated!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Project',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _inputField('Project Title', 'title', required: true),
                        const SizedBox(height: 20),
                        _inputField(
                          'Description',
                          'description',
                          maxLines: 5,
                          required: true,
                        ),
                        const SizedBox(height: 20),
                        _dropdownField('Status', 'status', [
                          'Ongoing',
                          'Completed',
                        ]),
                        const SizedBox(height: 20),
                        _dropdownField('Visibility', 'visibility', [
                          'Public',
                          'Private',
                        ]),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          title: const Text('Show Funding?'),
                          value: _data['showFunds'] == true,
                          onChanged:
                              (v) => setState(() => _data['showFunds'] = v),
                        ),
                        const SizedBox(height: 32),
                        LoadingButton(
                          loading: _saving,
                          text: 'Save Changes',
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String label,
    String key, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _data[key].toString(),
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.bgWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.accentGold,
                width: 2,
              ),
            ),
          ),
          validator:
              required
                  ? (v) => v?.trim().isEmpty ?? true ? 'Required' : null
                  : null,
          onChanged: (v) => _data[key] = v,
        ),
      ],
    );
  }

  Widget _dropdownField(String label, String key, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _data[key],
          items:
              options
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
          onChanged: (v) => setState(() => _data[key] = v),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.accentGold,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
