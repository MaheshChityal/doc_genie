import 'package:doc_genie/common/generic_state.dart';
import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/home/controller/home_controller.dart';
import 'package:doc_genie/feature/home/model/home_model.dart';
import 'package:doc_genie/widgets/app_card.dart';
import 'package:doc_genie/widgets/app_loader.dart';
import 'package:doc_genie/widgets/error_retry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);

    if (state is LoadingState || state is InitialState) {
      return const AppLoader();
    }

    if (state is ErrorState) {
      return ErrorRetry(
        message: state.exception.message,
        onRetry: () =>
            ref.read(homeControllerProvider.notifier).fetchHomeFeed(
              shouldRefresh: true,
            ),
      );
    }

    final data =
        (state as LoadedState<HomeModel>).response ?? const HomeModel();

    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeroCard(stats: data.stats),
          const SizedBox(height: 20),
          _SectionHeader(
            eyebrow: 'Activity',
            title: 'Recent Documents',
            subtitle: 'Latest submissions and their current status.',
          ),
          const SizedBox(height: 14),
          for (final activity in data.recentActivity) ...[
            _ActivityCard(activity: activity),
            const SizedBox(height: 12),
          ],
          if (data.recentActivity.isEmpty)
            const _EmptyPane(
              icon: Icons.inbox_rounded,
              title: 'No recent activity',
              subtitle: 'Documents you submit will appear here.',
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats});

  final List<HomeStat> stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      gradient: ColorConstants.heroGradient,
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'DocGenie Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Document Processing Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.05,
              letterSpacing: -0.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track RTGS, NEFT, and Fund Transfer documents across Maker and Checker workflows.',
            style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth >= 700
                  ? 4
                  : constraints.maxWidth >= 500
                  ? 3
                  : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 80,
                ),
                itemBuilder: (context, index) => _StatCard(stat: stats[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final HomeStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: AppTextStyles.eyebrow),
        const SizedBox(height: 6),
        Text(title, style: AppTextStyles.heading.copyWith(fontSize: 21)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTextStyles.caption),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final RecentActivity activity;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(activity.status);
    final typeColor = _typeColor(activity.transactionType);
    return AppCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: ColorConstants.surface,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.description_rounded, color: typeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.referenceNumber, style: AppTextStyles.subtitle),
                const SizedBox(height: 3),
                Text(
                  '${activity.transactionType} · ${activity.date}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              activity.status,
              style: AppTextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return ColorConstants.successColor;
      case 'Rejected':
        return ColorConstants.errorColor;
      default:
        return ColorConstants.warningColor;
    }
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'RTGS':
        return ColorConstants.infoColor;
      case 'NEFT':
        return ColorConstants.secondaryColor;
      default:
        return ColorConstants.accentColor;
    }
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      backgroundColor: ColorConstants.surface,
      child: Column(
        children: [
          Icon(icon, size: 40, color: ColorConstants.textMuted),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
