import 'package:easy_booking/core/utils/error/failure.dart';

extension FailureMessage on Failure {
  /// Text safe to show to the user. Technical details stay in [message].
  ///
  /// Server messages are not shown because their language and wording are
  /// not controlled by the app; use [ValidationFailure.fieldErrors] or the
  /// error code to build specific texts in the feature.
  String get userMessage {
    return switch (this) {
      ConnectionFailure() => 'Нет подключения к интернету',
      TimeoutFailure() => 'Сервер долго не отвечает. Попробуйте ещё раз',
      CancelledFailure() => 'Запрос отменён',
      UnauthorizedFailure() => 'Сессия истекла. Войдите снова',
      ValidationFailure() => 'Проверьте введённые данные',
      ServerFailure() => 'Сервис временно недоступен. Попробуйте позже',
      ParsingFailure() => 'Не удалось обработать ответ сервера',
      StorageFailure() => 'Не удалось сохранить данные на устройстве',
      UnexpectedFailure() => 'Что-то пошло не так. Попробуйте ещё раз',
    };
  }
}
