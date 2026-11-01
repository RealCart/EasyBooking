import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';

/// Step 3 of «Добавить квартиру»: the terms, after which the draft becomes
/// a property.
final class PublishPropertyParamsEntity extends Equatable {
  const PublishPropertyParamsEntity({required this.terms});

  final PropertyTermsEntity terms;

  @override
  List<Object?> get props => <Object?>[terms];
}
