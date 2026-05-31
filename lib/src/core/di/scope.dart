import '../../core/storage/prefs_store.dart';
import '../../features/calls/controller/calls_controller.dart';
import '../../features/chats/controller/chats_controller.dart';
import '../../features/contacts/controller/contacts_controller.dart';
import '../../features/groups/controller/groups_controller.dart';
import '../../features/profile/controller/profile_controller.dart';
import '../../features/settings/controller/ui_settings_controller.dart';
import '../../features/xmpp/controller/xmpp_controller.dart';
import '../../features/xmpp/service/xmpp_service.dart';

class Scope {
  late final PrefsStore prefs;

  late final XmppService xmppService;

  late final UiSettingsController uiSettings;
  late final ProfileController profile;
  late final XmppController xmpp;
  late final ContactsController contacts;
  late final ChatsController chats;
  late final GroupsController groups;
  late final CallsController calls;

  Future<void> bootstrap() async {
    prefs = await PrefsStore.create();

    xmppService = XmppService.instance;
    await xmppService.loadConfig();

    uiSettings = UiSettingsController(prefs)..bootstrap();
    profile = ProfileController(prefs)..bootstrap();

    xmpp = XmppController(prefs, xmppService)..bootstrap();
    contacts = ContactsController(xmppService)..bootstrap();

    chats = ChatsController(xmppService)..bootstrap();
    groups = GroupsController(prefs)..bootstrap();
    calls = CallsController()..bootstrap();
  }
}
