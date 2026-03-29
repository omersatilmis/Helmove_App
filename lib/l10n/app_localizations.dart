import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appExperience.
  ///
  /// In en, this message translates to:
  /// **'App Experience'**
  String get appExperience;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @addPost.
  ///
  /// In en, this message translates to:
  /// **'Add Post'**
  String get addPost;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Error accessing camera'**
  String get cameraError;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to start riding.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters required'**
  String get passwordTooShort;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @joinUs.
  ///
  /// In en, this message translates to:
  /// **'Join Us'**
  String get joinUs;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your riding experience.'**
  String get registerSubtitle;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! You can now login.'**
  String get registrationSuccessful;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration Failed'**
  String get registrationFailed;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters'**
  String get usernameTooShort;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @invalidMail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidMail;

  /// No description provided for @passwordAgain.
  ///
  /// In en, this message translates to:
  /// **'Password Again'**
  String get passwordAgain;

  /// No description provided for @reEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get reEnterPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @incomingCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming Call'**
  String get incomingCall;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice call'**
  String get voiceCall;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @groupRide.
  ///
  /// In en, this message translates to:
  /// **'Group Ride'**
  String get groupRide;

  /// No description provided for @intercom.
  ///
  /// In en, this message translates to:
  /// **'Intercom'**
  String get intercom;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroup;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @ridingStyle.
  ///
  /// In en, this message translates to:
  /// **'Riding Style'**
  String get ridingStyle;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @chill.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get chill;

  /// No description provided for @sport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get sport;

  /// No description provided for @offroad.
  ///
  /// In en, this message translates to:
  /// **'Off-Road'**
  String get offroad;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @maxParticipants.
  ///
  /// In en, this message translates to:
  /// **'Max Participants'**
  String get maxParticipants;

  /// No description provided for @rideDetails.
  ///
  /// In en, this message translates to:
  /// **'Ride Details'**
  String get rideDetails;

  /// No description provided for @startRide.
  ///
  /// In en, this message translates to:
  /// **'Start Ride'**
  String get startRide;

  /// No description provided for @endRide.
  ///
  /// In en, this message translates to:
  /// **'End Ride'**
  String get endRide;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @noParticipants.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get noParticipants;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get bugReport;

  /// No description provided for @featureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get featureRequest;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @tours.
  ///
  /// In en, this message translates to:
  /// **'Tours'**
  String get tours;

  /// No description provided for @notifications_empty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notifications_empty;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @settings_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settings_general;

  /// No description provided for @settings_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settings_privacy;

  /// No description provided for @settings_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settings_security;

  /// No description provided for @settings_help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settings_help;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'v{version} ({stage})'**
  String version(Object stage, Object version);

  /// No description provided for @about_app.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get about_app;

  /// No description provided for @checkUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkUpdates;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get expert;

  /// No description provided for @groupRideTerminated.
  ///
  /// In en, this message translates to:
  /// **'Group ride ended.'**
  String get groupRideTerminated;

  /// No description provided for @rideTerminatedByOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Ride terminated by organizer.'**
  String get rideTerminatedByOrganizer;

  /// No description provided for @leftGroup.
  ///
  /// In en, this message translates to:
  /// **'You left the group.'**
  String get leftGroup;

  /// No description provided for @preparingGroupInfo.
  ///
  /// In en, this message translates to:
  /// **'Preparing group information...'**
  String get preparingGroupInfo;

  /// No description provided for @preparingRideInfo.
  ///
  /// In en, this message translates to:
  /// **'Preparing ride information...'**
  String get preparingRideInfo;

  /// No description provided for @invalidGroupId.
  ///
  /// In en, this message translates to:
  /// **'Invalid Group ID'**
  String get invalidGroupId;

  /// No description provided for @noValidVoiceSessionFound.
  ///
  /// In en, this message translates to:
  /// **'No valid voice session found for invitation.'**
  String get noValidVoiceSessionFound;

  /// No description provided for @voiceSessionUnavailableOnlyRide.
  ///
  /// In en, this message translates to:
  /// **'Voice session unavailable. Only ride details are active.'**
  String get voiceSessionUnavailableOnlyRide;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @liveKitErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'LiveKit Error'**
  String get liveKitErrorPrefix;

  /// No description provided for @activeGroupLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading active group...'**
  String get activeGroupLoading;

  /// No description provided for @noActiveGroup.
  ///
  /// In en, this message translates to:
  /// **'No active group'**
  String get noActiveGroup;

  /// No description provided for @microphone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get microphone;

  /// No description provided for @mutedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Muted by Admin'**
  String get mutedByAdmin;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriend;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Founder (Admin)'**
  String get adminRole;

  /// No description provided for @captainRole.
  ///
  /// In en, this message translates to:
  /// **'Leader (Captain)'**
  String get captainRole;

  /// No description provided for @ultra.
  ///
  /// In en, this message translates to:
  /// **'Ultra'**
  String get ultra;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @lost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get lost;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @groupSettings.
  ///
  /// In en, this message translates to:
  /// **'Group Settings'**
  String get groupSettings;

  /// No description provided for @groupRideAndVoiceSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Group ride and voice session ended'**
  String get groupRideAndVoiceSessionEnded;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get updated;

  /// No description provided for @terminate.
  ///
  /// In en, this message translates to:
  /// **'Terminate'**
  String get terminate;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @everyoneCanJoin.
  ///
  /// In en, this message translates to:
  /// **'Everyone can join'**
  String get everyoneCanJoin;

  /// No description provided for @onlyInvitees.
  ///
  /// In en, this message translates to:
  /// **'Only invitees'**
  String get onlyInvitees;

  /// No description provided for @ridersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} riders'**
  String ridersCount(Object count);

  /// No description provided for @routePrefix.
  ///
  /// In en, this message translates to:
  /// **'Route: {route}'**
  String routePrefix(Object route);

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get notAvailable;

  /// No description provided for @intercomActive.
  ///
  /// In en, this message translates to:
  /// **'Intercom Active'**
  String get intercomActive;

  /// No description provided for @p2pConnected.
  ///
  /// In en, this message translates to:
  /// **'P2P Connected'**
  String get p2pConnected;

  /// No description provided for @p2pConnecting.
  ///
  /// In en, this message translates to:
  /// **'P2P Connecting...'**
  String get p2pConnecting;

  /// No description provided for @sfuConnected.
  ///
  /// In en, this message translates to:
  /// **'SFU Connected'**
  String get sfuConnected;

  /// No description provided for @sfuConnecting.
  ///
  /// In en, this message translates to:
  /// **'SFU Connecting...'**
  String get sfuConnecting;

  /// No description provided for @reconnectingStatus.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnectingStatus;

  /// No description provided for @waitingStatus.
  ///
  /// In en, this message translates to:
  /// **'Waiting...'**
  String get waitingStatus;

  /// No description provided for @connectedRiders.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED RIDERS'**
  String get connectedRiders;

  /// No description provided for @noParticipantsYet.
  ///
  /// In en, this message translates to:
  /// **'No one has joined yet.'**
  String get noParticipantsYet;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

  /// No description provided for @leaveRide.
  ///
  /// In en, this message translates to:
  /// **'Leave Ride'**
  String get leaveRide;

  /// No description provided for @rideSafeWarning.
  ///
  /// In en, this message translates to:
  /// **'Keep your eyes on the road. Ride safe!'**
  String get rideSafeWarning;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @pendingInvitesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 pending invite} other{{count} pending invites}}'**
  String pendingInvitesCount(num count);

  /// No description provided for @voiceSessionCreated.
  ///
  /// In en, this message translates to:
  /// **'Voice session created!'**
  String get voiceSessionCreated;

  /// No description provided for @invitesSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invites sent successfully!'**
  String get invitesSentSuccess;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// No description provided for @groupAndVoiceCreated.
  ///
  /// In en, this message translates to:
  /// **'Group and Voice Session created successfully!'**
  String get groupAndVoiceCreated;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search Users...'**
  String get searchUsers;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @pressSearchToStart.
  ///
  /// In en, this message translates to:
  /// **'Type to start searching'**
  String get pressSearchToStart;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any friends yet'**
  String get noFriendsYet;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get newGroup;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @destinationNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Destination Not Specified'**
  String get destinationNotSpecified;

  /// No description provided for @errorWithPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithPrefix(Object message);

  /// No description provided for @kickUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Kick User'**
  String get kickUserTitle;

  /// No description provided for @kickUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to kick {userName}?'**
  String kickUserConfirmation(String userName);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @sessionInfoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Session info is unavailable.'**
  String get sessionInfoUnavailable;

  /// No description provided for @inviteRejected.
  ///
  /// In en, this message translates to:
  /// **'Invite rejected.'**
  String get inviteRejected;

  /// No description provided for @idNotFound.
  ///
  /// In en, this message translates to:
  /// **'ID not found.'**
  String get idNotFound;

  /// No description provided for @acceptInviteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept invite.'**
  String get acceptInviteError;

  /// No description provided for @inviteFromUser.
  ///
  /// In en, this message translates to:
  /// **'Invite from {userName}'**
  String inviteFromUser(String userName);

  /// No description provided for @alreadyInRideWarning.
  ///
  /// In en, this message translates to:
  /// **'You are already in {sessionTitle}. Leave and join this one?'**
  String alreadyInRideWarning(String sessionTitle);

  /// No description provided for @kick.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get kick;

  /// No description provided for @muteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Mute User'**
  String get muteUserTitle;

  /// No description provided for @muteUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mute {userName}?'**
  String muteUserConfirmation(String userName);

  /// No description provided for @transferLeadershipConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to transfer leadership to {userName}?'**
  String transferLeadershipConfirmation(String userName);

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @promoteToCaptainTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote to Captain'**
  String get promoteToCaptainTitle;

  /// No description provided for @promoteToCaptainConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to give Captain authority to {userName}?'**
  String promoteToCaptainConfirmation(String userName);

  /// No description provided for @demoteToRiderTitle.
  ///
  /// In en, this message translates to:
  /// **'Demote to Rider'**
  String get demoteToRiderTitle;

  /// No description provided for @demoteToRiderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove Captain authority from {userName}?'**
  String demoteToRiderConfirmation(String userName);

  /// No description provided for @terminateGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminate Group'**
  String get terminateGroupTitle;

  /// No description provided for @lastPersonLeaveWarning.
  ///
  /// In en, this message translates to:
  /// **'You are the last person in the group. Leaving will terminate the group and voice session.'**
  String get lastPersonLeaveWarning;

  /// No description provided for @terminateAndExit.
  ///
  /// In en, this message translates to:
  /// **'Terminate and Exit'**
  String get terminateAndExit;

  /// No description provided for @leaveRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Room'**
  String get leaveRoomTitle;

  /// No description provided for @leaveGroupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this ride group?'**
  String get leaveGroupConfirmation;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leavingGroupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you leaving the group?'**
  String get leavingGroupQuestion;

  /// No description provided for @whatToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get whatToDo;

  /// No description provided for @leaveAndTransfer.
  ///
  /// In en, this message translates to:
  /// **'Leave & Transfer'**
  String get leaveAndTransfer;

  /// No description provided for @riders.
  ///
  /// In en, this message translates to:
  /// **'Riders'**
  String get riders;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @jot.
  ///
  /// In en, this message translates to:
  /// **'Jot'**
  String get jot;

  /// No description provided for @searchUserHint.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUserHint;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @searchFriends.
  ///
  /// In en, this message translates to:
  /// **'Search your friends'**
  String get searchFriends;

  /// No description provided for @searchByUsernameOrName.
  ///
  /// In en, this message translates to:
  /// **'Search by username or name'**
  String get searchByUsernameOrName;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @premiumPlans.
  ///
  /// In en, this message translates to:
  /// **'Premium Plans'**
  String get premiumPlans;

  /// No description provided for @communities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communities;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @continueTextShort.
  ///
  /// In en, this message translates to:
  /// **' more...'**
  String get continueTextShort;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Post?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This post will be permanently deleted.'**
  String get deleteConfirmContent;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from Gallery'**
  String get selectFromGallery;

  /// No description provided for @jotShared.
  ///
  /// In en, this message translates to:
  /// **'Jot shared!'**
  String get jotShared;

  /// No description provided for @jotIt.
  ///
  /// In en, this message translates to:
  /// **'Jot it'**
  String get jotIt;

  /// No description provided for @whatToShareToday.
  ///
  /// In en, this message translates to:
  /// **'What would you like to share today?'**
  String get whatToShareToday;

  /// No description provided for @replies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get replies;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noCommentsYet;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @shareYourReply.
  ///
  /// In en, this message translates to:
  /// **'Share your reply...'**
  String get shareYourReply;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get timeNow;

  /// No description provided for @timeMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String timeMinutesShort(int count);

  /// No description provided for @timeHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String timeHoursShort(int count);

  /// No description provided for @subjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Subject Title'**
  String get subjectTitle;

  /// No description provided for @shortTitle.
  ///
  /// In en, this message translates to:
  /// **'Short title...'**
  String get shortTitle;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Message'**
  String get yourMessage;

  /// No description provided for @typeHere.
  ///
  /// In en, this message translates to:
  /// **'Type here...'**
  String get typeHere;

  /// No description provided for @feedbackInfo.
  ///
  /// In en, this message translates to:
  /// **'Your opinions are very valuable to us. Let\'s develop the application together!'**
  String get feedbackInfo;

  /// No description provided for @reportDetailed.
  ///
  /// In en, this message translates to:
  /// **'Report {target}'**
  String reportDetailed(String target);

  /// No description provided for @reportDescription.
  ///
  /// In en, this message translates to:
  /// **'Please specify why you think this content violates our community guidelines.'**
  String get reportDescription;

  /// No description provided for @selectReason.
  ///
  /// In en, this message translates to:
  /// **'Select Reason'**
  String get selectReason;

  /// No description provided for @additionalDescription.
  ///
  /// In en, this message translates to:
  /// **'Additional Description (Optional)'**
  String get additionalDescription;

  /// No description provided for @briefDescription.
  ///
  /// In en, this message translates to:
  /// **'Briefly explain the situation...'**
  String get briefDescription;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @reportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully submitted'**
  String get reportSuccess;

  /// No description provided for @reportError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get reportError;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodDay.
  ///
  /// In en, this message translates to:
  /// **'Good day'**
  String get goodDay;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get goodNight;

  /// No description provided for @rideCarefully.
  ///
  /// In en, this message translates to:
  /// **'Ride carefully'**
  String get rideCarefully;

  /// No description provided for @postsTab.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get postsTab;

  /// No description provided for @jotsTab.
  ///
  /// In en, this message translates to:
  /// **'Jots'**
  String get jotsTab;

  /// No description provided for @motoMessage1.
  ///
  /// In en, this message translates to:
  /// **'Tank full, may your corners be plenty! 🏍️'**
  String get motoMessage1;

  /// No description provided for @motoMessage2.
  ///
  /// In en, this message translates to:
  /// **'We don\'t even go to the grocery store without equipment, right? 🤨'**
  String get motoMessage2;

  /// No description provided for @motoMessage3.
  ///
  /// In en, this message translates to:
  /// **'Do you know how much gas is now, boss? ⛽'**
  String get motoMessage3;

  /// No description provided for @motoMessage4.
  ///
  /// In en, this message translates to:
  /// **'Visor clean, may your path be clear. ✨'**
  String get motoMessage4;

  /// No description provided for @motoMessage5.
  ///
  /// In en, this message translates to:
  /// **'May no stone touch your wheel, no tear touch your eye. ✨'**
  String get motoMessage5;

  /// No description provided for @motoMessage6.
  ///
  /// In en, this message translates to:
  /// **'I saw the bike dusty, wash it sometime if you want... 🤔'**
  String get motoMessage6;

  /// No description provided for @motoMessage7.
  ///
  /// In en, this message translates to:
  /// **'Motor is a bit dusty... means good memories have accumulated 😏'**
  String get motoMessage7;

  /// No description provided for @motoMessage8.
  ///
  /// In en, this message translates to:
  /// **'Equipment ok? Let\'s get home safe before looking cool 😎'**
  String get motoMessage8;

  /// No description provided for @motoMessage9.
  ///
  /// In en, this message translates to:
  /// **'May your wheel press flat, no matter where the route is 😌'**
  String get motoMessage9;

  /// No description provided for @motoMessage10.
  ///
  /// In en, this message translates to:
  /// **'Visor clean, your head might be confused, don\'t worry, we are here ✨'**
  String get motoMessage10;

  /// No description provided for @motoMessage11.
  ///
  /// In en, this message translates to:
  /// **'Value your equipment, you are precious to us 😎'**
  String get motoMessage11;

  /// No description provided for @motoMessage12.
  ///
  /// In en, this message translates to:
  /// **'May the sound of the engine be higher than your mood 🎵🏍️'**
  String get motoMessage12;

  /// No description provided for @motoMessage13.
  ///
  /// In en, this message translates to:
  /// **'Is that a gear? I thought you were playing piano with your toe. 🎹'**
  String get motoMessage13;

  /// No description provided for @motoMessage14.
  ///
  /// In en, this message translates to:
  /// **'May your wheel touch the ground but your mind not stay in the air. ✌️'**
  String get motoMessage14;

  /// No description provided for @motoMessage15.
  ///
  /// In en, this message translates to:
  /// **'With that exhaust sound, you can only announce iftar time to the neighborhood. 🔊'**
  String get motoMessage15;

  /// No description provided for @motoMessage16.
  ///
  /// In en, this message translates to:
  /// **'If you can\'t lean the bike in the corner, tell us, we\'ll open the side stand. 📉'**
  String get motoMessage16;

  /// No description provided for @motoMessage17.
  ///
  /// In en, this message translates to:
  /// **'Hanging the helmet on the arm doesn\'t provide protection, \'Pro\' brother. 🦾'**
  String get motoMessage17;

  /// No description provided for @motoMessage18.
  ///
  /// In en, this message translates to:
  /// **'Equipment saves lives, don\'t forget to wear your helmet!'**
  String get motoMessage18;

  /// No description provided for @motoMessage19.
  ///
  /// In en, this message translates to:
  /// **'Asphalt is crying, slow down a bit! 💨'**
  String get motoMessage19;

  /// No description provided for @motoMessage20.
  ///
  /// In en, this message translates to:
  /// **'Which route are you dreaming of again? 🤔'**
  String get motoMessage20;

  /// No description provided for @motoMessage21.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to give the biker wave!'**
  String get motoMessage21;

  /// No description provided for @motoMessage22.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t you take the bike out because it was raining? Are you sugar? 🍭'**
  String get motoMessage22;

  /// No description provided for @preparingSessionInfo.
  ///
  /// In en, this message translates to:
  /// **'Preparing session info...'**
  String get preparingSessionInfo;

  /// No description provided for @noValidSession.
  ///
  /// In en, this message translates to:
  /// **'No valid session'**
  String get noValidSession;

  /// No description provided for @invalidSession.
  ///
  /// In en, this message translates to:
  /// **'Invalid session'**
  String get invalidSession;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @nameSurnamePhoto.
  ///
  /// In en, this message translates to:
  /// **'Name, Surname, Photo'**
  String get nameSurnamePhoto;

  /// No description provided for @myGarage.
  ///
  /// In en, this message translates to:
  /// **'My Garage'**
  String get myGarage;

  /// No description provided for @addManageBikes.
  ///
  /// In en, this message translates to:
  /// **'Add and manage your bikes'**
  String get addManageBikes;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @audioQuality.
  ///
  /// In en, this message translates to:
  /// **'Audio Quality'**
  String get audioQuality;

  /// No description provided for @noiseCancellation.
  ///
  /// In en, this message translates to:
  /// **'Noise Cancellation'**
  String get noiseCancellation;

  /// No description provided for @voiceNavigation.
  ///
  /// In en, this message translates to:
  /// **'Voice Navigation'**
  String get voiceNavigation;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'WiFi Only'**
  String get wifiOnly;

  /// No description provided for @distanceUnit.
  ///
  /// In en, this message translates to:
  /// **'Distance Unit'**
  String get distanceUnit;

  /// No description provided for @tempUnit.
  ///
  /// In en, this message translates to:
  /// **'Temperature Unit'**
  String get tempUnit;

  /// No description provided for @mapType.
  ///
  /// In en, this message translates to:
  /// **'Map Type'**
  String get mapType;

  /// No description provided for @trafficEnabled.
  ///
  /// In en, this message translates to:
  /// **'Traffic Enabled'**
  String get trafficEnabled;

  /// No description provided for @musicMode.
  ///
  /// In en, this message translates to:
  /// **'Music Mode'**
  String get musicMode;

  /// No description provided for @lowQuality.
  ///
  /// In en, this message translates to:
  /// **'Low (16 kbps) - Data Saver'**
  String get lowQuality;

  /// No description provided for @mediumQuality.
  ///
  /// In en, this message translates to:
  /// **'Balanced (32 kbps) - Default'**
  String get mediumQuality;

  /// No description provided for @highQuality.
  ///
  /// In en, this message translates to:
  /// **'High (48 kbps) - WiFi Recommended'**
  String get highQuality;

  /// No description provided for @ultraQuality.
  ///
  /// In en, this message translates to:
  /// **'Ultra (64 kbps) - Highest Quality'**
  String get ultraQuality;

  /// No description provided for @privacyLocation.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Location'**
  String get privacyLocation;

  /// No description provided for @ghostMode.
  ///
  /// In en, this message translates to:
  /// **'Ghost Mode'**
  String get ghostMode;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @onlyFriends.
  ///
  /// In en, this message translates to:
  /// **'Only Friends'**
  String get onlyFriends;

  /// No description provided for @privateNobody.
  ///
  /// In en, this message translates to:
  /// **'Private (Nobody can see)'**
  String get privateNobody;

  /// No description provided for @messageRequests.
  ///
  /// In en, this message translates to:
  /// **'Message Requests'**
  String get messageRequests;

  /// No description provided for @onlyFollowed.
  ///
  /// In en, this message translates to:
  /// **'Only People I Follow'**
  String get onlyFollowed;

  /// No description provided for @tagging.
  ///
  /// In en, this message translates to:
  /// **'Tagging'**
  String get tagging;

  /// No description provided for @blockedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Blocked Accounts'**
  String get blockedAccounts;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get copyright;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @measurementUnits.
  ///
  /// In en, this message translates to:
  /// **'Measurement Units'**
  String get measurementUnits;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @kilometer.
  ///
  /// In en, this message translates to:
  /// **'Kilometer (km)'**
  String get kilometer;

  /// No description provided for @mile.
  ///
  /// In en, this message translates to:
  /// **'Mile (mi)'**
  String get mile;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @celsius.
  ///
  /// In en, this message translates to:
  /// **'Celsius (°C)'**
  String get celsius;

  /// No description provided for @fahrenheit.
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit (°F)'**
  String get fahrenheit;

  /// No description provided for @mapSettings.
  ///
  /// In en, this message translates to:
  /// **'Map Settings'**
  String get mapSettings;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @satellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get satellite;

  /// No description provided for @terrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get terrain;

  /// No description provided for @hybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get hybrid;

  /// No description provided for @trafficInfo.
  ///
  /// In en, this message translates to:
  /// **'Traffic Information'**
  String get trafficInfo;

  /// No description provided for @showTrafficDensity.
  ///
  /// In en, this message translates to:
  /// **'Show density status'**
  String get showTrafficDensity;

  /// No description provided for @validationTitle.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get validationTitle;

  /// No description provided for @validationMessage.
  ///
  /// In en, this message translates to:
  /// **'Message is required'**
  String get validationMessage;

  /// No description provided for @savedSessions.
  ///
  /// In en, this message translates to:
  /// **'Saved Sessions'**
  String get savedSessions;

  /// No description provided for @createRideGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Ride Group'**
  String get createRideGroup;

  /// No description provided for @leaveGroupWarning.
  ///
  /// In en, this message translates to:
  /// **'Please leave your current ride before creating a new group.'**
  String get leaveGroupWarning;

  /// No description provided for @yourActiveGroup.
  ///
  /// In en, this message translates to:
  /// **'Your Active Group'**
  String get yourActiveGroup;

  /// No description provided for @nearbyGroups.
  ///
  /// In en, this message translates to:
  /// **'Nearby Groups'**
  String get nearbyGroups;

  /// No description provided for @defaultGroupName.
  ///
  /// In en, this message translates to:
  /// **'Weekend Ride'**
  String get defaultGroupName;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Group Name (e.g. Weekend Tour)'**
  String get groupNameHint;

  /// No description provided for @pPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get pPublic;

  /// No description provided for @pPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get pPrivate;

  /// No description provided for @destinationOptional.
  ///
  /// In en, this message translates to:
  /// **'Destination (Optional)'**
  String get destinationOptional;

  /// No description provided for @destinationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sapanca Lake'**
  String get destinationHint;

  /// No description provided for @tour.
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get tour;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a short description about the ride...'**
  String get descriptionHint;

  /// No description provided for @inviteUsers.
  ///
  /// In en, this message translates to:
  /// **'Invite Users'**
  String get inviteUsers;

  /// No description provided for @inviteRiders.
  ///
  /// In en, this message translates to:
  /// **'Invite Riders'**
  String get inviteRiders;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @transferLeadership.
  ///
  /// In en, this message translates to:
  /// **'Transfer Leadership'**
  String get transferLeadership;

  /// No description provided for @makeCaptain.
  ///
  /// In en, this message translates to:
  /// **'Make Captain'**
  String get makeCaptain;

  /// No description provided for @demote.
  ///
  /// In en, this message translates to:
  /// **'Demote'**
  String get demote;

  /// No description provided for @noActiveRoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new room or wait for an invite'**
  String get noActiveRoomSubtitle;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @kickFromSession.
  ///
  /// In en, this message translates to:
  /// **'Kick from Session'**
  String get kickFromSession;

  /// No description provided for @timeDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String timeDaysShort(int count);

  /// No description provided for @jotFeedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No jots yet. Be the first to post!'**
  String get jotFeedEmpty;

  /// No description provided for @feedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feed'**
  String get feedLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @imageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image failed to load'**
  String get imageLoadFailed;

  /// No description provided for @postShared.
  ///
  /// In en, this message translates to:
  /// **'Post shared!'**
  String get postShared;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @whatIsOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get whatIsOnYourMind;

  /// No description provided for @pleaseWriteSomething.
  ///
  /// In en, this message translates to:
  /// **'Please write something'**
  String get pleaseWriteSomething;

  /// No description provided for @addMedia.
  ///
  /// In en, this message translates to:
  /// **'Add Media'**
  String get addMedia;

  /// No description provided for @imageUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Image URL (https://...)'**
  String get imageUrlHint;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get noPostsYet;

  /// No description provided for @reportReceived.
  ///
  /// In en, this message translates to:
  /// **'Report received.'**
  String get reportReceived;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @noDiscoveryContent.
  ///
  /// In en, this message translates to:
  /// **'No content to discover yet.'**
  String get noDiscoveryContent;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @followingStatus.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingStatus;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorLabel(String message);

  /// No description provided for @friendship.
  ///
  /// In en, this message translates to:
  /// **'Friendship'**
  String get friendship;

  /// No description provided for @myFriends.
  ///
  /// In en, this message translates to:
  /// **'My Friends'**
  String get myFriends;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @sentRequests.
  ///
  /// In en, this message translates to:
  /// **'Sent Requests'**
  String get sentRequests;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @selectPerson.
  ///
  /// In en, this message translates to:
  /// **'Select Person'**
  String get selectPerson;

  /// No description provided for @messageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @chattingWith.
  ///
  /// In en, this message translates to:
  /// **'Chatting with {username}'**
  String chattingWith(String username);

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests.'**
  String get noPendingRequests;

  /// No description provided for @requestedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Requested on {day}/{month}'**
  String requestedOnDate(int day, int month);

  /// No description provided for @notFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'Not friends yet.'**
  String get notFriendsYet;

  /// No description provided for @left_session.
  ///
  /// In en, this message translates to:
  /// **'You left the session'**
  String get left_session;

  /// No description provided for @already_in_active_ride_error.
  ///
  /// In en, this message translates to:
  /// **'You are already in an active ride. To create a new group, leave the current ride first.'**
  String get already_in_active_ride_error;

  /// No description provided for @permissions_not_granted_error.
  ///
  /// In en, this message translates to:
  /// **'Necessary permissions for the session were not granted.'**
  String get permissions_not_granted_error;

  /// No description provided for @group_ride.
  ///
  /// In en, this message translates to:
  /// **'Group Ride'**
  String get group_ride;

  /// No description provided for @error_creating_group.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while creating the group: {error}'**
  String error_creating_group(String error);

  /// No description provided for @could_not_join_room.
  ///
  /// In en, this message translates to:
  /// **'Could not join the room.'**
  String get could_not_join_room;

  /// No description provided for @successfully_joined_room.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined the room'**
  String get successfully_joined_room;

  /// No description provided for @leaving_session.
  ///
  /// In en, this message translates to:
  /// **'Leaving session...'**
  String get leaving_session;

  /// No description provided for @successfully_left_session.
  ///
  /// In en, this message translates to:
  /// **'Successfully left the session'**
  String get successfully_left_session;

  /// No description provided for @session_terminated_error.
  ///
  /// In en, this message translates to:
  /// **'Session terminated (Error: {error})'**
  String session_terminated_error(String error);

  /// No description provided for @session_terminated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Session terminated successfully'**
  String get session_terminated_successfully;

  /// No description provided for @already_in_ride_accept_error.
  ///
  /// In en, this message translates to:
  /// **'You are already in an active ride. To accept the invitation, leave the current ride first.'**
  String get already_in_ride_accept_error;

  /// No description provided for @group_ride_terminated.
  ///
  /// In en, this message translates to:
  /// **'Group ride terminated. Session closed.'**
  String get group_ride_terminated;

  /// No description provided for @profile_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile unavailable'**
  String get profile_unavailable;

  /// No description provided for @friendRequestDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Hi, let\'s be friends!'**
  String get friendRequestDefaultMessage;

  /// No description provided for @noSentRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No sent requests yet.'**
  String get noSentRequestsYet;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @unnamedUser.
  ///
  /// In en, this message translates to:
  /// **'Unnamed User'**
  String get unnamedUser;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get requestSent;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get howCanWeHelp;

  /// No description provided for @searchYourProblem.
  ///
  /// In en, this message translates to:
  /// **'Search your problem...'**
  String get searchYourProblem;

  /// No description provided for @faqQuestion1.
  ///
  /// In en, this message translates to:
  /// **'How do I join a group ride?'**
  String get faqQuestion1;

  /// No description provided for @faqAnswer1.
  ///
  /// In en, this message translates to:
  /// **'You can join by entering the room code shared by your friend or by accepting an invitation.'**
  String get faqAnswer1;

  /// No description provided for @faqQuestion2.
  ///
  /// In en, this message translates to:
  /// **'What is Ghost Mode?'**
  String get faqQuestion2;

  /// No description provided for @faqAnswer2.
  ///
  /// In en, this message translates to:
  /// **'When Ghost Mode is on, your location isn\'t visible on the map, but you can still use the app.'**
  String get faqAnswer2;

  /// No description provided for @faqQuestion3.
  ///
  /// In en, this message translates to:
  /// **'How to prevent audio lag?'**
  String get faqQuestion3;

  /// No description provided for @faqAnswer3.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection. We use optimal architectures to minimize lag, but low signal can affect it.'**
  String get faqAnswer3;

  /// No description provided for @solutionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Solution not found?'**
  String get solutionNotFound;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact our support team.'**
  String get contactSupport;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Info (Optional)'**
  String get additionalInfo;

  /// No description provided for @explainSituation.
  ///
  /// In en, this message translates to:
  /// **'Briefly explain the situation...'**
  String get explainSituation;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send Report'**
  String get sendReport;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @addContent.
  ///
  /// In en, this message translates to:
  /// **'Add Content'**
  String get addContent;

  /// No description provided for @createNewContent.
  ///
  /// In en, this message translates to:
  /// **'Create New Content'**
  String get createNewContent;

  /// No description provided for @postType.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postType;

  /// No description provided for @sharePhotoOrVideo.
  ///
  /// In en, this message translates to:
  /// **'Share photo or video'**
  String get sharePhotoOrVideo;

  /// No description provided for @jotType.
  ///
  /// In en, this message translates to:
  /// **'Jot'**
  String get jotType;

  /// No description provided for @shareShortTextOrThought.
  ///
  /// In en, this message translates to:
  /// **'Share a short text or thought'**
  String get shareShortTextOrThought;

  /// No description provided for @youAreFriends.
  ///
  /// In en, this message translates to:
  /// **'You are friends'**
  String get youAreFriends;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @feedbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent successfully!'**
  String get feedbackSuccess;

  /// No description provided for @feedbackError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String feedbackError(String message);

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @writeTitle.
  ///
  /// In en, this message translates to:
  /// **'Please write a title.'**
  String get writeTitle;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Please write a message.'**
  String get writeMessage;

  /// No description provided for @writeTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Short title...'**
  String get writeTitleHint;

  /// No description provided for @writeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type here...'**
  String get writeMessageHint;

  /// No description provided for @audioMedia.
  ///
  /// In en, this message translates to:
  /// **'Audio & Media'**
  String get audioMedia;

  /// No description provided for @backgroundMusic.
  ///
  /// In en, this message translates to:
  /// **'Background Music'**
  String get backgroundMusic;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @dimWhileTalking.
  ///
  /// In en, this message translates to:
  /// **'Dim while talking'**
  String get dimWhileTalking;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @musicAlwaysDimmed.
  ///
  /// In en, this message translates to:
  /// **'Music always dimmed'**
  String get musicAlwaysDimmed;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @noChangeInMusic.
  ///
  /// In en, this message translates to:
  /// **'No change in music'**
  String get noChangeInMusic;

  /// No description provided for @reduceWindNoise.
  ///
  /// In en, this message translates to:
  /// **'Reduce wind noise'**
  String get reduceWindNoise;

  /// No description provided for @voiceRouteInstructions.
  ///
  /// In en, this message translates to:
  /// **'Voice route instructions'**
  String get voiceRouteInstructions;

  /// No description provided for @nobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get nobody;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Group Privacy'**
  String get groupPrivacy;

  /// No description provided for @maxRiders.
  ///
  /// In en, this message translates to:
  /// **'Max Riders'**
  String get maxRiders;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addCommentHint;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @mapSelectStop.
  ///
  /// In en, this message translates to:
  /// **'Select stop from map'**
  String get mapSelectStop;

  /// No description provided for @mapSearchStops.
  ///
  /// In en, this message translates to:
  /// **'Search stops...'**
  String get mapSearchStops;

  /// No description provided for @mapDirection.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get mapDirection;

  /// No description provided for @mapNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get mapNearby;

  /// No description provided for @mapThisArea.
  ///
  /// In en, this message translates to:
  /// **'This area'**
  String get mapThisArea;

  /// No description provided for @mapAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get mapAddress;

  /// No description provided for @mapPOI.
  ///
  /// In en, this message translates to:
  /// **'POI'**
  String get mapPOI;

  /// No description provided for @mapCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get mapCity;

  /// No description provided for @mapStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get mapStart;

  /// No description provided for @mapEnd.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get mapEnd;

  /// No description provided for @poiFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get poiFuel;

  /// No description provided for @poiRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get poiRest;

  /// No description provided for @poiService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get poiService;

  /// No description provided for @poiEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get poiEquipment;

  /// No description provided for @allNotificationsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read.'**
  String get allNotificationsRead;

  /// No description provided for @leaveActiveRide.
  ///
  /// In en, this message translates to:
  /// **'Leave Active Ride'**
  String get leaveActiveRide;

  /// No description provided for @leaveAndJoin.
  ///
  /// In en, this message translates to:
  /// **'Leave and Join'**
  String get leaveAndJoin;

  /// No description provided for @leaveAndPass.
  ///
  /// In en, this message translates to:
  /// **'Leave and Pass'**
  String get leaveAndPass;

  /// No description provided for @sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session info not found.'**
  String get sessionNotFound;

  /// No description provided for @invitationRejected.
  ///
  /// In en, this message translates to:
  /// **'Invitation rejected.'**
  String get invitationRejected;

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// No description provided for @searchChatHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats...'**
  String get searchChatHint;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @startChatWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Start chatting with your friends!'**
  String get startChatWithFriends;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get userBlocked;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @startChattingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start chatting with your friends!'**
  String get startChattingPrompt;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @older.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get older;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @interactionsWillShowUp.
  ///
  /// In en, this message translates to:
  /// **'Interactions will show up here'**
  String get interactionsWillShowUp;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @map_location_services_disabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get map_location_services_disabled;

  /// No description provided for @map_location_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get map_location_permission_denied;

  /// No description provided for @map_location_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while getting location.'**
  String get map_location_error;

  /// No description provided for @map_layers_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Layers coming soon.'**
  String get map_layers_coming_soon;

  /// No description provided for @map_eta_label.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get map_eta_label;

  /// No description provided for @map_add_stop.
  ///
  /// In en, this message translates to:
  /// **'Add Stop'**
  String get map_add_stop;

  /// No description provided for @map_send_to_group.
  ///
  /// In en, this message translates to:
  /// **'Send to Group'**
  String get map_send_to_group;

  /// No description provided for @map_start_navigation.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get map_start_navigation;

  /// No description provided for @map_no_steps_found.
  ///
  /// In en, this message translates to:
  /// **'No step information found.'**
  String get map_no_steps_found;

  /// No description provided for @map_step_number.
  ///
  /// In en, this message translates to:
  /// **'Step {index}'**
  String map_step_number(Object index);

  /// No description provided for @map_filter_nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get map_filter_nearby;

  /// No description provided for @map_filter_this_area.
  ///
  /// In en, this message translates to:
  /// **'This area'**
  String get map_filter_this_area;

  /// No description provided for @map_filter_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get map_filter_address;

  /// No description provided for @map_filter_poi.
  ///
  /// In en, this message translates to:
  /// **'POI'**
  String get map_filter_poi;

  /// No description provided for @map_filter_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get map_filter_city;

  /// No description provided for @map_point_destination.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get map_point_destination;

  /// No description provided for @map_point_origin.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get map_point_origin;

  /// No description provided for @map_get_directions.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get map_get_directions;

  /// No description provided for @map_select_stop_hint.
  ///
  /// In en, this message translates to:
  /// **'Select stop from map'**
  String get map_select_stop_hint;

  /// No description provided for @map_add_stop_title.
  ///
  /// In en, this message translates to:
  /// **'Add Stop'**
  String get map_add_stop_title;

  /// No description provided for @map_select_on_map.
  ///
  /// In en, this message translates to:
  /// **'Select on Map'**
  String get map_select_on_map;

  /// No description provided for @map_search_stop_hint.
  ///
  /// In en, this message translates to:
  /// **'Search stop...'**
  String get map_search_stop_hint;

  /// No description provided for @map_poi_gas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get map_poi_gas;

  /// No description provided for @map_poi_rest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get map_poi_rest;

  /// No description provided for @map_poi_service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get map_poi_service;

  /// No description provided for @map_poi_equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get map_poi_equipment;

  /// No description provided for @map_on_route_pois.
  ///
  /// In en, this message translates to:
  /// **'On-Route Points'**
  String get map_on_route_pois;

  /// No description provided for @map_business_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get map_business_open;

  /// No description provided for @map_business_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get map_business_closed;

  /// No description provided for @map_search_from.
  ///
  /// In en, this message translates to:
  /// **'From?'**
  String get map_search_from;

  /// No description provided for @map_search_to.
  ///
  /// In en, this message translates to:
  /// **'To?'**
  String get map_search_to;

  /// No description provided for @map_stop_selected.
  ///
  /// In en, this message translates to:
  /// **'Stop Selected'**
  String get map_stop_selected;

  /// No description provided for @map_select_stop.
  ///
  /// In en, this message translates to:
  /// **'Select Stop'**
  String get map_select_stop;

  /// No description provided for @map_businesses.
  ///
  /// In en, this message translates to:
  /// **'Businesses'**
  String get map_businesses;

  /// No description provided for @map_go_back.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get map_go_back;

  /// No description provided for @map_business_label.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get map_business_label;

  /// No description provided for @map_route_stops_title.
  ///
  /// In en, this message translates to:
  /// **'Route Stops'**
  String get map_route_stops_title;

  /// No description provided for @map_route_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh Route'**
  String get map_route_refresh;

  /// No description provided for @map_route_refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing Route...'**
  String get map_route_refreshing;

  /// No description provided for @map_route_steps_title.
  ///
  /// In en, this message translates to:
  /// **'Route Steps'**
  String get map_route_steps_title;

  /// No description provided for @map_warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get map_warning;

  /// No description provided for @map_traffic_severe.
  ///
  /// In en, this message translates to:
  /// **'Severe traffic'**
  String get map_traffic_severe;

  /// No description provided for @map_traffic_heavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy traffic'**
  String get map_traffic_heavy;

  /// No description provided for @map_traffic_moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate traffic'**
  String get map_traffic_moderate;

  /// No description provided for @map_traffic_low.
  ///
  /// In en, this message translates to:
  /// **'Light traffic'**
  String get map_traffic_low;

  /// No description provided for @map_traffic_clear.
  ///
  /// In en, this message translates to:
  /// **'Traffic is clear'**
  String get map_traffic_clear;

  /// No description provided for @map_alternative_routes_title.
  ///
  /// In en, this message translates to:
  /// **'Alternative Routes'**
  String get map_alternative_routes_title;

  /// No description provided for @map_route_count.
  ///
  /// In en, this message translates to:
  /// **'{count} routes'**
  String map_route_count(int count);

  /// No description provided for @map_route_badge_short_fast.
  ///
  /// In en, this message translates to:
  /// **'Short & Fast'**
  String get map_route_badge_short_fast;

  /// No description provided for @map_route_badge_shortest.
  ///
  /// In en, this message translates to:
  /// **'Shortest'**
  String get map_route_badge_shortest;

  /// No description provided for @map_route_badge_fastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get map_route_badge_fastest;

  /// No description provided for @map_route_badge_alternative.
  ///
  /// In en, this message translates to:
  /// **'Alternative'**
  String get map_route_badge_alternative;

  /// No description provided for @delete_comment_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Comment?'**
  String get delete_comment_title;

  /// No description provided for @add_comment_hint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get add_comment_hint;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @time_day_short.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String time_day_short(int count);

  /// No description provided for @time_hour_short.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String time_hour_short(int count);

  /// No description provided for @time_minute_short.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String time_minute_short(int count);

  /// No description provided for @clear_chat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clear_chat;

  /// No description provided for @block_user.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block_user;

  /// No description provided for @user_blocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get user_blocked;

  /// No description provided for @profile_not_found.
  ///
  /// In en, this message translates to:
  /// **'This profile is unavailable.'**
  String get profile_not_found;

  /// No description provided for @share_profile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get share_profile;

  /// No description provided for @share_profile_text.
  ///
  /// In en, this message translates to:
  /// **'Check out my profile on MotoComm! {url}'**
  String share_profile_text(String url);

  /// No description provided for @user_followed.
  ///
  /// In en, this message translates to:
  /// **'User followed'**
  String get user_followed;

  /// No description provided for @unfollowed.
  ///
  /// In en, this message translates to:
  /// **'Unfollowed'**
  String get unfollowed;

  /// No description provided for @personal_info.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personal_info;

  /// No description provided for @update_location_now.
  ///
  /// In en, this message translates to:
  /// **'Update Location Now'**
  String get update_location_now;

  /// No description provided for @change_profile_photo.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get change_profile_photo;

  /// No description provided for @profile_updated_success.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profile_updated_success;

  /// No description provided for @no_internet_connection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get no_internet_connection;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @map_access.
  ///
  /// In en, this message translates to:
  /// **'Map Access'**
  String get map_access;

  /// No description provided for @group_ride_participation.
  ///
  /// In en, this message translates to:
  /// **'Join Group Rides'**
  String get group_ride_participation;

  /// No description provided for @ad_supported_experience.
  ///
  /// In en, this message translates to:
  /// **'Ad-supported Experience'**
  String get ad_supported_experience;

  /// No description provided for @ad_free_experience.
  ///
  /// In en, this message translates to:
  /// **'Ad-free Experience'**
  String get ad_free_experience;

  /// No description provided for @unlimited_route_recording.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Route Recording'**
  String get unlimited_route_recording;

  /// No description provided for @unlimited_communication.
  ///
  /// In en, this message translates to:
  /// **'Unlimited & Free Communication'**
  String get unlimited_communication;

  /// No description provided for @rider_radar.
  ///
  /// In en, this message translates to:
  /// **'Rider Radar (Nearby Tracking)'**
  String get rider_radar;

  /// No description provided for @road_captain_tools.
  ///
  /// In en, this message translates to:
  /// **'Road Captain Tools'**
  String get road_captain_tools;

  /// No description provided for @select_plan.
  ///
  /// In en, this message translates to:
  /// **'Select Your Plan'**
  String get select_plan;

  /// No description provided for @restore_purchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restore_purchases;

  /// No description provided for @subscription_restored_success.
  ///
  /// In en, this message translates to:
  /// **'Subscription restored successfully! ✅'**
  String get subscription_restored_success;

  /// No description provided for @no_active_subscription_found.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found to restore.'**
  String get no_active_subscription_found;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @invitation_sent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get invitation_sent;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @send_invitation.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get send_invitation;

  /// No description provided for @invite_sent.
  ///
  /// In en, this message translates to:
  /// **'Invitation Sent'**
  String get invite_sent;

  /// No description provided for @sos_sent.
  ///
  /// In en, this message translates to:
  /// **'SOS Sent!'**
  String get sos_sent;

  /// No description provided for @image_upload_error.
  ///
  /// In en, this message translates to:
  /// **'Error uploading image'**
  String get image_upload_error;

  /// No description provided for @delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Delete operation failed'**
  String get delete_failed;

  /// No description provided for @like_failed.
  ///
  /// In en, this message translates to:
  /// **'Like operation failed'**
  String get like_failed;

  /// No description provided for @call_ended.
  ///
  /// In en, this message translates to:
  /// **'You ended the call.'**
  String get call_ended;

  /// No description provided for @call_ended_by_other.
  ///
  /// In en, this message translates to:
  /// **'The call was ended by the other party.'**
  String get call_ended_by_other;

  /// No description provided for @communities_preparing.
  ///
  /// In en, this message translates to:
  /// **'Communities Page is being prepared...'**
  String get communities_preparing;

  /// No description provided for @enter_min_characters.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least {count} characters.'**
  String enter_min_characters(int count);

  /// No description provided for @post_shared.
  ///
  /// In en, this message translates to:
  /// **'Post shared!'**
  String get post_shared;

  /// No description provided for @new_post.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get new_post;

  /// No description provided for @write_description.
  ///
  /// In en, this message translates to:
  /// **'Write a description...'**
  String get write_description;

  /// No description provided for @already_in_ride.
  ///
  /// In en, this message translates to:
  /// **'You are already in an active ride...'**
  String get already_in_ride;

  /// No description provided for @permissions_not_granted.
  ///
  /// In en, this message translates to:
  /// **'Required permissions for the session were not granted.'**
  String get permissions_not_granted;

  /// No description provided for @group_creation_failed.
  ///
  /// In en, this message translates to:
  /// **'Group could not be created.'**
  String get group_creation_failed;

  /// No description provided for @group_creation_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while creating the group: {error}'**
  String group_creation_error(String error);

  /// No description provided for @joined_room_success.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined the room'**
  String get joined_room_success;

  /// No description provided for @left_session_success.
  ///
  /// In en, this message translates to:
  /// **'Successfully left the session'**
  String get left_session_success;

  /// No description provided for @session_terminated_success.
  ///
  /// In en, this message translates to:
  /// **'Session terminated successfully'**
  String get session_terminated_success;

  /// No description provided for @settingsOperationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get settingsOperationSuccess;

  /// No description provided for @settingsOperationError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get settingsOperationError;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get accountSecurity;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your current password'**
  String get changePasswordSubtitle;

  /// No description provided for @releaseStageBeta.
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get releaseStageBeta;

  /// No description provided for @aboutAppHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'What Helmove Offers?'**
  String get aboutAppHighlightsTitle;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Helmove is an elite riding and communication ecosystem that blends motorcycle culture with advanced technology. Our platform was born from a vision to remove the technical limitations of traditional intercom systems, bringing seamless P2P voice architecture, sophisticated group management, and real-time location discipline together into a flawless experience. It is designed to make every moment on the road safer, more synchronized, and more premium.'**
  String get aboutAppDescription;

  /// No description provided for @developerTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer Team'**
  String get developerTeamTitle;

  /// No description provided for @developerTeamMessage.
  ///
  /// In en, this message translates to:
  /// **'Built with love by motorcycle enthusiasts, for motorcycle enthusiasts.'**
  String get developerTeamMessage;

  /// No description provided for @connectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connectionSettings;

  /// No description provided for @wifiOnlyDownloads.
  ///
  /// In en, this message translates to:
  /// **'Download over Wi-Fi only'**
  String get wifiOnlyDownloads;

  /// No description provided for @mapUpdatesFor.
  ///
  /// In en, this message translates to:
  /// **'For map updates'**
  String get mapUpdatesFor;

  /// No description provided for @bluetoothDevices.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Devices'**
  String get bluetoothDevices;

  /// No description provided for @userInfoNotFound.
  ///
  /// In en, this message translates to:
  /// **'User info not found.'**
  String get userInfoNotFound;

  /// No description provided for @passwordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Password could not be updated.'**
  String get passwordUpdateFailed;

  /// No description provided for @passwordUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated successfully. For your security, all sessions were closed. Please log in again.'**
  String get passwordUpdatedMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @passwordStrengthHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password to keep your account secure.'**
  String get passwordStrengthHint;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @currentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get currentPasswordHint;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get currentPasswordRequired;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @updatePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordButton;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked'**
  String get userUnblocked;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked accounts.'**
  String get noBlockedUsers;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockUser;

  /// No description provided for @noBikesYet.
  ///
  /// In en, this message translates to:
  /// **'No motorcycles added yet.'**
  String get noBikesYet;

  /// No description provided for @addBike.
  ///
  /// In en, this message translates to:
  /// **'Add Motorcycle'**
  String get addBike;

  /// No description provided for @bottomNavDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get bottomNavDiscover;

  /// No description provided for @bottomNavCommunication.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get bottomNavCommunication;

  /// No description provided for @shareSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to share?'**
  String get shareSheetTitle;

  /// No description provided for @shareSheetCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get shareSheetCameraTitle;

  /// No description provided for @shareSheetCameraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture a quick photo or video'**
  String get shareSheetCameraSubtitle;

  /// No description provided for @shareSheetGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get shareSheetGalleryTitle;

  /// No description provided for @shareSheetGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose content from your library'**
  String get shareSheetGallerySubtitle;

  /// No description provided for @shareSheetJotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Jots'**
  String get shareSheetJotsTitle;

  /// No description provided for @shareSheetJotsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quickly jot down your thoughts'**
  String get shareSheetJotsSubtitle;

  /// No description provided for @communicationPermissionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone, Bluetooth, Location, and Call permissions are required for the full voice chat experience.'**
  String get communicationPermissionsRequired;

  /// No description provided for @feedbackCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get feedbackCategoryGeneral;

  /// No description provided for @feedbackCategoryBugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get feedbackCategoryBugReport;

  /// No description provided for @feedbackCategoryFeatureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get feedbackCategoryFeatureRequest;

  /// No description provided for @feedbackCategoryUiImprovement.
  ///
  /// In en, this message translates to:
  /// **'UI Improvement'**
  String get feedbackCategoryUiImprovement;

  /// No description provided for @feedbackCategoryPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get feedbackCategoryPerformance;

  /// No description provided for @feedbackCategorySecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get feedbackCategorySecurity;

  /// No description provided for @feedbackCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackCategoryOther;

  /// No description provided for @feedbackStatusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get feedbackStatusNew;

  /// No description provided for @feedbackStatusRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get feedbackStatusRead;

  /// No description provided for @feedbackStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get feedbackStatusInProgress;

  /// No description provided for @feedbackStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get feedbackStatusCompleted;

  /// No description provided for @feedbackStatusWontFix.
  ///
  /// In en, this message translates to:
  /// **'Won\'t Fix'**
  String get feedbackStatusWontFix;

  /// No description provided for @copyrightTagline.
  ///
  /// In en, this message translates to:
  /// **'Advanced Communication and Social Rider Ecosystem'**
  String get copyrightTagline;

  /// No description provided for @copyrightHeader.
  ///
  /// In en, this message translates to:
  /// **'© {year} Helmove'**
  String copyrightHeader(int year);

  /// No description provided for @copyrightAllRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved.'**
  String get copyrightAllRightsReserved;

  /// No description provided for @copyrightLegalNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal Notice'**
  String get copyrightLegalNoticeTitle;

  /// No description provided for @copyrightLegalNoticeContent.
  ///
  /// In en, this message translates to:
  /// **'All texts, graphics, logos, button icons, visuals, and software within the Helmove app are the property of Helmove and are protected by international copyright laws.'**
  String get copyrightLegalNoticeContent;

  /// No description provided for @copyrightReverseEngineeringTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse Engineering Prohibited'**
  String get copyrightReverseEngineeringTitle;

  /// No description provided for @copyrightReverseEngineeringContent.
  ///
  /// In en, this message translates to:
  /// **'Reverse engineering, decompiling, disassembling, or otherwise attempting to derive the source code or algorithms of this software is strictly prohibited. Such attempts will be considered a violation of intellectual property rights.'**
  String get copyrightReverseEngineeringContent;

  /// No description provided for @copyrightUsageRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage Rights'**
  String get copyrightUsageRightsTitle;

  /// No description provided for @copyrightUsageRightsContent.
  ///
  /// In en, this message translates to:
  /// **'This app and its content are for personal use only. Copying, reproducing, republishing, uploading, transmitting, or distributing content without Helmove\'s prior written permission is prohibited.'**
  String get copyrightUsageRightsContent;

  /// No description provided for @copyrightTrademarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Trademarks'**
  String get copyrightTrademarksTitle;

  /// No description provided for @copyrightTrademarksContent.
  ///
  /// In en, this message translates to:
  /// **'The Helmove logo and service marks are registered trademarks of Helmove. All other trademarks belong to their respective owners.'**
  String get copyrightTrademarksContent;

  /// No description provided for @copyrightOpenSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get copyrightOpenSourceTitle;

  /// No description provided for @copyrightOpenSourceDescription.
  ///
  /// In en, this message translates to:
  /// **'Helmove is developed using great open-source software and original architectural planning.'**
  String get copyrightOpenSourceDescription;

  /// No description provided for @privacyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated: March 6, 2026'**
  String get privacyLastUpdated;

  /// No description provided for @privacySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Introduction'**
  String get privacySection1Title;

  /// No description provided for @privacySection1Content.
  ///
  /// In en, this message translates to:
  /// **'At Helmove, we value your privacy. This privacy policy explains how your data is collected, used, and protected when you use our app.'**
  String get privacySection1Content;

  /// No description provided for @privacySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Data We Collect'**
  String get privacySection2Title;

  /// No description provided for @privacySection2Content.
  ///
  /// In en, this message translates to:
  /// **'When you use our app, we may collect the following data:\\n\\n- Profile Information: Your name, email address, and profile photo.\\n- Location Data: To share your location with other riders during group rides (when Ghost Mode is off).\\n- Media: Posts, \'jots\', and photos you share.\\n- Device Information: Technical data required for app performance and error tracking.'**
  String get privacySection2Content;

  /// No description provided for @privacySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. How We Use Data'**
  String get privacySection3Title;

  /// No description provided for @privacySection3Content.
  ///
  /// In en, this message translates to:
  /// **'We use the data we collect for the following purposes:\\n\\n- Provide communication features (voice sessions, messaging).\\n- Improve ride safety and group coordination.\\n- Personalize and enhance the app experience.\\n- Resolve technical issues and ensure security.'**
  String get privacySection3Content;

  /// No description provided for @privacySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Data Sharing'**
  String get privacySection4Title;

  /// No description provided for @privacySection4Content.
  ///
  /// In en, this message translates to:
  /// **'Your data is not shared with third parties for advertising purposes except where required by law. For voice communication, infrastructure providers like LiveKit may process only the necessary technical identifiers.'**
  String get privacySection4Content;

  /// No description provided for @privacySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Your Rights'**
  String get privacySection5Title;

  /// No description provided for @privacySection5Content.
  ///
  /// In en, this message translates to:
  /// **'You can edit your profile, access your data, or request deletion of your account and personal data at any time. You can also disable location sharing at any time from privacy settings.'**
  String get privacySection5Content;

  /// No description provided for @privacySection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Contact'**
  String get privacySection6Title;

  /// No description provided for @privacySection6Content.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about our privacy policy, you can reach us at support@Helmove.app.'**
  String get privacySection6Content;

  /// No description provided for @privacyWebInfoText.
  ///
  /// In en, this message translates to:
  /// **'For more information, please visit our website.'**
  String get privacyWebInfoText;

  /// No description provided for @privacyWebLinkText.
  ///
  /// In en, this message translates to:
  /// **'Helmove Privacy Policy'**
  String get privacyWebLinkText;

  /// No description provided for @privacyBottomBannerText.
  ///
  /// In en, this message translates to:
  /// **'Helmove Safe Riding Platform'**
  String get privacyBottomBannerText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
