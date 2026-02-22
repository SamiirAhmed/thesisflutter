import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ExamTrackingScreen extends StatefulWidget {
  const ExamTrackingScreen({super.key});

  @override
  State<ExamTrackingScreen> createState() => _ExamTrackingScreenState();
}

class _ExamTrackingScreenState extends State<ExamTrackingScreen> {
  final TextEditingController _refController = TextEditingController();
  bool _isLoading = false;
  List<dynamic>? _results;
  String? _error;

  void _trackAppeal() async {
    if (_refController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = null;
      _error = null;
    });

    final result = await ApiService.trackExamAppeal(_refController.text.trim());

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _results = result['data'];
      } else {
        _error = result['message'] ?? 'Failed to track appeal.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Track Appeal"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Enter Reference Number",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _refController,
              decoration: InputDecoration(
                hintText: "e.g. APP-67B8C...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (_) => _trackAppeal(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _trackAppeal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "TRACK NOW",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 30),
            if (_error != null)
              Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_results != null)
              Expanded(
                child: ListView.builder(
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    final item = _results![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['subject_name'] ?? 'Unknown Subject',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(item['status']),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.pin,
                              "Ref",
                              item['reference_no'],
                            ),
                            _buildInfoRow(
                              Icons.edit_note,
                              "Requested Mark",
                              item['requested_mark'].toString(),
                            ),
                            _buildInfoRow(
                              Icons.calendar_today,
                              "Date",
                              item['created_at'],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Reason:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(item['reason'] ?? 'No reason provided'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.blue;
    if (status.toLowerCase().contains('pending')) color = Colors.orange;
    if (status.toLowerCase().contains('approved')) color = Colors.green;
    if (status.toLowerCase().contains('rejected')) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
