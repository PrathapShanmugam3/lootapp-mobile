import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final client = ref.watch(apiClientProvider).requireValue;
  return ReportsRepository(client);
});

class ReportsFilter {
  const ReportsFilter({required this.dateOption, this.startDate, this.endDate});

  final String dateOption;
  final String? startDate;
  final String? endDate;

  @override
  bool operator ==(Object other) =>
      other is ReportsFilter &&
      other.dateOption == dateOption &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(dateOption, startDate, endDate);
}

final reportsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, ReportsFilter>((ref, filter) {
  return ref.watch(reportsRepositoryProvider).getReports(
        dateOption: filter.dateOption,
        startDate: filter.startDate,
        endDate: filter.endDate,
      );
});

class DetailedReportFilter {
  const DetailedReportFilter({required this.offId, this.startDate, this.endDate});

  final String offId;
  final String? startDate;
  final String? endDate;

  @override
  bool operator ==(Object other) =>
      other is DetailedReportFilter &&
      other.offId == offId &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(offId, startDate, endDate);
}

final detailedReportProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, DetailedReportFilter>((ref, filter) {
  return ref.watch(reportsRepositoryProvider).getDetailedReport(
        offId: filter.offId,
        startDate: filter.startDate,
        endDate: filter.endDate,
      );
});
