// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Agriገበያ';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get amharic => 'Amharic (አማርኛ)';

  @override
  String get oromo => 'Afaan Oromo';

  @override
  String get somali => 'Somali (Soomaali)';

  @override
  String get tigrinya => 'Tigrinya (ትግርኛ)';

  @override
  String get next => 'Next';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get phoneLogin => 'Phone Login';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get enterVerificationCode =>
      'Enter the 6-digit code sent to your phone';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get verify => 'Verify';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get invalidOtp => 'Invalid OTP code. Please try again.';

  @override
  String get setupProfile => 'Setup Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get enterName => 'Enter your name';

  @override
  String get location => 'Location';

  @override
  String get region => 'Region';

  @override
  String get zone => 'Zone';

  @override
  String get woreda => 'Woreda';

  @override
  String get profilePhoto => 'Profile Photo (Optional)';

  @override
  String get telegramUsername => 'Telegram Username (Optional)';

  @override
  String get whatsappNumber => 'WhatsApp Number (Optional)';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get verifiedPhone => 'Verified Phone';

  @override
  String get createListing => 'Create Listing';

  @override
  String get editListing => 'Edit Listing';

  @override
  String get productCategory => 'Product Category';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get productName => 'Product Name';

  @override
  String get customProductName => 'Custom Product Name (if not in list)';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get price => 'Price (ETB)';

  @override
  String get negotiable => 'Negotiable';

  @override
  String get description => 'Description (Optional)';

  @override
  String get addPhotos => 'Add Photos (Max 5)';

  @override
  String get contactPreferences => 'Contact Preferences';

  @override
  String get enableTelegram => 'Enable Telegram Contact';

  @override
  String get enableWhatsapp => 'Enable WhatsApp Contact';

  @override
  String get enableInAppChat => 'Enable In-App Chat';

  @override
  String get publishListing => 'Publish Listing';

  @override
  String get fillRequiredFields => 'Please fill all required fields';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get noListingsFound => 'No listings found';

  @override
  String get filters => 'Filters';

  @override
  String get minPrice => 'Min Price';

  @override
  String get maxPrice => 'Max Price';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get newest => 'Newest';

  @override
  String get nearest => 'Nearest';

  @override
  String get all => 'All';

  @override
  String get memberSince => 'Member since';

  @override
  String get contactSeller => 'Contact Seller';

  @override
  String get paySeller => 'Pay Seller';

  @override
  String get reportListing => 'Report Listing';

  @override
  String get reportProfile => 'Report Profile';

  @override
  String get listingDetails => 'Listing Details';

  @override
  String get sold => 'Sold';

  @override
  String get active => 'Active';

  @override
  String get chats => 'Chats';

  @override
  String get noChatsYet => 'No conversations yet';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get confirmPayment => 'Confirm Payment';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get amountToPay => 'Amount to Pay';

  @override
  String payWith(String method) {
    return 'Pay with $method';
  }

  @override
  String get paymentPending => 'Payment Pending';

  @override
  String get paymentSuccessful => 'Payment Successful';

  @override
  String get paymentFailed => 'Payment Failed';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get receipt => 'Payment Receipt';

  @override
  String paymentNotification(String amount) {
    return 'A payment of $amount ETB has been initiated';
  }

  @override
  String get myAccount => 'My Account';

  @override
  String get myListings => 'My Listings';

  @override
  String get markAsSold => 'Mark as Sold';

  @override
  String get deleteListing => 'Delete Listing';

  @override
  String get deleteConfirm => 'Are you sure you want to delete this listing?';

  @override
  String get signOut => 'Sign Out';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get termsText =>
      'By using Agriገበያ, you agree that we are not a party to any transaction. Payments are made directly between buyer and seller using Chapa (Telebirr, CBE Birr, e-Birr). We make no guarantee of product quality or delivery.';

  @override
  String get agreeTerms => 'I agree to the Terms of Use';

  @override
  String get report => 'Report';

  @override
  String get reportReason => 'Select Reason for Report';

  @override
  String get scamFraud => 'Scam or Fraud';

  @override
  String get abusiveContent => 'Abusive or Inappropriate Content';

  @override
  String get incorrectPrice => 'Incorrect Price or Details';

  @override
  String get other => 'Other';

  @override
  String get reportSuccess =>
      'Report submitted. Thank you for keeping our marketplace safe.';
}
