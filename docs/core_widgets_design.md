# Core widget design notes

The EasyBooking Paper design-system artboards are the reference for the core widgets. The mobile artboards provide context-specific variants, including the 48 px flow button and borderless header actions. `AppColors`, `AppTypography`, `AppSpacing`, `AppRadii`, and `AppSizes` hold shared values; semantic surface colors and body letter spacing follow the Paper tokens.

## Decisions where Paper does not specify behavior

- The reference artboards show a 430 px mobile canvas. Components adapt to their incoming constraints, and narrow layouts may wrap or stack content. Images retain the reference aspect ratio when their width changes.
- Controls retain at least a 44 px interactive target where possible, even when the visible control is smaller. Text can increase component height at larger accessibility text scales.
- Paper does not specify every keyboard focus, loading, or disabled treatment. Those states use the design tokens. Ripple and hover feedback are intentionally suppressed throughout the app; only `AppPrimaryButton` retains its explicit Paper hover and pressed colors.
- Safe-area padding follows the device's system insets. Paper's drawn home indicator is not duplicated by the widgets.
- The generic outlined icon actions follow the component library. Header actions use their separate borderless, 22 px treatment from the mobile screens.
- Dialog, conflict, snackbar, resend, and section actions keep their context-specific text treatments: Paper specifies colors or sizes that differ from the three general text-button styles.

## Migration notes

- Use `AppPrimaryButton` or `AppPrimaryButton.compact` and `AppSecondaryButton` in place of the removed `AppButton` variant API. The compact primary matches the 48 px flow footer.
- `AppTextButton` provides accent, underlined, and muted treatments. `AppSavedIconButton` uses its `isSaved` state to select the Paper appearance.
- `AppArrivalCard.leading` represents the property image in the Paper layout. `AppCalendarEventRow.image` supplies the optional thumbnail; its obsolete colored indicator parameter was removed.
- `AppSignatureStep.statusLabel` can provide a localized status label. The signature document title and resend prompt remain available for semantics when they are not visible in the reference layout.

Interactive galleries live in `lib/core/widgets/previews/` and include narrow, enlarged-text examples for the component groups that need them. Widget tests cover representative dimensions, interaction, semantics, and constrained layouts. They are not pixel goldens; visual review against the Paper artboards remains useful when changing the design.
