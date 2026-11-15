import 'package:flutter/material.dart';

import '../config.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});
  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _q = TextEditingController();
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String q) async {
    final me = supabase.auth.currentUser!.id;
    var query = supabase.from('profiles').select().neq('id', me);
    if (q.trim().isNotEmpty) {
      final s = q.trim().replaceAll(',', '');
      query = query.or('name.ilike.%$s%,phone.ilike.%$s%');
    }
    final res = await query.limit(50);
    if (mounted) setState(() => _users = List<Map<String, dynamic>>.from(res));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _q,
          onChanged: _search,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Naam ya number se dhundo',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, i) {
          final u = _users[i];
          final name = (u['name'] as String?)?.isNotEmpty == true
              ? u['name'] as String
              : (u['phone'] ?? 'User') as String;
          return ListTile(
            leading: CircleAvatar(child: Text(name[0].toUpperCase())),
            title: Text(name),
            subtitle: Text(u['phone'] ?? ''),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(peerId: u['id'], peerName: name)),
            ),
          );
        },
      ),
    );
  }
}
