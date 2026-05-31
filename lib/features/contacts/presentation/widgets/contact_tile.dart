import 'package:flutter/material.dart';

import 'package:app_design/features/contacts/domain/contact.dart';
import 'package:app_design/features/contacts/presentation/contact_info_popup.dart';
import 'package:app_design/core/ui/corporate_ui.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onOpenChat;

  const ContactTile({
    super.key,
    required this.contact,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CorporateUi.radius),
        side: BorderSide(color: Colors.transparent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(CorporateUi.radius),
        onTap: onOpenChat,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => showContactInfoPopup(context, contact: contact),
                child: CorporateAvatar(initials: contact.initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.jid,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.primary.withOpacity(0.65)),
            ],
          ),
        ),
      ),
    );
  }
}
