import 'enums.dart';

class UiNotification {
  const UiNotification(this.type, {this.body});
  final SyncNotify type;
  final String? body;

	@override
	  String toString() {
	    return 
'''{
	type: $type,
	body: $body
}''';
	  }
}
