import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Submeter documentos KYC
  Future<void> submitKYCDocuments({
    required String userId,
    required File selfie,
    required File idFront,
    required File idBack,
    required File drivingLicense,
    File? proofOfAddress,
  }) async {
    try {
      print('Uploading KYC documents for user: $userId');

      // Criar referências para cada documento
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final Map<String, String> uploadedUrls = {};

      // Upload da selfie
      uploadedUrls['selfie'] = await _uploadFile(
        file: selfie,
        path: 'kyc/$userId/selfie_$timestamp.jpg',
      );

      // Upload do documento frente
      uploadedUrls['idFront'] = await _uploadFile(
        file: idFront,
        path: 'kyc/$userId/id_front_$timestamp.jpg',
      );

      // Upload do documento verso
      uploadedUrls['idBack'] = await _uploadFile(
        file: idBack,
        path: 'kyc/$userId/id_back_$timestamp.jpg',
      );

      // Upload da carta de condução
      uploadedUrls['drivingLicense'] = await _uploadFile(
        file: drivingLicense,
        path: 'kyc/$userId/driving_license_$timestamp.jpg',
      );

      // Upload do comprovativo de morada (se houver)
      if (proofOfAddress != null) {
        uploadedUrls['proofOfAddress'] = await _uploadFile(
          file: proofOfAddress,
          path: 'kyc/$userId/proof_address_$timestamp.jpg',
        );
      }

      // Criar registro de verificação no Firestore
      await _firestore.collection('verifications').doc(userId).set({
        'userId': userId,
        'documents': uploadedUrls,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'rejectionReason': null,
        'type': 'kyc',
      });

      // Atualizar status do usuário
      await _firestore.collection('users').doc(userId).update({
        'kycStatus': 'pending',
        'kycSubmittedAt': FieldValue.serverTimestamp(),
      });

      print('KYC documents submitted successfully');
    } catch (e) {
      print('Erro ao submeter documentos KYC: $e');
      throw Exception('Falha ao submeter documentos: ${e.toString()}');
    }
  }

  // Upload de arquivo individual
  Future<String> _uploadFile({
    required File file,
    required String path,
  }) async {
    try {
      print('Uploading file to: $path');

      // Verificar se o arquivo existe
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado');
      }

      // Criar referência
      final ref = _storage.ref().child(path);

      // Upload com metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Fazer upload
      final uploadTask = ref.putFile(file, metadata);

      // Aguardar conclusão
      final snapshot = await uploadTask;

      // Obter URL de download
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload do arquivo: $e');
      throw Exception('Falha no upload do arquivo: ${e.toString()}');
    }
  }

  // Obter status de verificação
  Future<VerificationStatus> getVerificationStatus(String userId) async {
    try {
      final doc =
          await _firestore.collection('verifications').doc(userId).get();

      if (!doc.exists) {
        return VerificationStatus(
          status: 'not_submitted',
          isPending: false,
          isApproved: false,
          isRejected: false,
        );
      }

      final data = doc.data()!;
      final status = data['status'] as String;

      return VerificationStatus(
        status: status,
        isPending: status == 'pending',
        isApproved: status == 'approved',
        isRejected: status == 'rejected',
        rejectionReason: data['rejectionReason'],
        submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
        reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      print('Erro ao obter status de verificação: $e');
      return VerificationStatus(
        status: 'error',
        isPending: false,
        isApproved: false,
        isRejected: false,
      );
    }
  }

  // Aprovar verificação (admin)
  Future<void> approveVerification(String userId, String adminId) async {
    try {
      // Atualizar verificação
      await _firestore.collection('verifications').doc(userId).update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
      });

      // Atualizar usuário
      await _firestore.collection('users').doc(userId).update({
        'hasKYC': true,
        'kycStatus': 'approved',
        'kycApprovedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao aprovar verificação: $e');
      throw e;
    }
  }

  // Rejeitar verificação (admin)
  Future<void> rejectVerification(
    String userId,
    String adminId,
    String reason,
  ) async {
    try {
      // Atualizar verificação
      await _firestore.collection('verifications').doc(userId).update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'rejectionReason': reason,
      });

      // Atualizar usuário
      await _firestore.collection('users').doc(userId).update({
        'kycStatus': 'rejected',
        'kycRejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao rejeitar verificação: $e');
      throw e;
    }
  }
}

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
