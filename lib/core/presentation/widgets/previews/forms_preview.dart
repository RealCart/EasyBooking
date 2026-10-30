import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:easy_booking/core/presentation/widgets/forms/app_document_tile.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_phone_country_fields.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_search_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_upload_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_value_field.dart';
import 'package:easy_booking/core/presentation/widgets/previews/app_preview_gallery.dart';

@Preview(
  name: 'Forms',
  group: 'EasyBooking Core Widgets',
  size: Size(430, 900),
  wrapper: appWidgetPreviewWrapper,
)
Widget formsWidgetPreview() => const _FormsPreview();

class _FormsPreview extends StatefulWidget {
  const _FormsPreview();

  @override
  State<_FormsPreview> createState() => _FormsPreviewState();
}

class _FormsPreviewState extends State<_FormsPreview> {
  final TextEditingController _searchController = TextEditingController(
    text: 'Esentai',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+7 700 123 45 67',
  );
  final TextEditingController _moneyController = TextEditingController(
    text: '42 500',
  );
  String _country = 'Kazakhstan (+7)';

  @override
  void dispose() {
    _searchController.dispose();
    _phoneController.dispose();
    _moneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPreviewGallery(
      title: 'Forms',
      description: 'Fields are editable; upload and footer actions are active.',
      children: <Widget>[
        const AppPreviewSection(
          title: 'Text fields',
          child: Column(
            children: <Widget>[
              AppTextField(
                label: 'Full name',
                initialValue: 'Daniyar Muratov',
              ),
              SizedBox(height: 12),
              AppTextField(
                label: 'ID number',
                initialValue: '•••••• ••• 214',
                obscureText: true,
                trailing: Icon(Icons.visibility_outlined),
              ),
              SizedBox(height: 12),
              AppTextField(
                label: 'iCal link',
                initialValue: 'https://calendar.example',
                errorText: 'The link must end with .ics',
              ),
              SizedBox(height: 12),
              AppTextField(
                label: 'Disabled',
                initialValue: 'Unavailable value',
                enabled: false,
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Search',
          description: 'Edit the query or use the clear action.',
          child: AppSearchField(
            controller: _searchController,
            hint: 'Search properties',
            subtitle: 'Name or address',
            onSubmitted: (String value) => _notify('Searching for “$value”'),
          ),
        ),
        AppPreviewSection(
          title: 'Phone and country',
          child: AppPhoneCountryFields(
            countryValue: _country,
            phoneController: _phoneController,
            onCountryPressed: () {
              setState(() {
                _country = _country.startsWith('Kazakhstan')
                    ? 'Kyrgyzstan (+996)'
                    : 'Kazakhstan (+7)';
              });
            },
          ),
        ),
        AppPreviewSection(
          title: 'Upload',
          child: AppUploadField(
            title: 'Add photo',
            description: 'You can change the cover later',
            onPressed: () => _notify('Upload picker requested'),
          ),
        ),
        AppPreviewSection(
          title: 'Uploaded document',
          child: AppDocumentTile(
            fileName: 'Identity-card.pdf',
            details: '2 pages · 842 KB',
            actionLabel: 'Replace',
            onAction: () => _notify('Replace document tapped'),
          ),
        ),
        AppPreviewSection(
          title: 'Money and time',
          child: Column(
            children: <Widget>[
              AppValueField(
                type: AppValueFieldType.money,
                controller: _moneyController,
                label: 'Nightly rate',
                currencySymbol: '₸',
              ),
              const SizedBox(height: 12),
              AppValueField(
                type: AppValueFieldType.time,
                initialValue: '14:00',
                label: 'Check-in time',
                readOnly: true,
                onTap: () => _notify('Time picker requested'),
              ),
            ],
          ),
        ),
        AppPreviewSection(
          title: 'Flow footer',
          child: AppFlowFooter(
            message: 'Next — connect channels and calendars',
            primaryLabel: 'Continue',
            secondaryLabel: 'Back',
            onPrimaryPressed: () => _notify('Continue tapped'),
            onSecondaryPressed: () => _notify('Back tapped'),
          ),
        ),
      ],
    );
  }

  void _notify(String message) => showPreviewMessage(context, message);
}
