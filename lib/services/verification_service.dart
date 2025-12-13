import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço de verificação KYC.
class VerificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submete documentos para verificação KYC.
  Future<void> submitKYCDocuments({
    required String userId,
    required File selfie,
    required File idFront,
    required File idBack,
    required File drivingLicense,
    File? proofOfAddress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final Map<String, String> uploadedUrls = {};

      uploadedUrls['selfie'] = await _uploadFile(
        file: selfie,
        path: '$userId/selfie_$timestamp.jpg',
        bucket: 'user-documents',
      );

      uploadedUrls['idFront'] = await _uploadFile(
        file: idFront,
        path: '$userId/id_front_$timestamp.jpg',
        bucket: 'user-documents',
      );

      uploadedUrls['idBack'] = await _uploadFile(
        file: idBack,
        path: '$userId/id_back_$timestamp.jpg',
        bucket: 'user-documents',
      );

      uploadedUrls['drivingLicense'] = await _uploadFile(
        file: drivingLicense,
        path: '$userId/driving_license_$timestamp.jpg',
        bucket: 'user-documents',
      );

      if (proofOfAddress != null) {
        uploadedUrls['proofOfAddress'] = await _uploadFile(
          file: proofOfAddress,
          path: '$userId/proof_address_$timestamp.jpg',
          bucket: 'user-documents',
        );
      }

      await _supabase.from('verifications').upsert({
        'user_id': userId,
        'documents': uploadedUrls,
        'status': 'pending',
        'reviewed_at': null,
        'reviewed_by': null,
        'rejection_reason': null,
        'type': 'kyc',
      });

      await _supabase.from('users').update({
        'kyc_status': 'pending',
        'kyc_submitted_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Falha ao submeter documentos: ${e.toString()}');
    }
  }

  /// Faz upload de um ficheiro para o storage.
  Future<String> _uploadFile({
    required File file,
    required String path,
    required String bucket,
  }) async {
    try {
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado');
      }

      await _supabase.storage.from(bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
            ),
          );

      final signedUrl = await _supabase.storage.from(bucket).createSignedUrl(
            path,
            60 * 60 * 24 * 365,
          );

      return signedUrl;
    } catch (e) {
      throw Exception('Falha no upload do arquivo: ${e.toString()}');
    }
  }

  /// Obtém o estado de verificação de um utilizador.
  Future<VerificationStatus> getVerificationStatus(String userId) async {
    try {
      final userData = await _supabase
          .from('users')
          .select(
              'kyc_status, kyc_submitted_at, kyc_approved_at, kyc_rejected_at')
          .eq('id', userId)
          .maybeSingle();

      if (userData != null && userData['kyc_status'] != null) {
        final kycStatus = userData['kyc_status'] as String;

        if (kycStatus == 'approved' || kycStatus == 'rejected') {
          return VerificationStatus(
            status: kycStatus,
            isPending: false,
            isApproved: kycStatus == 'approved',
            isRejected: kycStatus == 'rejected',
            submittedAt: userData['kyc_submitted_at'] != null
                ? DateTime.parse(userData['kyc_submitted_at'])
                : null,
            reviewedAt:
                kycStatus == 'approved' && userData['kyc_approved_at'] != null
                    ? DateTime.parse(userData['kyc_approved_at'])
                    : (kycStatus == 'rejected' &&
                            userData['kyc_rejected_at'] != null
                        ? DateTime.parse(userData['kyc_rejected_at'])
                        : null),
          );
        }

        if (kycStatus == 'pending') {
          final verificationData = await _supabase
              .from('verifications')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

          if (verificationData != null) {
            return VerificationStatus(
              status: 'pending',
              isPending: true,
              isApproved: false,
              isRejected: false,
              rejectionReason: verificationData['rejection_reason'],
              submittedAt: verificationData['submitted_at'] != null
                  ? DateTime.parse(verificationData['submitted_at'])
                  : null,
              reviewedAt: verificationData['reviewed_at'] != null
                  ? DateTime.parse(verificationData['reviewed_at'])
                  : null,
            );
          }
        }
      }

      final verificationData = await _supabase
          .from('verifications')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (verificationData == null) {
        return VerificationStatus(
          status: 'not_submitted',
          isPending: false,
          isApproved: false,
          isRejected: false,
        );
      }

      final status = verificationData['status'] as String;

      return VerificationStatus(
        status: status,
        isPending: status == 'pending',
        isApproved: status == 'approved',
        isRejected: status == 'rejected',
        rejectionReason: verificationData['rejection_reason'],
        submittedAt: verificationData['submitted_at'] != null
            ? DateTime.parse(verificationData['submitted_at'])
            : null,
        reviewedAt: verificationData['reviewed_at'] != null
            ? DateTime.parse(verificationData['reviewed_at'])
            : null,
      );
    } catch (e) {
      return VerificationStatus(
        status: 'error',
        isPending: false,
        isApproved: false,
        isRejected: false,
      );
    }
  }

  /// Aprova a verificação de um utilizador (admin).
  Future<void> approveVerification(String userId, String adminId) async {
    try {
      await _supabase.from('verifications').update({
        'status': 'approved',
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': adminId,
      }).eq('user_id', userId);

      await _supabase.from('users').update({
        'is_verified': true,
        'kyc_status': 'approved',
        'kyc_approved_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw e;
    }
  }

  /// Rejeita a verificação de um utilizador (admin).
  Future<void> rejectVerification(
    String userId,
    String adminId,
    String reason,
  ) async {
    try {
      await _supabase.from('verifications').update({
        'status': 'rejected',
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': adminId,
        'rejection_reason': reason,
      }).eq('user_id', userId);

      await _supabase.from('users').update({
        'kyc_status': 'rejected',
        'kyc_rejected_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw e;
    }
  }
}

/// Estado de verificação KYC.
class VerificationStatus {
  final String status;
  final bool isPending;
  final bool isApproved;
  final bool isRejected;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  VerificationStatus({
    required this.status,
    required this.isPending,
    required this.isApproved,
    required this.isRejected,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });
}
