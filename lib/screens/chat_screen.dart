import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  const ChatScreen({super.key, required this.peerId, required this.peerName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  late final String _me = supabase.auth.currentUser!.id;
  late final Stream<List<Map<String, dynamic>>> _stream = supabase
      .from('messages')
      .stream(primaryKey: ['id']).order('created_at', ascending: false);

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    _text.clear();
    try {
      await supabase.from('messages').insert({
        'sender_id': _me,
        'receiver_id': widget.peerId,
        'content': t,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Send fail: $e')));
      }
    }
  }

  Future<void> _markRead() async {
    await supabase
        .from('messages')
        .update({'is_read': true})
        .eq('sender_id', widget.peerId)
        .eq('receiver_id', _me)
        .eq('is_read', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      backgroundColor: const Color(0xFFECE5DD),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data!
                    .where((m) =>
                        (m['sender_id'] == _me &&
                            m['receiver_id'] == widget.peerId) ||
                        (m['sender_id'] == widget.peerId &&
                            m['receiver_id'] == _me))
                    .toList();
                if (msgs.any(
                    (m) => m['receiver_id'] == _me && m['is_read'] != true)) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _markRead());
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = m['sender_id'] == _me;
                    final time = DateFormat('h:mm a')
                        .format(DateTime.parse(m['created_at']).toLocal());
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                        decoration: BoxDecoration(
                          color: mine ? const Color(0xFFDCF8C6) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Text(m['content'])),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(time,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.black54)),
                                if (mine) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                      m['is_read'] == true
                                          ? Icons.done_all
                                          : Icons.done,
                                      size: 14,
                                      color: m['is_read'] == true
                                          ? Colors.blue
                                          : Colors.black45),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF075E54),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
