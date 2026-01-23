import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Card de perfil de utilizador.
class UserProfileCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String memberSince;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;

  const UserProfileCard({
    super.key,
    required this.name,
    this.avatarUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.isVerified = false,
    required this.memberSince,
    this.onTap,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: AppRadius.borderRadiusLg,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryOpacity70,
                      ],
                    ),
                  ),
                  child: avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                if (isVerified)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating > 0 ? rating.toStringAsFixed(1) : 'Novo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (reviewCount > 0) ...[
                        Text(
                          ' ($reviewCount)',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        memberSince,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Message button
            if (onMessage != null)
              IconButton(
                onPressed: onMessage,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOpacity10,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.message_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget de partilha de veículo.
class ShareVehicleSheet extends StatelessWidget {
  final String vehicleName;
  final String vehicleUrl;
  final VoidCallback? onClose;

  const ShareVehicleSheet({
    super.key,
    required this.vehicleName,
    required this.vehicleUrl,
    this.onClose,
  });

  static void show(BuildContext context, {
    required String vehicleName,
    required String vehicleUrl,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareVehicleSheet(
        vehicleName: vehicleName,
        vehicleUrl: vehicleUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardHover : Colors.grey[300],
              borderRadius: AppRadius.borderRadiusFull,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Partilhar Veículo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            vehicleName,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Share options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareOption(
                context,
                Icons.link_rounded,
                'Copiar Link',
                AppColors.primary,
                () {
                  Clipboard.setData(ClipboardData(text: vehicleUrl));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Link copiado!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                isDark,
              ),
              _buildShareOption(
                context,
                Icons.message_rounded,
                'WhatsApp',
                const Color(0xFF25D366),
                () {
                  // Abrir WhatsApp
                  Navigator.pop(context);
                },
                isDark,
              ),
              _buildShareOption(
                context,
                Icons.email_rounded,
                'Email',
                AppColors.info,
                () {
                  // Abrir email
                  Navigator.pop(context);
                },
                isDark,
              ),
              _buildShareOption(
                context,
                Icons.more_horiz_rounded,
                'Mais',
                isDark ? AppColors.darkTextSecondary : Colors.grey,
                () {
                  // Mais opções
                  Navigator.pop(context);
                },
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // URL preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardHover : Colors.grey[100],
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    vehicleUrl,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet para contactar proprietário.
class ContactOwnerSheet extends StatelessWidget {
  final String ownerName;
  final String? ownerPhone;
  final String? ownerEmail;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onEmail;

  const ContactOwnerSheet({
    super.key,
    required this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
    this.onCall,
    this.onMessage,
    this.onEmail,
  });

  static void show(BuildContext context, {
    required String ownerName,
    String? ownerPhone,
    String? ownerEmail,
    VoidCallback? onCall,
    VoidCallback? onMessage,
    VoidCallback? onEmail,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContactOwnerSheet(
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        ownerEmail: ownerEmail,
        onCall: onCall,
        onMessage: onMessage,
        onEmail: onEmail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardHover : Colors.grey[300],
              borderRadius: AppRadius.borderRadiusFull,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryOpacity10,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contactar Proprietário',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      ownerName,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact options
          if (ownerPhone != null)
            _buildContactOption(
              context,
              Icons.phone_rounded,
              'Ligar',
              ownerPhone!,
              AppColors.success,
              onCall,
              isDark,
            ),
          if (onMessage != null)
            _buildContactOption(
              context,
              Icons.chat_rounded,
              'Mensagem na App',
              'Chat em tempo real',
              AppColors.primary,
              onMessage,
              isDark,
            ),
          if (ownerEmail != null)
            _buildContactOption(
              context,
              Icons.email_rounded,
              'Email',
              ownerEmail!,
              AppColors.info,
              onEmail,
              isDark,
            ),

          const SizedBox(height: 12),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningOpacity10,
              borderRadius: AppRadius.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Comunique sempre através da plataforma para sua segurança',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback? onTap,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            borderRadius: AppRadius.borderRadiusMd,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget para mostrar resposta rápida.
class QuickReplyChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const QuickReplyChip({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: AppRadius.borderRadiusFull,
          border: Border.all(
            color: AppColors.primaryOpacity30,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
