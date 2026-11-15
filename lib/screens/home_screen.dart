import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final me = supabase.auth.currentUser!.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.message),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NewChatScreen())),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('messages')
            .stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Har peer ka latest message + unread count
          final latest = <String, Map<String, dynamic>>{};
          final unread = <String, int>{};
          for (final m in snap.data!) {
            final peer = m['sender_id'] == me ? m['receiver_id'] : m['sender_id'];
            latest.putIfAbsent(peer as String, () => m);
            if (m['receiver_id'] == me && m['is_read'] != true) {
              unread[peer] = (unread[peer] ?? 0) + 1;
            }
          }
          if (latest.isEmpty) {
            return const Center(
                child: Text('Abhi koi chat nahi. Neeche button se shuru karo.'));
          }
          final ids = latest.keys.toList();
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: supabase.from('profiles').select().inFilter('id', ids),
            builder: (context, ps) {
              final profiles = {
                for (final p in ps.data ?? <Map<String, dynamic>>[])
                  p['id'] as String: p
              };
              return ListView.separated(
                itemCount: ids.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final id = ids[i];
                  final m = latest[id]!;
                  final p = profiles[id];
                  final name = (p?['name'] as String?)?.isNotEmpty == true
                      ? p!['name'] as String
                      : (p?['phone'] ?? 'User') as String;
                  final time = DateFormat('h:mm a')
                      .format(DateTime.parse(m['created_at']).toLocal());
                  final n = unread[id] ?? 0;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: p?['avatar_url'] != null
                          ? NetworkImage(p!['avatar_url'])
                          : null,
                      child: p?['avatar_url'] == null
                          ? Text(name[0].toUpperCase())
                          : null,
                    ),
                    title: Text(name),
                    subtitle: Text(m['content'],
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(time, style: const TextStyle(fontSize: 12)),
                        if (n > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle),
                            child: Text('$n',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ChatScreen(peerId: id, peerName: name)),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
