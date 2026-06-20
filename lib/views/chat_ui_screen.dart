import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../controller/chat_controller.dart';

class ChatUIScreen extends StatefulWidget {
  final String roomId;
  final String otherUid;
  final String otherInitials;
  final Color otherColor;
  final String taskTitle;
  final bool isPeminta;
  final ChatController ctrl;

  const ChatUIScreen({
    super.key,
    required this.roomId,
    required this.otherUid,
    required this.otherInitials,
    required this.otherColor,
    required this.taskTitle,
    required this.isPeminta,
    required this.ctrl,
  });

  @override
  State<ChatUIScreen> createState() => _ChatUIScreenState();
}

class _ChatUIScreenState extends State<ChatUIScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Tandai sudah dibaca saat buka chat
    widget.ctrl.markAsRead(widget.roomId);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textCtrl.clear();

    await widget.ctrl.sendMessage(
      roomId: widget.roomId,
      text: text,
      otherUid: widget.otherUid,
    );

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTaskBanner(),
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: const Color(0xFF1BAB8A),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar lawan bicara
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.otherInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9FE1CB),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF1BAB8A), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isPeminta ? 'Helper' : 'Peminta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'Online · Aktif',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          // POV badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.isPeminta ? 'POV: Peminta' : 'POV: Helper',
              style:
                  const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Task Banner ──────────────────────────────────────────────────────────
  Widget _buildTaskBanner() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFE8F6F2),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined,
              size: 14, color: Color(0xFF1BAB8A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.taskTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F6E56),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Message List ─────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return StreamBuilder<List<ChatMessageModel>>(
      stream: widget.ctrl.streamMessages(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(color: Color(0xFF1BAB8A)),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 40, color: Color(0xFFCCCCCC)),
                SizedBox(height: 12),
                Text(
                  'Belum ada pesan\nMulai percakapan!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF888888)),
                ),
              ],
            ),
          );
        }

        // Scroll ke bawah saat ada pesan baru
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          widget.ctrl.markAsRead(widget.roomId);
        });

        return ListView.builder(
          controller: _scrollCtrl,
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 12),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final msg = messages[i];
            final isMe = msg.senderUid == widget.ctrl.currentUid;

            // Tampilkan tanggal jika beda hari
            final showDate = i == 0 ||
                !_isSameDay(
                  messages[i - 1].createdAt,
                  msg.createdAt,
                );

            return Column(
              children: [
                if (showDate) _buildDateDivider(msg.createdAt),
                _buildBubble(msg, isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime? dt) {
    final label = dt != null ? _formatDate(dt) : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: Colors.grey.shade300, thickness: 0.8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF888888)),
            ),
          ),
          Expanded(
              child: Divider(color: Colors.grey.shade300, thickness: 0.8)),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessageModel msg, bool isMe) {
    final timeStr = msg.createdAt != null
        ? '${msg.createdAt!.hour.toString().padLeft(2, '0')}:${msg.createdAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 270),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF1BAB8A) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMe ? 14 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 14),
            ),
            border: isMe
                ? null
                : Border.all(
                    color: const Color(0xFFE8E8E8), width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                msg.text,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFF222222),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          isMe ? Colors.white60 : const Color(0xFF888888),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      msg.isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 12,
                      color: msg.isRead
                          ? Colors.white
                          : Colors.white60,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Input Bar ────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                hintStyle: const TextStyle(
                    color: Color(0xFFBBBBBB), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isSending
                    ? const Color(0xFF1BAB8A).withOpacity(0.5)
                    : const Color(0xFF1BAB8A),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (_isSameDay(dt, now)) return 'Hari ini';
    if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) {
      return 'Kemarin';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}