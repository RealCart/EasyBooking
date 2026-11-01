part of 'edit_profile_bloc.dart';

sealed class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the details that fill the form: added when the BLoC is created
/// and on retry.
final class EditProfileStarted extends EditProfileEvent {
  const EditProfileStarted();
}

/// The user edited [field] (a `ProfileFields` key); clears its server
/// error.
final class EditProfileFieldEdited extends EditProfileEvent {
  const EditProfileFieldEdited(this.field);

  final String field;

  @override
  List<Object?> get props => <Object?>[field];
}

/// «Сохранить» with the validated form.
final class EditProfileSubmitted extends EditProfileEvent {
  const EditProfileSubmitted(this.params);

  final UpdateProfileParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}
