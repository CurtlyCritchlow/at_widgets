import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_contact/at_contact.dart';
import 'package:at_events_flutter/at_events_flutter.dart';
import 'package:at_events_flutter/models/event_key_location_model.dart';
import 'package:at_events_flutter/models/event_notification.dart';
import 'package:at_events_flutter/screens/notification_dialog/event_notification_dialog.dart';
import 'package:at_location_flutter/service/master_location_service.dart';
import 'package:at_location_flutter/service/send_location_notification.dart';
import 'package:at_location_flutter/utils/constants/init_location_service.dart';
import 'package:flutter/material.dart';

import 'at_event_notification_listener.dart';

class HomeEventService {
  HomeEventService._();
  static final HomeEventService _instance = HomeEventService._();
  factory HomeEventService() => _instance;

  bool isActionRequired(EventNotificationModel event) {
    if (event.isCancelled!) return true;

    var _eventInfo = getMyEventInfo(event);

    if (_eventInfo == null) {
      return true;
    }

    if (_eventInfo.isExited) {
      return true;
    }

    if (!_eventInfo.isAccepted) {
      return true;
    } else {
      return false;
    }

    // var isRequired = true;
    // var currentAtsign = AtEventNotificationListener()
    //     .atClientManager
    //     .atClient
    //     .getCurrentAtSign();

    // if (event.group!.members!.isEmpty) return true;

    // event.group!.members!.forEach((member) {
    //   if (member.atSign![0] != '@') member.atSign = '@' + member.atSign!;
    //   if (currentAtsign![0] != '@') currentAtsign = '@' + currentAtsign!;

    //   if ((member.tags!['isAccepted'] != null &&
    //           member.tags!['isAccepted'] == true) &&
    //       member.tags!['isExited'] == false &&
    //       member.atSign!.toLowerCase() == currentAtsign!.toLowerCase()) {
    //     isRequired = false;
    //   }
    // });

    // if (event.atsignCreator == currentAtsign) isRequired = false;

    // return isRequired;
  }

  String getActionString(EventNotificationModel event, bool haveResponded) {
    if (event.isCancelled!) return 'Cancelled';
    var label = 'Action required';

    var _eventInfo = getMyEventInfo(event);

    if (_eventInfo == null) {
      return 'Action required';
    }

    if (_eventInfo.isExited) {
      return 'Request declined';
    }

    if (!_eventInfo.isAccepted) {
      return 'Action required';
    }

    return 'Action required';

    // var currentAtsign = AtEventNotificationListener()
    //     .atClientManager
    //     .atClient
    //     .getCurrentAtSign();

    // if (event.group!.members!.isEmpty) return '';

    // event.group!.members!.forEach((member) {
    //   if (member.atSign![0] != '@') member.atSign = '@' + member.atSign!;
    //   if (currentAtsign![0] != '@') currentAtsign = '@' + currentAtsign!;

    //   if (member.tags!['isExited'] != null &&
    //       member.tags!['isExited'] == true &&
    //       member.atSign!.toLowerCase() == currentAtsign!.toLowerCase()) {
    //     label = 'Request declined';
    //   } else if (member.tags!['isExited'] != null &&
    //       member.tags!['isExited'] == false &&
    //       member.tags!['isAccepted'] != null &&
    //       member.tags!['isAccepted'] == false &&
    //       member.atSign!.toLowerCase() == currentAtsign!.toLowerCase() &&
    //       haveResponded) {
    //     label = 'Pending request';
    //   }
    // });

    // return label;
  }

  String getSubTitle(EventNotificationModel _event) {
    return _event.event != null
        ? _event.event!.date != null
            ? 'Event on ${dateToString(_event.event!.date!)}'
            : ''
        : '';
  }

  String? getSemiTitle(EventNotificationModel _event, bool _haveResponded) {
    return
        // _event.group != null
        //     ?
        (isActionRequired(_event))
            ? getActionString(_event, _haveResponded)
            : null;
    // : 'Action required';
  }

  bool calculateShowRetry(EventKeyLocationModel _eventKeyModel) {
    if ((_eventKeyModel.eventNotificationModel!.group != null) &&
        (isActionRequired(_eventKeyModel.eventNotificationModel!)) &&
        (_eventKeyModel.haveResponded)) {
      if (getActionString(_eventKeyModel.eventNotificationModel!,
              _eventKeyModel.haveResponded) ==
          'Pending request') {
        return true;
      }
      return false;
    }
    return false;
  }

  // ignore: always_declare_return_types
  onEventModelTap(
      EventNotificationModel eventNotificationModel, bool haveResponded) {
    if (isActionRequired(eventNotificationModel) &&
        !eventNotificationModel.isCancelled!) {
      if (haveResponded) {
        eventNotificationModel.isUpdate = true;
        EventsMapScreenData().moveToEventScreen(eventNotificationModel);
        return null;
      }
      return showDialog<void>(
        context: AtEventNotificationListener().navKey!.currentContext!,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return EventNotificationDialog(eventData: eventNotificationModel);
        },
      );
    }

    eventNotificationModel.isUpdate = true;

    /// Move to map screen
    EventsMapScreenData().moveToEventScreen(eventNotificationModel);
  }

  /// will return for event's for which i am member
  EventInfo? getMyEventInfo(EventNotificationModel _event) {
    String _id = trimAtsignsFromKey(_event.key!);
    String? _atsign;

    if (!compareAtSign(_event.atsignCreator!,
        AtClientManager.getInstance().atClient.getCurrentAtSign()!)) {
      _atsign = _event.atsignCreator;
    }

    if (_atsign == null && _event.group!.members!.isNotEmpty) {
      Set<AtContact>? groupMembers = _event.group!.members!;

      for (var member in groupMembers) {
        if (!compareAtSign(member.atSign!,
            AtClientManager.getInstance().atClient.getCurrentAtSign()!)) {
          _atsign = member.atSign;
          break;
        }
      }
    }

    if (SendLocationNotification().allAtsignsLocationData != null) {
      if (SendLocationNotification()
              .allAtsignsLocationData[_atsign]!
              .locationSharingFor[_id] !=
          null) {
        var _locationSharingFor = SendLocationNotification()
            .allAtsignsLocationData[_atsign]!
            .locationSharingFor[_id]!;

        return EventInfo(
            isSharing: _locationSharingFor.isSharing,
            isExited: _locationSharingFor.isExited,
            isAccepted: _locationSharingFor.isAccepted);
      }
    }

    for (var key in SendLocationNotification().allAtsignsLocationData.entries) {
      if (SendLocationNotification()
              .allAtsignsLocationData[key.key]!
              .locationSharingFor[_id] !=
          null) {
        var _locationSharingFor = SendLocationNotification()
            .allAtsignsLocationData[key.key]!
            .locationSharingFor[_id]!;

        return EventInfo(
            isSharing: _locationSharingFor.isSharing,
            isExited: _locationSharingFor.isExited,
            isAccepted: _locationSharingFor.isAccepted);
      }
    }
  }

  /// will return for event's for which i am creator
  EventInfo? getOtherMemberEventInfo(String _id) {
    _id = trimAtsignsFromKey(_id);

    for (var key in MasterLocationService().locationReceivedData.entries) {
      if (MasterLocationService()
              .locationReceivedData[key.key]!
              .locationSharingFor[_id] !=
          null) {
        var _locationSharingFor = MasterLocationService()
            .locationReceivedData[key.key]!
            .locationSharingFor[_id]!;

        return EventInfo(
            isSharing: _locationSharingFor.isSharing,
            isExited: _locationSharingFor.isExited,
            isAccepted: _locationSharingFor.isAccepted);
      }
    }
  }
}
