import 'package:flutter_test/flutter_test.dart';
import 'package:fyp/models/user.dart';
import 'dart:math' as math;

void
main() {
  group(
    'Advertisement Data Validation Tests',
    () {
      test(
        'should validate advertisement URL format',
        () {
          // Valid URLs
          expect(
            _isValidImageUrl(
              'https://example.com/image.jpg',
            ),
            isTrue,
          );
          expect(
            _isValidImageUrl(
              'https://firebasestorage.googleapis.com/image.png',
            ),
            isTrue,
          );
          expect(
            _isValidImageUrl(
              'https://cdn.example.com/photo.jpeg',
            ),
            isTrue,
          );
          expect(
            _isValidImageUrl(
              'https://images.unsplash.com/photo.jpg',
            ),
            isTrue,
          );

          // Invalid URLs
          expect(
            _isValidImageUrl(
              'not-a-url',
            ),
            isFalse,
          );
          expect(
            _isValidImageUrl(
              'ftp://example.com/image.jpg',
            ),
            isFalse,
          );
          expect(
            _isValidImageUrl(
              'http://example.com/image.jpg',
            ),
            isFalse,
          ); // Should be HTTPS
          expect(
            _isValidImageUrl(
              '',
            ),
            isFalse,
          );
          expect(
            _isValidImageUrl(
              'https://example.com/image.txt',
            ),
            isFalse,
          ); // Wrong extension
        },
      );

      test(
        'should validate advertisement title length',
        () {
          // Valid lengths
          expect(
            _isValidTitleLength(
              'Short Title',
            ),
            isTrue,
          );
          expect(
            _isValidTitleLength(
              'A' *
                  50,
            ),
            isTrue,
          );
          expect(
            _isValidTitleLength(
              'Special Offer! 🎉',
            ),
            isTrue,
          );
          expect(
            _isValidTitleLength(
              'Limited Time Deal - 50% Off',
            ),
            isTrue,
          );

          // Invalid lengths
          expect(
            _isValidTitleLength(
              '',
            ),
            isFalse,
          );
          expect(
            _isValidTitleLength(
              'A' *
                  200,
            ),
            isFalse,
          );
          expect(
            _isValidTitleLength(
              'A' *
                  101,
            ),
            isFalse,
          );
        },
      );

      test(
        'should validate advertisement description',
        () {
          // Valid descriptions
          expect(
            _isValidDescription(
              'Valid description',
            ),
            isTrue,
          );
          expect(
            _isValidDescription(
              'A' *
                  500,
            ),
            isTrue,
          );
          expect(
            _isValidDescription(
              'Get 50% off on all items! Limited time offer. 🎉',
            ),
            isTrue,
          );
          expect(
            _isValidDescription(
              'Buy one get one free on selected items. Terms and conditions apply.',
            ),
            isTrue,
          );

          // Invalid descriptions
          expect(
            _isValidDescription(
              '',
            ),
            isFalse,
          );
          expect(
            _isValidDescription(
              'A' *
                  1000,
            ),
            isFalse,
          );
          expect(
            _isValidDescription(
              'A' *
                  501,
            ),
            isFalse,
          );
        },
      );

      test(
        'should validate business advertisement data integrity',
        () {
          // Valid business with advertisement
          final validBusiness = User(
            username:
                'test_business',
            email:
                'test@example.com',
            password:
                'password',
            type:
                UserType.business,
            businessName:
                'Test Business',
            advertisementTitle:
                'Special Offer',
            advertisementDescription:
                '50% off everything',
            advertisementImageUrl:
                'https://example.com/image.jpg',
          );

          expect(
            _isValidBusinessAdvertisement(
              validBusiness,
            ),
            isTrue,
          );

          // Invalid business - missing required fields
          final invalidBusiness = User(
            username:
                'test_business',
            email:
                'test@example.com',
            password:
                'password',
            type:
                UserType.business,
            businessName:
                '', // Empty business name
            advertisementTitle:
                'Special Offer',
          );

          expect(
            _isValidBusinessAdvertisement(
              invalidBusiness,
            ),
            isFalse,
          );
        },
      );

      test(
        'should validate advertisement content quality',
        () {
          // High quality advertisements
          expect(
            _isHighQualityAdvertisement(
              'Special Offer - 50% Off!',
              'Get amazing deals on all items',
            ),
            isTrue,
          );
          expect(
            _isHighQualityAdvertisement(
              'Happy Hours',
              'Buy 1 Get 1 Free from 2-5 PM',
            ),
            isTrue,
          );
          expect(
            _isHighQualityAdvertisement(
              'Weekend Sale',
              'All items 30% off this weekend only',
            ),
            isTrue,
          );

          // Low quality advertisements
          expect(
            _isHighQualityAdvertisement(
              '',
              'Some description',
            ),
            isFalse,
          ); // Empty title
          expect(
            _isHighQualityAdvertisement(
              'Ad',
              'Short',
            ),
            isFalse,
          ); // Too short
          expect(
            _isHighQualityAdvertisement(
              'A' *
                  100,
              'A' *
                  10,
            ),
            isFalse,
          ); // Title too long, description too short
        },
      );

      test(
        'should validate advertisement image requirements',
        () {
          // Valid image URLs
          expect(
            _isValidAdvertisementImage(
              'https://example.com/ad-image.jpg',
            ),
            isTrue,
          );
          expect(
            _isValidAdvertisementImage(
              'https://firebasestorage.googleapis.com/ads/photo.png',
            ),
            isTrue,
          );
          expect(
            _isValidAdvertisementImage(
              'https://cdn.example.com/promotions/banner.jpeg',
            ),
            isTrue,
          );

          // Invalid image URLs
          expect(
            _isValidAdvertisementImage(
              '',
            ),
            isFalse,
          );
          expect(
            _isValidAdvertisementImage(
              'https://example.com/document.pdf',
            ),
            isFalse,
          );
          expect(
            _isValidAdvertisementImage(
              'https://example.com/video.mp4',
            ),
            isFalse,
          );
          expect(
            _isValidAdvertisementImage(
              'not-a-url',
            ),
            isFalse,
          );
        },
      );

      test(
        'should validate advertisement business type',
        () {
          // Valid business type
          final businessUser = User(
            username:
                'business',
            email:
                'business@example.com',
            password:
                'password',
            type:
                UserType.business,
            advertisementTitle:
                'Special Offer',
          );

          expect(
            _canHaveAdvertisement(
              businessUser,
            ),
            isTrue,
          );

          // Invalid business type
          final normalUser = User(
            username:
                'user',
            email:
                'user@example.com',
            password:
                'password',
            type:
                UserType.user,
            advertisementTitle:
                'Special Offer',
          );

          expect(
            _canHaveAdvertisement(
              normalUser,
            ),
            isFalse,
          );
        },
      );

      test(
        'should validate advertisement uniqueness',
        () {
          final business1 = User(
            username:
                'business1',
            email:
                'business1@example.com',
            password:
                'password',
            type:
                UserType.business,
            advertisementTitle:
                'Special Offer',
          );

          final business2 = User(
            username:
                'business2',
            email:
                'business2@example.com',
            password:
                'password',
            type:
                UserType.business,
            advertisementTitle:
                'Special Offer', // Same title
          );

          final business3 = User(
            username:
                'business3',
            email:
                'business3@example.com',
            password:
                'password',
            type:
                UserType.business,
            advertisementTitle:
                'Different Offer',
          );

          expect(
            _isAdvertisementUnique(
              business1,
              [
                business2,
                business3,
              ],
            ),
            isFalse,
          );
          expect(
            _isAdvertisementUnique(
              business3,
              [
                business1,
                business2,
              ],
            ),
            isTrue,
          );
        },
      );

      test(
        'should validate advertisement expiration logic',
        () {
          // Test advertisement expiration validation
          expect(
            _isAdvertisementActive(
              DateTime.now(),
            ),
            isTrue,
          );
          expect(
            _isAdvertisementActive(
              DateTime.now().add(
                const Duration(
                  days:
                      30,
                ),
              ),
            ),
            isTrue,
          );
          expect(
            _isAdvertisementActive(
              DateTime.now().subtract(
                const Duration(
                  days:
                      1,
                ),
              ),
            ),
            isFalse,
          );
        },
      );

      test(
        'should validate advertisement targeting',
        () {
          // Test location-based targeting
          final nearbyBusiness = User(
            username:
                'nearby_business',
            email:
                'nearby@example.com',
            password:
                'password',
            type:
                UserType.business,
            businessName:
                'Nearby Business',
            advertisementTitle:
                'Local Special',
          );

          final farBusiness = User(
            username:
                'far_business',
            email:
                'far@example.com',
            password:
                'password',
            type:
                UserType.business,
            businessName:
                'Far Business',
            advertisementTitle:
                'Far Special',
          );

          // Mock location data
          const userLocation = {
            'lat':
                40.7128,
            'lng':
                -74.0060,
          }; // New York
          const nearbyLocation = {
            'lat':
                40.7129,
            'lng':
                -74.0061,
          }; // Very close
          const farLocation = {
            'lat':
                34.0522,
            'lng':
                -118.2437,
          }; // Los Angeles

          expect(
            _isAdvertisementRelevant(
              nearbyBusiness,
              userLocation,
              nearbyLocation,
            ),
            isTrue,
          );
          expect(
            _isAdvertisementRelevant(
              farBusiness,
              userLocation,
              farLocation,
            ),
            isFalse,
          );
        },
      );
    },
  );
}

// Validation helper functions
bool
_isValidImageUrl(
  String url,
) {
  if (url.isEmpty) return false;

  // Must be HTTPS
  if (!url.startsWith(
    'https://',
  ))
    return false;

  // Must have valid image extension
  final validExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];
  return validExtensions.any(
    (
      ext,
    ) => url.toLowerCase().endsWith(
      ext,
    ),
  );
}

bool
_isValidTitleLength(
  String title,
) {
  return title.isNotEmpty &&
      title.length <=
          100;
}

bool
_isValidDescription(
  String description,
) {
  return description.isNotEmpty &&
      description.length <=
          500;
}

bool
_isValidBusinessAdvertisement(
  User business,
) {
  return business.type ==
          UserType.business &&
      business.businessName !=
          null &&
      business.businessName!.isNotEmpty &&
      (business.advertisementTitle !=
              null ||
          business.advertisementDescription !=
              null ||
          business.advertisementImageUrl !=
              null);
}

bool
_isHighQualityAdvertisement(
  String title,
  String description,
) {
  return title.isNotEmpty &&
      title.length >=
          3 &&
      title.length <=
          100 &&
      description.isNotEmpty &&
      description.length >=
          10 &&
      description.length <=
          500;
}

bool
_isValidAdvertisementImage(
  String imageUrl,
) {
  if (imageUrl.isEmpty) return false;

  // Must be HTTPS
  if (!imageUrl.startsWith(
    'https://',
  ))
    return false;

  // Must be an image file
  final validExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];
  return validExtensions.any(
    (
      ext,
    ) => imageUrl.toLowerCase().endsWith(
      ext,
    ),
  );
}

bool
_canHaveAdvertisement(
  User user,
) {
  return user.type ==
      UserType.business;
}

bool
_isAdvertisementUnique(
  User business,
  List<
    User
  >
  existingBusinesses,
) {
  final currentTitle =
      business.advertisementTitle?.toLowerCase();
  if (currentTitle ==
      null)
    return true;

  return !existingBusinesses.any(
    (
      existing,
    ) =>
        existing.username !=
            business.username &&
        existing.advertisementTitle?.toLowerCase() ==
            currentTitle,
  );
}

bool
_isAdvertisementActive(
  DateTime expirationDate,
) {
  return DateTime.now().isBefore(
    expirationDate,
  );
}

bool
_isAdvertisementRelevant(
  User business,
  Map<
    String,
    double
  >
  userLocation,
  Map<
    String,
    double
  >
  businessLocation,
) {
  // Calculate distance between user and business
  final distance = _calculateDistance(
    userLocation['lat']!,
    userLocation['lng']!,
    businessLocation['lat']!,
    businessLocation['lng']!,
  );

  // Consider advertisement relevant if within 10km
  return distance <=
      10.0;
}

double
_calculateDistance(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  // Simple distance calculation (Haversine formula would be more accurate)
  const double earthRadius =
      6371; // km

  final dLat = _degreesToRadians(
    lat2 -
        lat1,
  );
  final dLng = _degreesToRadians(
    lng2 -
        lng1,
  );

  final a =
      math.sin(
            dLat /
                2,
          ) *
          math.sin(
            dLat /
                2,
          ) +
      (math.sin(
            lat1,
          ) *
          math.sin(
            lat2,
          ) *
          math.sin(
            dLng /
                2,
          ) *
          math.sin(
            dLng /
                2,
          ));
  final c =
      2 *
      math.atan(
        math.sqrt(
              a,
            ) /
            math.sqrt(
              1 -
                  a,
            ),
      );

  return earthRadius *
      c;
}

double
_degreesToRadians(
  double degrees,
) {
  return degrees *
      (3.14159265359 /
          180);
}
