part of 'add_property_bloc.dart';

sealed class AddPropertyEvent extends Equatable {
  const AddPropertyEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the draft to prefill the step: added when the BLoC is created and
/// on retry.
final class AddPropertyStarted extends AddPropertyEvent {
  const AddPropertyStarted();
}

/// The user edited the field [field] (an `AddPropertyFields` key).
final class AddPropertyFieldEdited extends AddPropertyEvent {
  const AddPropertyFieldEdited(this.field);

  final String field;

  @override
  List<Object?> get props => <Object?>[field];
}

/// Step 1 («Продолжить») with the validated form.
final class AddPropertyDetailsSubmitted extends AddPropertyEvent {
  const AddPropertyDetailsSubmitted(this.params);

  final SaveAddPropertyDetailsParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

/// Step 2 («Продолжить») with the chosen channels; may be empty.
final class AddPropertyChannelsSubmitted extends AddPropertyEvent {
  const AddPropertyChannelsSubmitted(this.params);

  final SaveAddPropertyChannelsParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

/// Step 3 («Добавить квартиру») with the validated terms; publishes.
final class AddPropertyTermsSubmitted extends AddPropertyEvent {
  const AddPropertyTermsSubmitted(this.params);

  final PublishPropertyParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
