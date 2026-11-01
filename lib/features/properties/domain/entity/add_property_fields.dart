/// Field keys of the add-property steps, used in
/// `ValidationFailure.fieldErrors`.
///
/// There is no properties API yet; when it exists, alias its `AppApi` keys
/// here instead.
abstract final class AddPropertyFields {
  // Step 1.
  static const String title = 'title';
  static const String address = 'address';
  static const String rooms = 'rooms';

  // Step 3.
  static const String pricePerNight = 'pricePerNight';
  static const String deposit = 'deposit';
  static const String checkInTime = 'checkInTime';
  static const String checkOutTime = 'checkOutTime';
  static const String minNights = 'minNights';
  static const String cleaningFee = 'cleaningFee';
}
