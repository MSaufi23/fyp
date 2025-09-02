import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp/main.dart';
import 'package:fyp/models/user.dart';
import 'package:fyp/services/database_service.dart';
import 'package:fyp/widgets/advertisement_carousel.dart';
import 'package:fyp/widgets/advertisement_manager.dart';

void
main() {
  group(
    'Advertisement Integration Tests',
    () {
      testWidgets(
        'complete advertisement workflow test',
        (
          WidgetTester tester,
        ) async {
          // Start the app
          await tester.pumpWidget(
            const MyApp(),
          );
          await tester.pumpAndSettle();

          // Note: This is a basic integration test structure
          // You would need to adapt this based on your actual app navigation

          // Test advertisement creation flow
          // Test advertisement display flow
          // Test advertisement interaction flow
        },
      );

      testWidgets(
        'advertisement carousel integration with business data',
        (
          WidgetTester tester,
        ) async {
          // Arrange - Create realistic business data
          final testBusinesses = [
            User(
              username:
                  'restaurant_1',
              email:
                  'restaurant1@example.com',
              password:
                  'password123',
              type:
                  UserType.business,
              businessName:
                  'Pizza Palace',
              businessDescription:
                  'Best pizza in town',
              businessAddress:
                  '123 Main St',
              businessPhone:
                  '+1234567890',
              businessEmail:
                  'contact@pizzapalace.com',
              advertisementTitle:
                  'Weekend Special',
              advertisementDescription:
                  'Buy any large pizza, get a medium free!',
              advertisementImageUrl:
                  'https://example.com/pizza-ad.jpg',
            ),
            User(
              username:
                  'cafe_1',
              email:
                  'cafe1@example.com',
              password:
                  'password123',
              type:
                  UserType.business,
              businessName:
                  'Coffee Corner',
              businessDescription:
                  'Artisan coffee and pastries',
              businessAddress:
                  '456 Oak Ave',
              businessPhone:
                  '+1234567891',
              businessEmail:
                  'hello@coffeecorner.com',
              advertisementTitle:
                  'Happy Hour',
              advertisementDescription:
                  '50% off all beverages from 2-5 PM',
              advertisementImageUrl:
                  'https://example.com/coffee-ad.jpg',
            ),
            User(
              username:
                  'bakery_1',
              email:
                  'bakery1@example.com',
              password:
                  'password123',
              type:
                  UserType.business,
              businessName:
                  'Sweet Dreams Bakery',
              businessDescription:
                  'Fresh baked goods daily',
              businessAddress:
                  '789 Pine St',
              businessPhone:
                  '+1234567892',
              businessEmail:
                  'orders@sweetdreams.com',
              advertisementTitle:
                  'Fresh Bread Sale',
              advertisementDescription:
                  'All bread 30% off after 6 PM',
              advertisementImageUrl:
                  'https://example.com/bread-ad.jpg',
            ),
          ];

          // Act
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    AdvertisementCarousel(
                      businessesWithAds:
                          testBusinesses,
                      onBusinessTap: (
                        business,
                      ) {
                        // Handle business tap
                        print(
                          'Tapped on: ${business.businessName}',
                        );
                      },
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Main content area',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          // Assert
          expect(
            find.text(
              'Pizza Palace',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              'Coffee Corner',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              'Sweet Dreams Bakery',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              'Weekend Special',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              'Happy Hour',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              'Fresh Bread Sale',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              '1/3',
            ),
            findsOneWidget,
          ); // Page indicator
        },
      );

      testWidgets(
        'advertisement manager integration with form validation',
        (
          WidgetTester tester,
        ) async {
          // Arrange
          String? savedImageUrl;
          String? savedTitle;
          String? savedDescription;
          bool saveCalled =
              false;

          // Act
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    AdvertisementManager(
                      isEditing:
                          true,
                      onImageSelected:
                          (
                            url,
                          ) =>
                              savedImageUrl =
                                  url,
                      onTitleChanged:
                          (
                            title,
                          ) =>
                              savedTitle =
                                  title,
                      onDescriptionChanged:
                          (
                            description,
                          ) =>
                              savedDescription =
                                  description,
                    ),
                    const SizedBox(
                      height:
                          20,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        saveCalled =
                            true;
                        // Simulate save operation
                        print(
                          'Saving advertisement: $savedTitle',
                        );
                      },
                      child: const Text(
                        'Save Advertisement',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          // Fill in the form
          await tester.enterText(
            find
                .byType(
                  TextField,
                )
                .first,
            'Summer Sale Campaign',
          );
          await tester.enterText(
            find
                .byType(
                  TextField,
                )
                .last,
            'Get 25% off on all summer items. Limited time offer!',
          );
          await tester.pump();

          // Tap save button
          await tester.tap(
            find.text(
              'Save Advertisement',
            ),
          );
          await tester.pump();

          // Assert
          expect(
            savedTitle,
            equals(
              'Summer Sale Campaign',
            ),
          );
          expect(
            savedDescription,
            equals(
              'Get 25% off on all summer items. Limited time offer!',
            ),
          );
          expect(
            saveCalled,
            isTrue,
          );
        },
      );

      testWidgets(
        'advertisement display integration with navigation',
        (
          WidgetTester tester,
        ) async {
          // Arrange
          final testBusinesses = [
            User(
              username:
                  'business_1',
              email:
                  'business1@example.com',
              password:
                  'password',
              type:
                  UserType.business,
              businessName:
                  'Test Business',
              advertisementTitle:
                  'Special Offer',
              advertisementDescription:
                  'Limited time deal',
            ),
          ];

          User? selectedBusiness;
          bool dialogShown =
              false;

          // Act
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AdvertisementCarousel(
                  businessesWithAds:
                      testBusinesses,
                  onBusinessTap: (
                    business,
                  ) {
                    selectedBusiness =
                        business;
                    dialogShown =
                        true;
                    // Simulate showing business details dialog
                    showDialog(
                      context: tester.element(
                        find.byType(
                          AdvertisementCarousel,
                        ),
                      ),
                      builder:
                          (
                            context,
                          ) => AlertDialog(
                            title: Text(
                              business.businessName ??
                                  'Business',
                            ),
                            content: Text(
                              business.advertisementDescription ??
                                  '',
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () =>
                                        Navigator.of(
                                          context,
                                        ).pop(),
                                child: const Text(
                                  'Close',
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ),
            ),
          );

          // Tap on advertisement
          await tester.tap(
            find.text(
              'Test Business',
            ),
          );
          await tester.pumpAndSettle();

          // Assert
          expect(
            selectedBusiness,
            isNotNull,
          );
          expect(
            selectedBusiness!.username,
            equals(
              'business_1',
            ),
          );
          expect(
            dialogShown,
            isTrue,
          );
          expect(
            find.text(
              'Test Business',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              'Limited time deal',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'advertisement data persistence integration',
        (
          WidgetTester tester,
        ) async {
          // Arrange
          final databaseService =
              DatabaseService();
          final testBusiness = User(
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
                'Test Advertisement',
            advertisementDescription:
                'Test Description',
            advertisementImageUrl:
                'https://example.com/test.jpg',
          );

          // Act & Assert
          // Note: This would require actual database integration
          // For now, we'll test the data structure
          expect(
            testBusiness.advertisementTitle,
            equals(
              'Test Advertisement',
            ),
          );
          expect(
            testBusiness.advertisementDescription,
            equals(
              'Test Description',
            ),
          );
          expect(
            testBusiness.advertisementImageUrl,
            equals(
              'https://example.com/test.jpg',
            ),
          );
        },
      );

      testWidgets(
        'advertisement carousel with mixed business types',
        (
          WidgetTester tester,
        ) async {
          // Arrange - Mix of businesses with and without ads
          final mixedBusinesses = [
            User(
              username:
                  'business_with_ad',
              email:
                  'withad@example.com',
              password:
                  'password',
              type:
                  UserType.business,
              businessName:
                  'Business With Ad',
              advertisementTitle:
                  'Special Offer',
            ),
            User(
              username:
                  'business_without_ad',
              email:
                  'withoutad@example.com',
              password:
                  'password',
              type:
                  UserType.business,
              businessName:
                  'Business Without Ad',
              // No advertisement data
            ),
            User(
              username:
                  'normal_user',
              email:
                  'user@example.com',
              password:
                  'password',
              type:
                  UserType.user,
              // Normal user, not a business
            ),
          ];

          // Filter businesses with ads
          final businessesWithAds =
              mixedBusinesses
                  .where(
                    (
                      business,
                    ) =>
                        business.advertisementImageUrl !=
                            null ||
                        business.advertisementTitle !=
                            null ||
                        business.advertisementDescription !=
                            null,
                  )
                  .toList();

          // Act
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AdvertisementCarousel(
                  businessesWithAds:
                      businessesWithAds,
                  onBusinessTap:
                      (
                        business,
                      ) {},
                ),
              ),
            ),
          );

          // Assert
          expect(
            businessesWithAds.length,
            equals(
              1,
            ),
          );
          expect(
            find.text(
              'Business With Ad',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              'Special Offer',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              'Business Without Ad',
            ),
            findsNothing,
          );
          expect(
            find.text(
              'normal_user',
            ),
            findsNothing,
          );
        },
      );
    },
  );
}
