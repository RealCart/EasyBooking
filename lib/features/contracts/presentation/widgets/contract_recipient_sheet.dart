import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_primary_button.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/phone_input_formatter.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_labels.dart';

/// «Кому отправить»: picks the channel and the address of the signing link.
///
/// Pops the chosen [ContractRecipientEntity] (a phone in E.164 format or an
/// email); nothing is sent until the screen submits it.
final class ContractRecipientSheet extends StatefulWidget {
  const ContractRecipientSheet({
    required this.initialRecipient,
    required this.guestPhone,
    super.key,
  });

  final ContractRecipientEntity initialRecipient;

  /// Prefills the phone when the initial recipient is an email.
  final String guestPhone;

  @override
  State<ContractRecipientSheet> createState() => _ContractRecipientSheetState();
}

final class _ContractRecipientSheetState extends State<ContractRecipientSheet> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _addressController;
  late final FocusNode _addressFocusNode;
  late ContractDeliveryChannel _channel;

  /// The text of the other address kind, restored when the user switches
  /// between a phone channel and email.
  late String _otherKindText;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _addressFocusNode = FocusNode();
    final ContractRecipientEntity recipient = widget.initialRecipient;
    _channel = recipient.channel;
    if (recipient.channel.usesPhone) {
      _addressController = TextEditingController(
        text: PhoneNumber.formatNational(recipient.address),
      );
      _otherKindText = '';
    } else {
      _addressController = TextEditingController(text: recipient.address);
      _otherKindText = PhoneNumber.formatNational(widget.guestPhone);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  void _selectChannel(ContractDeliveryChannel channel) {
    if (channel == _channel) {
      return;
    }
    setState(() {
      if (channel.usesPhone != _channel.usesPhone) {
        final String current = _addressController.text;
        _addressController.text = _otherKindText;
        _otherKindText = current;
      }
      _channel = channel;
    });
  }

  void _submit() {
    context.hideKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String text = _addressController.text;
    final String address = _channel.usesPhone
        ? PhoneNumber.toE164(text) ?? text.trim()
        : text.trim();
    Navigator.of(
      context,
    ).pop(ContractRecipientEntity(channel: _channel, address: address));
  }

  @override
  Widget build(BuildContext context) {
    final bool usesPhone = _channel.usesPhone;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            AppSpacing.xLarge,
            AppSizes.pageGutter,
            AppSpacing.large,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Кому отправить',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Гость получит ссылку на договор и подпишет его онлайн',
                  style: AppTypography.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: <Widget>[
                    for (final ContractDeliveryChannel channel
                        in ContractDeliveryChannel.values)
                      Semantics(
                        button: true,
                        selected: channel == _channel,
                        label: channel.label,
                        excludeSemantics: true,
                        child: AppChoiceChip(
                          label: channel.label,
                          isSelected: channel == _channel,
                          onSelected: (_) => _selectChannel(channel),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.large),
                AppTextField(
                  // A new field state per address kind, so a phone error is
                  // not shown under an email.
                  key: ValueKey<bool>(usesPhone),
                  controller: _addressController,
                  focusNode: _addressFocusNode,
                  label: usesPhone ? 'Телефон' : 'Email',
                  leading: usesPhone
                      ? Text(
                          PhoneNumber.countryCode,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.text,
                          ),
                        )
                      : null,
                  validator: usesPhone
                      ? FormValidators.phone
                      : FormValidators.email,
                  keyboardType: usesPhone
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  inputFormatters: usesPhone
                      ? const <PhoneInputFormatter>[PhoneInputFormatter()]
                      : null,
                  autocorrect: false,
                  autofillHints: <String>[
                    if (usesPhone)
                      AutofillHints.telephoneNumberNational
                    else
                      AutofillHints.email,
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xLarge),
                AppPrimaryButton.compact(label: 'Готово', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
