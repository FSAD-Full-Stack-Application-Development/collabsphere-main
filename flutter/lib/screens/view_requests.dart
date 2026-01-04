import 'package:flutter/material.dart';
import 'package:collab_sphere/models/project.dart';
import 'package:collab_sphere/api/project.dart';
import 'package:collab_sphere/theme.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ViewFundingRequestsPage extends StatefulWidget {
  final Project project;

  const ViewFundingRequestsPage({super.key, required this.project});

  @override
  State<ViewFundingRequestsPage> createState() =>
      _ViewFundingRequestsPageState();
}

class _ViewFundingRequestsPageState extends State<ViewFundingRequestsPage> {
  List<dynamic> _fundingRequests = [];
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _fetchFundingRequests();
  }

  Future<void> _fetchFundingRequests() async {
    setState(() => _loading = true);
    try {
      final response = await projectService.getFundingRequests(
        widget.project.id,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fundingRequests = data['funding_requests'] ?? [];
        });
      } else {
        _showError('Failed to load funding requests');
      }
    } catch (e) {
      _showError('Error loading funding requests: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _approveRequest(String requestId) async {
    await _processRequest(
      requestId,
      () => projectService.approveFundingRequest(widget.project.id, requestId),
    );
  }

  Future<void> _rejectRequest(String requestId) async {
    await _processRequest(
      requestId,
      () => projectService.rejectFundingRequest(widget.project.id, requestId),
    );
  }

  Future<void> _processRequest(
    String requestId,
    Future Function() action,
  ) async {
    setState(() => _processing = true);
    try {
      final response = await action();
      if (response.statusCode == 200) {
        _showSuccess('Request processed successfully');
        _fetchFundingRequests(); // Refresh the list
      } else {
        _showError('Failed to process request');
      }
    } catch (e) {
      _showError('Error processing request: $e');
    } finally {
      setState(() => _processing = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Funding Requests',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.gradientMain),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _fundingRequests.isEmpty
              ? _buildEmptyState()
              : _buildRequestsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_money, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'No funding requests yet',
            style: TextStyle(fontSize: 18, color: AppTheme.textLight),
          ),
          const SizedBox(height: 8),
          Text(
            'Requests from community members will appear here',
            style: TextStyle(fontSize: 14, color: AppTheme.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fundingRequests.length,
      itemBuilder: (context, index) {
        final request = _fundingRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final user = request['funder'] ?? {};
    final amount =
        double.tryParse(request['amount']?.toString() ?? '0.0') ?? 0.0;
    final note = request['note'] ?? '';
    final status = request['status'] ?? 'pending';
    final createdAt =
        request['created_at'] != null
            ? DateTime.parse(request['created_at'])
            : DateTime.now();
    final requestId = request['id']?.toString() ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and amount
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.accentGold,
                  child: Text(
                    (user['full_name'] ?? '?').isNotEmpty
                        ? user['full_name'][0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${NumberFormat.compact().format(amount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Note/message
            if (note.isNotEmpty) ...[
              Text(
                'Message:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMedium,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Timestamp and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Requested ${_formatTime(createdAt)}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),

            // Action buttons (only for pending requests)
            if (status == 'pending' && !_processing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectRequest(requestId),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveRequest(requestId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return AppTheme.accentGold;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(time);
  }
}
