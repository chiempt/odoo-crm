import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/lead_model.dart';
import '../../providers/crm_provider.dart';
import 'lead_detail_tokens.dart';

class AttachmentsSheet extends StatefulWidget {
  final Lead lead;

  const AttachmentsSheet({super.key, required this.lead});

  static Future<void> show(BuildContext context, Lead lead) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentsSheet(lead: lead),
    );
  }

  @override
  State<AttachmentsSheet> createState() => _AttachmentsSheetState();
}

class _AttachmentsSheetState extends State<AttachmentsSheet> {
  bool _isUploading = false;
  final Set<int> _busyAttachmentIds = <int>{};

  String _safeFileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'attachment.bin';
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<String?> _persistDownload(String fileName, List<int> bytes) async {
    final preferredPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save attachment',
      fileName: _safeFileName(fileName),
    );
    if (preferredPath != null && preferredPath.isNotEmpty) {
      final file = File(preferredPath);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }

    final fallback = File(
      '${Directory.systemTemp.path}/${_safeFileName(fileName)}',
    );
    await fallback.writeAsBytes(bytes, flush: true);
    return fallback.path;
  }

  Future<void> _pickAndUpload() async {
    final provider = context.read<CrmProvider>();
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      if (!context.mounted) return;
      setState(() => _isUploading = true);
      try {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final fileName = result.files.single.name;

        final success = await provider.uploadAttachment(
          leadId: int.parse(widget.lead.id),
          fileName: fileName,
          base64Content: base64String,
        );

        if (success) {
          await provider.fetchLeadById(int.parse(widget.lead.id));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File uploaded successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Upload failed')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _downloadAttachment(LeadAttachment attachment) async {
    final provider = context.read<CrmProvider>();
    final leadId = int.parse(widget.lead.id);
    setState(() => _busyAttachmentIds.add(attachment.id));
    try {
      final result = await provider.downloadAttachment(
        leadId: leadId,
        attachmentId: attachment.id,
      );
      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download failed')));
        return;
      }

      final path = await _persistDownload(result.fileName, result.bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloaded to $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download error: $e')));
    } finally {
      if (mounted) {
        setState(() => _busyAttachmentIds.remove(attachment.id));
      }
    }
  }

  Future<void> _deleteAttachment(LeadAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete attachment?'),
          content: Text('Delete "${attachment.name}" permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<CrmProvider>();
    final leadId = int.parse(widget.lead.id);
    setState(() => _busyAttachmentIds.add(attachment.id));
    try {
      final success = await provider.deleteAttachment(
        leadId: leadId,
        attachmentId: attachment.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Attachment deleted' : 'Delete failed'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyAttachmentIds.remove(attachment.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CrmProvider>();
    final lead = provider.leads.firstWhere(
      (l) => l.id == widget.lead.id,
      orElse: () => widget.lead,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attachments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUpload,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LdToken.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: lead.attachments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.attachment_rounded,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No attachments yet',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: lead.attachments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final a = lead.attachments[index];
                      final busy = _busyAttachmentIds.contains(a.id);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.insert_drive_file_rounded,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          a.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${a.fileSizeLabel} • ${a.createDate.split(' ')[0]}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  size: 20,
                                ),
                                onSelected: (value) {
                                  if (value == 'download') {
                                    _downloadAttachment(a);
                                    return;
                                  }
                                  if (value == 'delete') {
                                    _deleteAttachment(a);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem<String>(
                                    value: 'download',
                                    child: Text('Download'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
