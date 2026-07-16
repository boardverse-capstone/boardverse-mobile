import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Icon System - Sử dụng Lucide Icons thay vì Material Icons
/// Đảm bảo consistent design với stroke width 2px và rounded corners
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
  static const IconData explore = LucideIcons.compass;

  /// Booking/Schedule tab
  static const IconData booking = LucideIcons.calendarClock;

  /// Tournament/Ranking tab
  static const IconData tournament = LucideIcons.trophy;

  /// Profile tab
  static const IconData profile = LucideIcons.userCircle;

  /// Home
  static const IconData home = LucideIcons.home;

  /// Back arrow
  static const IconData back = LucideIcons.arrowLeft;

  /// Forward arrow
  static const IconData forward = LucideIcons.arrowRight;

  /// Menu
  static const IconData menu = LucideIcons.menu;

  /// Close
  static const IconData close = LucideIcons.x;

  /// More options
  static const IconData moreVertical = LucideIcons.moreVertical;

  /// More options horizontal
  static const IconData moreHorizontal = LucideIcons.moreHorizontal;

  // ========================
  // GAME ICONS
  // ========================

  /// Board game
  static const IconData boardGame = LucideIcons.gamepad2;

  /// Card game
  static const IconData cardGame = LucideIcons.layers;

  /// Strategy game
  static const IconData strategy = LucideIcons.target;

  /// Party game
  static const IconData party = LucideIcons.partyPopper;

  /// Dice
  static const IconData dice = LucideIcons.dices;

  /// Chess
  static const IconData chess = LucideIcons.shield;

  /// Puzzle
  static const IconData puzzle = LucideIcons.puzzle;

  /// Game controller
  static const IconData controller = LucideIcons.gamepad;

  // ========================
  // ACTION ICONS
  // ========================

  /// Search
  static const IconData search = LucideIcons.search;

  /// Filter
  static const IconData filter = LucideIcons.slidersHorizontal;

  /// Sort
  static const IconData sort = LucideIcons.arrowUpDown;

  /// Add
  static const IconData add = LucideIcons.plusCircle;

  /// Add (simple)
  static const IconData addSimple = LucideIcons.plus;

  /// Edit
  static const IconData edit = LucideIcons.pencil;

  /// Delete
  static const IconData delete = LucideIcons.trash2;

  /// Share
  static const IconData share = LucideIcons.share2;

  /// Copy
  static const IconData copy = LucideIcons.copy;

  /// Download
  static const IconData download = LucideIcons.download;

  /// Upload
  static const IconData upload = LucideIcons.upload;

  /// Refresh
  static const IconData refresh = LucideIcons.refreshCcw;

  /// Reload
  static const IconData reload = LucideIcons.rotateCcw;

  // ========================
  // STATUS ICONS
  // ========================

  /// Available/Success
  static const IconData available = LucideIcons.checkCircle;

  /// Check (simple)
  static const IconData check = LucideIcons.check;

  /// Busy/Unavailable
  static const IconData busy = LucideIcons.xCircle;

  /// Pending/Waiting
  static const IconData pending = LucideIcons.clock;

  /// Error
  static const IconData error = LucideIcons.alertCircle;

  /// Warning
  static const IconData warning = LucideIcons.alertTriangle;

  /// Info
  static const IconData info = LucideIcons.info;

  /// Help
  static const IconData help = LucideIcons.helpCircle;

  // ========================
  // USER & SOCIAL ICONS
  // ========================

  /// Users/Group
  static const IconData users = LucideIcons.users;

  /// User (single)
  static const IconData user = LucideIcons.user;

  /// User add
  static const IconData userAdd = LucideIcons.userPlus;

  /// User remove
  static const IconData userRemove = LucideIcons.userMinus;

  /// User check
  static const IconData userCheck = LucideIcons.userCheck;

  /// Rating/Star
  static const IconData rating = LucideIcons.star;

  /// Star filled
  static const IconData starFilled = LucideIcons.star;

  /// Star empty
  static const IconData starEmpty = LucideIcons.star;

  /// Heart (like/favorite)
  static const IconData heart = LucideIcons.heart;

  /// Heart filled
  static const IconData heartFilled = LucideIcons.heart;

  /// Karma/Points
  static const IconData karma = LucideIcons.flame;

  /// ELO rating
  static const IconData elo = LucideIcons.zap;

  /// Chat/Message
  static const IconData chat = LucideIcons.messageCircle;

  // ========================
  // CAFE & LOCATION ICONS
  // ========================

  /// Cafe/Store
  static const IconData cafe = LucideIcons.store;

  /// Location/Map pin
  static const IconData location = LucideIcons.mapPin;

  /// Phone
  static const IconData phone = LucideIcons.phone;

  /// Phone call
  static const IconData phoneCall = LucideIcons.phoneCall;

  /// Schedule/Calendar
  static const IconData schedule = LucideIcons.calendar;

  /// Clock/Time
  static const IconData clock = LucideIcons.clock;

  /// Globe
  static const IconData globe = LucideIcons.globe;

  /// Directions
  static const IconData directions = LucideIcons.navigation;

  // ========================
  // BOOKING ICONS
  // ========================

  /// Book/Reserve
  static const IconData book = LucideIcons.calendarCheck;

  /// Cancel booking
  static const IconData cancelBooking = LucideIcons.x;

  /// Confirm booking
  static const IconData confirmBooking = LucideIcons.check;

  /// Booking history
  static const IconData bookingHistory = LucideIcons.history;

  /// Pending booking
  static const IconData pendingBooking = LucideIcons.hourglass;

  // ========================
  // MEDIA ICONS
  // ========================

  /// Camera
  static const IconData camera = LucideIcons.camera;

  /// Camera off
  static const IconData cameraOff = LucideIcons.cameraOff;

  /// Image/Gallery
  static const IconData image = LucideIcons.image;

  /// QR code
  static const IconData qrCode = LucideIcons.qrCode;

  /// QR code scanner
  static const IconData qrScan = LucideIcons.scanLine;

  /// Video
  static const IconData video = LucideIcons.video;

  /// Video off
  static const IconData videoOff = LucideIcons.videoOff;

  // ========================
  // SETTINGS ICONS
  // ========================

  /// Settings
  static const IconData settings = LucideIcons.settings;

  /// Bell/Notification
  static const IconData bell = LucideIcons.bell;

  /// Bell off
  static const IconData bellOff = LucideIcons.bellOff;

  /// Lock
  static const IconData lock = LucideIcons.lock;

  /// Unlock
  static const IconData unlock = LucideIcons.unlock;

  /// Eye (show)
  static const IconData eye = LucideIcons.eye;

  /// Eye off (hide)
  static const IconData eyeOff = LucideIcons.eyeOff;

  /// Log out
  static const IconData logout = LucideIcons.logOut;

  /// Login
  static const IconData login = LucideIcons.logIn;

  /// Moon/Night mode
  static const IconData moon = LucideIcons.moon;

  /// Sun/Day mode
  static const IconData sun = LucideIcons.sun;

  /// Language
  static const IconData language = LucideIcons.languages;

  // ========================
  // MONEY & PAYMENT ICONS
  // ========================

  /// Money
  static const IconData money = LucideIcons.wallet;

  /// Credit card
  static const IconData creditCard = LucideIcons.creditCard;

  /// Cash
  static const IconData cash = LucideIcons.banknote;

  /// Discount
  static const IconData discount = LucideIcons.percent;

  /// Gift
  static const IconData gift = LucideIcons.gift;

  // ========================
  // UTILITY ICONS
  // ========================

  /// External link
  static const IconData externalLink = LucideIcons.externalLink;

  /// Link
  static const IconData link = LucideIcons.link;

  /// Send
  static const IconData send = LucideIcons.send;

  /// Inbox
  static const IconData inbox = LucideIcons.inbox;

  /// Archive
  static const IconData archive = LucideIcons.archive;

  /// Flag/Report
  static const IconData flag = LucideIcons.flag;

  /// Bookmark
  static const IconData bookmark = LucideIcons.bookmark;

  /// Bookmark filled
  static const IconData bookmarkFilled = LucideIcons.bookmark;

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
  }) {
    return Icon(
      data,
      size: size,
      color: Colors.orange,
    );
  }

  /// Tạo Icon với secondary color
  static Widget secondaryIcon(
    IconData data, {
    double size = md,
  }) {
    return Icon(
      data,
      size: size,
      color: Colors.teal,
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
