import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';

void main() {
  group('RequestStatus', () {
    test('declares the four statuses in order', () {
      expect(RequestStatus.values, <RequestStatus>[
        RequestStatus.initial,
        RequestStatus.loading,
        RequestStatus.success,
        RequestStatus.failure,
      ]);
    });

    test('exactly one getter is true for each status', () {
      for (final RequestStatus status in RequestStatus.values) {
        final List<bool> flags = <bool>[
          status.isInitial,
          status.isLoading,
          status.isSuccess,
          status.isFailure,
        ];

        expect(flags.where((bool flag) => flag), hasLength(1));
        expect(flags[status.index], isTrue, reason: '$status');
      }
    });
  });
}
