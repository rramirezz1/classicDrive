import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- ADICIONA ESTA LINHA
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/review_model.dart';
import '../../widgets/rating_widget.dart';

class AddReviewScreen extends StatefulWidget {
  final String bookingId;

  const AddReviewScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  BookingModel? _booking;
  VehicleModel? _vehicle;
  bool _hasExistingReview = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);

      // Buscar dados da reserva
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (!bookingsSnapshot.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reserva não encontrada')),
          );
          context.pop();
        }
        return;
      }

      final booking = BookingModel.fromMap(
        bookingsSnapshot.data()!,
        bookingsSnapshot.id,
      );

      // Verificar se já existe avaliação
      final existingReview = await FirebaseFirestore.instance
          .collection('reviews')
          .where('bookingId', isEqualTo: widget.bookingId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        setState(() {
          _hasExistingReview = true;
          _isLoading = false;
        });
        return;
      }

      // Buscar dados do veículo
      final vehicle = await databaseService.getVehicleById(booking.vehicleId);

      setState(() {
        _booking = booking;
        _vehicle = vehicle;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma avaliação'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, adicione um comentário'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final review = ReviewModel(
        bookingId: widget.bookingId,
        vehicleId: _booking!.vehicleId,
        reviewerId: authService.currentUser!.uid,
        reviewerName: authService.userData?.name ?? 'Utilizador',
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Adicionar avaliação
      await FirebaseFirestore.instance
          .collection('reviews')
          .add(review.toMap());

      // Atualizar rating do veículo
      await _updateVehicleRating(_booking!.vehicleId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avaliação adicionada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop(true); // Retornar true para indicar sucesso
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar avaliação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateVehicleRating(String vehicleId) async {
    try {
      final reviews = await FirebaseFirestore.instance
          .collection('reviews')
          .where('vehicleId', isEqualTo: vehicleId)
          .get();

      if (reviews.docs.isEmpty) return;

      double totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += doc.data()['rating'];
      }

      final avgRating = totalRating / reviews.docs.length;

      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
        'stats.rating': avgRating,
        'stats.totalBookings': FieldValue.increment(1),
      });
    } catch (e) {
      print('Erro ao atualizar rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasExistingReview) {
      return Scaffold(
        appBar: AppBar(title: const Text('Avaliação')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Já avaliou esta reserva',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_booking == null || _vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Avaliação')),
        body: const Center(
          child: Text('Erro ao carregar dados'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar Experiência'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do veículo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: _vehicle!.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _vehicle!.images.first,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.directions_car, size: 40),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _vehicle!.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reserva de ${_booking!.numberOfDays} ${_booking!.numberOfDays == 1 ? "dia" : "dias"}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Rating
            Center(
              child: RatingInput(
                initialRating: _rating,
                onRatingChanged: (rating) {
                  setState(() => _rating = rating);
                },
                label: 'Como foi a sua experiência?',
              ),
            ),

            const SizedBox(height: 32),

            // Comentário
            const Text(
              'Comentário',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Conte-nos sobre a sua experiência...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sugestões de comentário
            const Text(
              'Considere mencionar:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...[
              '• Estado do veículo',
              '• Pontualidade na entrega',
              '• Comunicação com o proprietário',
              '• Se recomendaria a outros',
            ].map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 32),

            // Botão submeter
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enviar Avaliação'),
              ),
            ),

            const SizedBox(height: 16),

            // Nota
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A sua avaliação ajuda outros utilizadores e o proprietário a melhorar',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
