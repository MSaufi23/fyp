import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/database_service.dart';
import '../main.dart';
import 'package:uuid/uuid.dart';

class ReportPage
    extends
        StatefulWidget {
  const ReportPage({
    super.key,
  });

  @override
  State<
    ReportPage
  >
  createState() =>
      _ReportPageState();
}

class _ReportPageState
    extends
        State<
          ReportPage
        > {
  final _formKey =
      GlobalKey<
        FormState
      >();
  final _contentController =
      TextEditingController();
  final _databaseService =
      DatabaseService();
  bool _isLoading =
      false;
  List<
    Report
  >
  _userReports =
      [];

  @override
  void initState() {
    super.initState();
    _loadUserReports();
  }

  Future<
    void
  >
  _loadUserReports() async {
    if (currentUser !=
        null) {
      final reports = await _databaseService.getUserReports(
        currentUser!.username,
      );
      setState(
        () {
          _userReports =
              reports;
        },
      );
    }
  }

  Future<
    void
  >
  _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(
        () {
          _isLoading =
              true;
        },
      );

      try {
        final report = Report(
          id:
              const Uuid().v4(),
          reporterUsername:
              currentUser!.username,
          reporterType:
              currentUser!.type.toString(),
          content:
              _contentController.text,
          timestamp:
              DateTime.now(),
        );

        await _databaseService.createReport(
          report,
        );
        _contentController.clear();
        await _loadUserReports();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Report submitted successfully',
              ),
              backgroundColor:
                  Colors.green,
            ),
          );
        }
      } catch (
        e
      ) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                'Error submitting report: $e',
              ),
              backgroundColor:
                  Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(
            () {
              _isLoading =
                  false;
            },
          );
        }
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report an Issue',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          16.0,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(
                  16.0,
                ),
                child: Form(
                  key:
                      _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Submit a Report',
                        style: TextStyle(
                          fontSize:
                              20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height:
                            16,
                      ),
                      TextFormField(
                        controller:
                            _contentController,
                        maxLines:
                            5,
                        decoration: const InputDecoration(
                          labelText:
                              'Describe the issue',
                          hintText:
                              'Please provide details about the bug or issue you encountered...',
                          border:
                              OutlineInputBorder(),
                        ),
                        validator: (
                          value,
                        ) {
                          if (value ==
                                  null ||
                              value.isEmpty) {
                            return 'Please describe the issue';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height:
                            16,
                      ),
                      ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : _submitReport,
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width:
                                      20,
                                  height:
                                      20,
                                  child: CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                                : const Text(
                                  'Submit Report',
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height:
                  24,
            ),
            const Text(
              'Your Previous Reports',
              style: TextStyle(
                fontSize:
                    20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height:
                  16,
            ),
            if (_userReports.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(
                    16.0,
                  ),
                  child: Text(
                    'You haven\'t submitted any reports yet.',
                    style: TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap:
                    true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount:
                    _userReports.length,
                itemBuilder: (
                  context,
                  index,
                ) {
                  final report =
                      _userReports[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        16.0,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                report.statusText,
                                style: TextStyle(
                                  color:
                                      report.statusColor,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${report.timestamp.day}/${report.timestamp.month}/${report.timestamp.year}',
                                style: const TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height:
                                8,
                          ),
                          Text(
                            report.content,
                          ),
                          if (report.adminResponse !=
                              null) ...[
                            const SizedBox(
                              height:
                                  8,
                            ),
                            const Divider(),
                            const Text(
                              'Admin Response:',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height:
                                  4,
                            ),
                            Text(
                              report.adminResponse!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
