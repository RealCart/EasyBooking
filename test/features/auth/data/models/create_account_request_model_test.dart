import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/features/auth/data/models/create_account_request_model.dart';
import 'package:easy_booking/features/auth/domain/entity/create_account_params_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';

void main() {
  group('CreateAccountRequestModel', () {
    test('fromEntity maps the city to its id and time zone', () {
      final CreateAccountRequestModel model =
          CreateAccountRequestModel.fromEntity(
            const CreateAccountParamsEntity(
              firstName: 'Айгерим',
              lastName: 'Садыкова',
              email: 'aigerim@example.kz',
              teamName: 'Esentai Stay',
              city: KazakhstanCities.aktobe,
            ),
          );

      expect(model.firstName, 'Айгерим');
      expect(model.lastName, 'Садыкова');
      expect(model.email, 'aigerim@example.kz');
      expect(model.teamName, 'Esentai Stay');
      expect(model.city, 'aktobe');
      expect(model.timeZone, 'Asia/Aqtobe');
    });

    test('toJson uses the API keys, including timeZone', () {
      const CreateAccountRequestModel model = CreateAccountRequestModel(
        firstName: 'Айгерим',
        lastName: 'Садыкова',
        email: 'aigerim@example.kz',
        teamName: 'Esentai Stay',
        city: 'almaty',
        timeZone: 'Asia/Almaty',
      );

      expect(model.toJson(), <String, Object?>{
        'firstName': 'Айгерим',
        'lastName': 'Садыкова',
        'email': 'aigerim@example.kz',
        'teamName': 'Esentai Stay',
        'city': 'almaty',
        'timeZone': 'Asia/Almaty',
      });
    });
  });
}
