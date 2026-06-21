import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      q: 'Bagaimana cara memesan helper?',
      a: 'Buat permintaan tugas di halaman utama, isi detail tugas dan budget. Helper yang tertarik akan mengajukan penawaran, lalu kamu bisa memilih yang paling cocok.',
    ),
    (
      q: 'Bagaimana sistem pembayaran bekerja?',
      a: 'Pembayaran dilakukan langsung antara kamu dan helper setelah tugas selesai. Sepakati harga sebelum memulai — TASURU tidak mengambil komisi.',
    ),
    (
      q: 'Apa yang dilakukan jika helper tidak muncul?',
      a: 'Hubungi helper melalui fitur chat bawaan TASURU. Jika tidak ada respons dalam waktu yang wajar, kamu bisa membatalkan tugas dan mencari helper lain.',
    ),
    (
      q: 'Bagaimana cara memberi ulasan kepada helper?',
      a: 'Setelah menekan tombol "Tandai Selesai", sistem akan otomatis memunculkan form ulasan bintang. Kamu bisa memberi nilai 1–5 dan komentar opsional.',
    ),
    (
      q: 'Apakah data saya aman?',
      a: 'Ya. Semua data disimpan secara aman di infrastruktur Firebase (Google Cloud). Kami tidak pernah menjual atau membagikan data pribadimu kepada pihak ketiga.',
    ),
    (
      q: 'Bagaimana cara menjadi helper?',
      a: 'Setiap pengguna terdaftar TASURU secara otomatis bisa menjadi helper. Cukup buka halaman beranda, cari tugas yang tersedia, lalu ajukan penawaran harga kamu.',
    ),
    (
      q: 'Berapa batas maksimum harga penawaran?',
      a: 'Tidak ada batas tetap. Harga sepenuhnya disepakati antara peminta dan helper secara bebas sesuai kompleksitas tugas.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1BAB8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bantuan & Dukungan',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Intro card ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1BAB8A).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF1BAB8A).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1BAB8A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Color(0xFF1BAB8A), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ada yang bisa kami bantu?',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      SizedBox(height: 2),
                      Text('Cari jawaban di FAQ atau hubungi tim kami.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF555555))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── FAQ ───────────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Pertanyaan yang sering ditanyakan',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888)),
            ),
          ),
          ..._faqs.map((faq) => _FaqItem(question: faq.q, answer: faq.a)),

          const SizedBox(height: 20),

          // ── Kontak ────────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Hubungi kami',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _ContactTile(
                  icon: Icons.email_outlined,
                  label: 'Email Support',
                  value: 'support@tasuru.app',
                  onTap: () {},
                ),
                const Divider(
                    height: 1, indent: 70, color: Color(0xFFF5F5F5)),
                _ContactTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Instagram',
                  value: '@tasuru.app',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Center(
            child: Text(
              'TASURU v1.0.0',
              style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── FAQ Item ──────────────────────────────────────────────────────────────────

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _rotation = Tween<double>(begin: 0, end: 0.5).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotation,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF1BAB8A),
                      size: 20,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Divider(
                              height: 1, color: Color(0xFFF5F5F5)),
                          const SizedBox(height: 10),
                          Text(
                            widget.answer,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF555555),
                                height: 1.6),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contact Tile ──────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(icon, color: const Color(0xFF1BAB8A), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF1BAB8A))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFDDDDDD), size: 22),
          ],
        ),
      ),
    );
  }
}
