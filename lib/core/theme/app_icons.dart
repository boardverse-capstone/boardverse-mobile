import 'package:flutter/material.dart';

/// Icon System - Sử dụng Material Icons (Icons class)
/// Đảm bảo consistent design với các icon có sẵn trong Flutter
/// Xem thêm: https://fonts.google.com/icons
class AppIcons {
  AppIcons._();

  // ========================
  // ICON SIZES
  // ========================

  /// Extra small - Inline với text nhỏ
  static const double xs = 12.0;

  /// Small - Chips, small labels
  static const double sm = 16.0;

  /// Medium - Default icon size
  static const double md = 20.0;

  /// Large - Navigation, featured
  static const double lg = 24.0;

  /// Extra large - Empty state icons
  static const double xl = 32.0;

  /// Extra extra large - Large decorative icons
  static const double xxl = 48.0;

  // ========================
  // NAVIGATION ICONS
  // ========================

  /// Explore/Discover tab
  static const IconData explore = Icons.explore_outlined;

  /// Booking/Schedule tab
  static const IconData booking = Icons.calendar_month_outlined;

  /// Tournament/Ranking tab
  static const IconData tournament = Icons.emoji_events_outlined;

  /// Profile tab
  static const IconData profile = Icons.account_circle_outlined;

  /// Home
  static const IconData home = Icons.home_outlined;

  /// Back arrow
  static const IconData back = Icons.arrow_back;

  /// Forward arrow
  static const IconData forward = Icons.arrow_forward;

  /// Menu
  static const IconData menu = Icons.menu;

  /// Close
  static const IconData close = Icons.close;

  /// More options
  static const IconData moreVertical = Icons.more_vert;

  /// More options horizontal
  static const IconData moreHorizontal = Icons.more_horiz;

  // ========================
  // GAME ICONS
  // ========================

  /// Board game
  static const IconData boardGame = Icons.sports_esports_outlined;

  /// Card game
  static const IconData cardGame = Icons.layers_outlined;

  /// Strategy game
  static const IconData strategy = Icons.track_changes;

  /// Party game
  static const IconData party = Icons.celebration_outlined;

  /// Dice
  static const IconData dice = Icons.casino_outlined;

  /// Chess
  static const IconData chess = Icons.shield_outlined;

  /// Puzzle
  static const IconData puzzle = Icons.extension_outlined;

  /// Game controller
  static const IconData controller = Icons.gamepad_outlined;

  // ========================
  // ACTION ICONS
  // ========================

  /// Search
  static const IconData search = Icons.search;

  /// Filter
  static const IconData filter = Icons.filter_list;

  /// Sort
  static const IconData sort = Icons.sort;

  /// Add
  static const IconData add = Icons.add_circle_outlined;

  /// Add (simple)
  static const IconData addSimple = Icons.add;

  /// Edit
  static const IconData edit = Icons.edit_outlined;

  /// Delete
  static const IconData delete = Icons.delete_outline;

  /// Share
  static const IconData share = Icons.share_outlined;

  /// Copy
  static const IconData copy = Icons.copy;

  /// Download
  static const IconData download = Icons.download_outlined;

  /// Upload
  static const IconData upload = Icons.upload_file;

  /// Refresh
  static const IconData refresh = Icons.refresh;

  /// Reload
  static const IconData reload = Icons.replay;

  // ========================
  // STATUS ICONS
  // ========================

  /// Available/Success
  static const IconData available = Icons.check_circle_outline;

  /// Check (simple)
  static const IconData check = Icons.check;

  /// Busy/Unavailable
  static const IconData busy = Icons.cancel_outlined;

  /// Pending/Waiting
  static const IconData pending = Icons.schedule;

  /// Error
  static const IconData error = Icons.error_outline;

  /// Warning
  static const IconData warning = Icons.warning_amber_outlined;

  /// Info
  static const IconData info = Icons.info_outline;

  /// Help
  static const IconData help = Icons.help_outline;

  // ========================
  // USER & SOCIAL ICONS
  // ========================

  /// Users/Group
  static const IconData users = Icons.group_outlined;

  /// User (single)
  static const IconData user = Icons.person_outline;

  /// User add
  static const IconData userAdd = Icons.person_add_outlined;

  /// User remove
  static const IconData userRemove = Icons.person_remove_outlined;

  /// User check
  static const IconData userCheck = Icons.person_pin;

  /// Rating/Star
  static const IconData rating = Icons.star_outline;

  /// Star filled
  static const IconData starFilled = Icons.star;

  /// Star empty
  static const IconData starEmpty = Icons.star_border;

  /// Heart (like/favorite)
  static const IconData heart = Icons.favorite_border;

  /// Heart filled
  static const IconData heartFilled = Icons.favorite;

  /// Karma/Points
  static const IconData karma = Icons.local_fire_department_outlined;

  /// ELO rating
  static const IconData elo = Icons.bolt;

  /// Level/Rank badge
  static const IconData level = Icons.workspace_premium_outlined;

  /// Chat/Message
  static const IconData chat = Icons.chat_bubble_outline;

  // ========================
  // CAFE & LOCATION ICONS
  // ========================

  /// Cafe/Store
  static const IconData cafe = Icons.store_outlined;

  /// Location/Map pin
  static const IconData location = Icons.location_on_outlined;

  /// Phone
  static const IconData phone = Icons.phone_outlined;

  /// Phone call
  static const IconData phoneCall = Icons.call;

  /// Schedule/Calendar
  static const IconData schedule = Icons.calendar_today_outlined;

  /// Clock/Time
  static const IconData clock = Icons.access_time;

  /// Globe
  static const IconData globe = Icons.language;

  /// Directions
  static const IconData directions = Icons.directions;

  // ========================
  // BOOKING ICONS
  // ========================

  /// Book/Reserve
  static const IconData book = Icons.event_available_outlined;

  /// Cancel booking
  static const IconData cancelBooking = Icons.close;

  /// Confirm booking
  static const IconData confirmBooking = Icons.check;

  /// Booking history
  static const IconData bookingHistory = Icons.history;

  /// Pending booking
  static const IconData pendingBooking = Icons.pending_outlined;

  // ========================
  // MEDIA ICONS
  // ========================

  /// Camera
  static const IconData camera = Icons.camera_alt_outlined;

  /// Camera off
  static const IconData cameraOff = Icons.no_photography;

  /// Image/Gallery
  static const IconData image = Icons.image_outlined;

  /// QR code
  static const IconData qrCode = Icons.qr_code;

  /// QR code scanner
  static const IconData qrScan = Icons.qr_code_scanner;

  /// Video
  static const IconData video = Icons.videocam_outlined;

  /// Video off
  static const IconData videoOff = Icons.videocam_off_outlined;

  // ========================
  // SETTINGS ICONS
  // ========================

  /// Settings
  static const IconData settings = Icons.settings_outlined;

  /// Bell/Notification
  static const IconData bell = Icons.notifications_outlined;

  /// Bell off
  static const IconData bellOff = Icons.notifications_off_outlined;

  /// Lock
  static const IconData lock = Icons.lock_outline;

  /// Unlock
  static const IconData unlock = Icons.lock_open_outlined;

  /// Eye (show)
  static const IconData eye = Icons.visibility_outlined;

  /// Eye off (hide)
  static const IconData eyeOff = Icons.visibility_off_outlined;

  /// Log out
  static const IconData logout = Icons.logout;

  /// Login
  static const IconData login = Icons.login;

  /// Moon/Night mode
  static const IconData moon = Icons.dark_mode_outlined;

  /// Sun/Day mode
  static const IconData sun = Icons.light_mode_outlined;

  /// Language
  static const IconData language = Icons.translate;

  // ========================
  // MONEY & PAYMENT ICONS
  // ========================

  /// Money
  static const IconData money = Icons.account_balance_wallet_outlined;

  /// Credit card
  static const IconData creditCard = Icons.credit_card_outlined;

  /// Cash
  static const IconData cash = Icons.payments_outlined;

  /// Discount
  static const IconData discount = Icons.discount_outlined;

  /// Gift
  static const IconData gift = Icons.card_giftcard_outlined;

  // ========================
  // UTILITY ICONS
  // ========================

  /// External link
  static const IconData externalLink = Icons.open_in_new;

  /// Link
  static const IconData link = Icons.link;

  /// Send
  static const IconData send = Icons.send_outlined;

  /// Inbox
  static const IconData inbox = Icons.inbox_outlined;

  /// Archive
  static const IconData archive = Icons.archive_outlined;

  /// Flag/Report
  static const IconData flag = Icons.flag_outlined;

  /// Bookmark
  static const IconData bookmark = Icons.bookmark_outline;

  /// Bookmark filled
  static const IconData bookmarkFilled = Icons.bookmark;

  // ========================
  // AUTH ICONS
  // ========================

  /// Email
  static const IconData email = Icons.email_outlined;

  /// Password
  static const IconData password = Icons.lock_outline;

  /// Visibility on
  static const IconData visibilityOn = Icons.visibility_outlined;

  /// Visibility off
  static const IconData visibilityOff = Icons.visibility_off_outlined;

  /// Verified
  static const IconData verified = Icons.verified_outlined;

  /// Security
  static const IconData security = Icons.security_outlined;

  // ========================
  // HELPER METHODS
  // ========================

  /// Tạo Icon widget với size và color mặc định
  static Widget icon(
    IconData data, {
    double size = md,
    Color? color,
  }) {
    return Icon(
      data,
      size: size,
      color: color,
    );
  }

  /// Tạo Icon với primary color
  static Widget primaryIcon(
    IconData data, {
    double size = md,
    Color? color,
  }) {
    return Icon(
      data,
      size: size,
      color: color ?? Colors.orange,
    );
  }

  /// Tạo Icon với secondary color
  static Widget secondaryIcon(
    IconData data, {
    double size = md,
    Color? color,
  }) {
    return Icon(
      data,
      size: size,
      color: color ?? Colors.teal,
    );
  }

  /// Tạo Icon với semantic color (success/error/warning/info)
  static Widget semanticIcon(
    IconData data, {
    double size = md,
    required Color color,
  }) {
    return Icon(
      data,
      size: size,
      color: color,
    );
  }
}
