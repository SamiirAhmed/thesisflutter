import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ExamAppealScreen extends StatefulWidget {
  const ExamAppealScreen({super.key});

  @override
  State<ExamAppealScreen> createState() => _ExamAppealScreenState();
}

class _ExamAppealScreenState extends State<ExamAppealScreen> {
  int _currentStep =
      0; // 0: Appeal Type, 1: Seen Paper, 2: Selection/Entry, 3: Success
  String _appealType = 'Exam Appeal';
  List<dynamic> _subjects = [];
  bool _isLoading = false;

  // Selection State
  final Map<int, bool> _selectedSubjects = {}; // sub_cl_no -> checked
  final Map<int, TextEditingController> _marksControllers = {};
  final Map<int, TextEditingController> _reasonControllers = {};

  String _referenceNumber = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getExamSubjects();
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _isLoading = false;
        _subjects = result['subjects'] ?? [];
      });
      return;
    }

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Failed to load subjects')),
    );
  }

  void _submitAppeal() async {
    // Collect data
    final List<Map<String, dynamic>> payload = [];
    _selectedSubjects.forEach((subClNo, isSelected) {
      if (isSelected) {
        final subject = _subjects.firstWhere((s) => s['sub_cl_no'] == subClNo);
        payload.add({
          'sub_cl_no': subClNo,
          'marks': _marksControllers[subClNo]?.text ?? '',
          'reason': _reasonControllers[subClNo]?.text ?? '',
          'sc_no': subject['sc_no'],
        });
      }
    });

    setState(() => _isLoading = true);
    final result = await ApiService.submitExamAppeal(payload);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _referenceNumber = result['reference_no'];
        _currentStep = 3; // Success screen
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Submission failed')),
      );
    }
  }

  Widget _buildAppealTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "What are you appealing?",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildChoiceCard(
          "Exam Paper Marks Appeal",
          Icons.description_outlined,
          () {
            setState(() {
              _appealType = 'Exam Paper';
              _currentStep = 1;
            });
          },
        ),
        const SizedBox(height: 15),
        _buildChoiceCard(
          "Coursework Marks Appeal",
          Icons.assignment_outlined,
          () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Coming Soon")));
          },
        ),
      ],
    );
  }

  Widget _buildChoiceCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.indigo),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSeenPaperCheck() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Have you seen your exam paper?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: _buildChoiceCardSmall(
                "Yes, I have seen it",
                Icons.check_circle_outline,
                Colors.green,
                () {
                  setState(() {
                    _currentStep = 2;
                  });
                  _fetchSubjects();
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildChoiceCardSmall(
                "No, I have not seen it",
                Icons.cancel_outlined,
                Colors.red,
                () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceCardSmall(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 5),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_subjects.isEmpty) {
      return const Center(
        child: Text("No subjects available for the current semester."),
      );
    }

    int selectedCount = _selectedSubjects.values.where((v) => v).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Subjects (Max 3)",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Selected: $selectedCount / 3",
          style: TextStyle(
            color: selectedCount == 3 ? Colors.red : Colors.grey,
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: ListView.builder(
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final sub = _subjects[index];
              final int subClNo = sub['sub_cl_no'];
              bool isChecked = _selectedSubjects[subClNo] ?? false;
              bool isDisabled = !isChecked && selectedCount >= 3;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isChecked ? Colors.indigo : Colors.grey.shade300,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: Text(
                          sub['subject_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Code: ${sub['sc_no']}"),
                        value: isChecked,
                        onChanged: isDisabled
                            ? null
                            : (val) {
                                setState(() {
                                  _selectedSubjects[subClNo] = val ?? false;
                                  if (val == true) {
                                    _marksControllers[subClNo] ??=
                                        TextEditingController();
                                    _reasonControllers[subClNo] ??=
                                        TextEditingController();
                                  }
                                });
                              },
                      ),
                      if (isChecked) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _marksControllers[subClNo],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Marks seen on paper",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.edit_note),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _reasonControllers[subClNo],
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: "Appeal Reason",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.comment_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: selectedCount > 0 ? _showConfirmationModal : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "PROCEED TO SUBMIT",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmationModal() {
    // Validate inputs
    bool allValid = true;
    _selectedSubjects.forEach((subClNo, isSelected) {
      if (isSelected) {
        if (_marksControllers[subClNo]!.text.isEmpty ||
            _reasonControllers[subClNo]!.text.isEmpty) {
          allValid = false;
        }
      }
    });

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill marks and reasons for all selected subjects.",
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Confirm Submission",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ..._subjects
                  .where((s) => _selectedSubjects[s['sub_cl_no']] == true)
                  .map((s) {
                    final id = s['sub_cl_no'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['subject_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Marks: ${_marksControllers[id]?.text}"),
                            Text(
                              "Reason: ${_reasonControllers[id]?.text}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              const SizedBox(height: 20),
              const Text(
                "Are you sure you want to submit this appeal?",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitAppeal();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text("YES, SUBMIT NOW"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccessScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 100, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          "Appeal Submitted Successfully!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text("Your unique reference number is:"),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
          ),
          child: Text(
            _referenceNumber,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text("BACK TO HOME"),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_appealType),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0 && _currentStep < 3) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _currentStep == 0
              ? _buildAppealTypeSelection()
              : _currentStep == 1
              ? _buildSeenPaperCheck()
              : _currentStep == 2
              ? _buildSubjectSelection()
              : _buildSuccessScreen(),
        ),
      ),
    );
  }
}
