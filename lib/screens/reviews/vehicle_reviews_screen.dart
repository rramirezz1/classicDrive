import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/review_model.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/rating_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleReviewsScreen extends StatelessWidget {
  final String vehicleId;
  final VehicleModel vehicle;

  const VehicleReviewsScreen({
    super.key,
    required this.vehicleId,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliações'),
      ),
      body: Column(
        children: [
          // Resumo das avaliações
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('reviews')
                  .stream(primaryKey: ['id']).eq('vehicle_id', vehicleId),
              builder: (context, snapshot) {
                final reviews = snapshot.data ?? [];
                final reviewCount = reviews.length;
                
                double avgRating = 0.0;
                if (reviewCount > 0) {
                  final total = reviews.fold<double>(
                      0, (sum, item) => sum + (item['rating'] as num).toDouble());
                  avgRating = total / reviewCount;
                }

                return Column(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RatingWidget(
                      rating: avgRating,
                      size: 32,
                      readOnly: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Baseado em $reviewCount ${reviewCount == 1 ? "avaliação" : "avaliações"}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Lista de avaliações
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('reviews')
                  .stream(primaryKey: ['id'])
                  .eq('vehicle_id', vehicleId)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ainda não há avaliações',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seja o primeiro a avaliar!',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final reviews = snapshot.data!
                    .map((data) => ReviewModel.fromMap(data))
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return _ReviewCard(review: review);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              child: Text(
                review.reviewerName[0].toUpperCase(),
                style: const TextStyle(
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
                    review.reviewerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(review.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            RatingWidget(
              rating: review.rating,
              size: 20,
              readOnly: true,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Comentário
        Text(
          review.comment,
          style: const TextStyle(
            height: 1.5,
          ),
        ),

        // Imagens (se houver)
        if (review.images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: review.images.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(review.images[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
