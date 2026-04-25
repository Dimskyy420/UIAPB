import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import '../../controller/request_controller.dart';
import 'step2_detail_screen.dart';

class Step1KategoriScreen extends StatefulWidget {
  const Step1KategoriScreen({super.key});

  @override
  State<Step1KategoriScreen> createState() => _Step1KategoriScreenState();
}

class _Step1KategoriScreenState extends State<Step1KategoriScreen> {
  final RequestController _controller = RequestController();
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'icon': '📚', 'label': 'Akademik'},
    {'icon': '📋', 'label': 'Administrasi'},
    {'icon': '📦', 'label': 'Logistik Ringan'},
    {'icon': '🎉', 'label': 'Event Kampus'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Kategori',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Apa jenis bantuan yang kamu butuhkan?',
                      style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    ),
                    const SizedBox(height: 24),
                    _buildCategoryGrid(),
                  ],
                ),
              ),
            ),
            _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 18, color: Color(0xFF444444)),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buat Permintaan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    'Langkah 1 dari 3',
                    style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(1),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: i < step
                  ? const Color(0xFF1BAB8A)
                  : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat['label'];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat['label']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF0FBF7)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1BAB8A)
                    : const Color(0xFFE0E0E0),
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat['icon'], style: const TextStyle(fontSize: 24)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat['label'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF1BAB8A)
                            : const Color(0xFF333333),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1BAB8A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    final isActive = _selectedCategory != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isActive
              ? () {
                  final draft = RequestModel(
                    userId: '',
                    category: _selectedCategory!,
                    title: '',
                    description: '',
                    duration: '1-2 jam',
                    mode: 'Tatap Muka',
                    location: '',
                    date: '',
                    time: '',
                    budget: 0,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Step2DetailScreen(draft: draft),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1BAB8A),
            disabledBackgroundColor: const Color(0xFFCCCCCC),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Lanjut',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}