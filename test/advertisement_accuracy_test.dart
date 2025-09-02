import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fyp/widgets/advertisement_carousel.dart';
import 'package:fyp/widgets/advertisement_manager.dart';
import 'package:fyp/models/user.dart';
import 'package:fyp/services/database_service.dart';

// Generate mocks
@GenerateMocks(
  [
    DatabaseService,
  ],
)
import 'advertisement_accuracy_test.mocks.dart';

void
main() {
  group(
    'Advertisement Accuracy Tests',
    () {
      late MockDatabaseService mockDatabaseService;

      setUp(
        () {
          mockDatabaseService =
              MockDatabaseService();
        },
      );

      group(
        'Advertisement Display Accuracy',
        () {
          testWidgets(
            'should display correct advertisement data',
            (
              WidgetTester tester,
            ) async {
              // Arrange
              final testBusinesses = [
                User(
                  username:
                      'test_business1',
                  email:
                      'test1@example.com',
                  password:
                      'password',
                  type:
                      UserType.business,
                  businessName:
                      'Test Restaurant',
                  advertisementTitle:
                      'Special Offer!',
                  advertisementDescription:
                      '50% off on all items',
                  advertisementImageUrl:
                      'https://example.com/test-image.jpg',
                ),
                User(
                  username:
                      'test_business2',
                  email:
                      'test2@example.com',
                  password:
                      'password',
                  type:
                      UserType.business,
                  businessName:
                      'Test Cafe',
                  advertisementTitle:
                      'Happy Hours',
                  advertisementDescription:
                      'Buy 1 Get 1 Free',
                  advertisementImageUrl:
                      'https://example.com/test-image2.jpg',
                ),
              ];

              // Act
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: AdvertisementCarousel(
                      businessesWithAds:
                          testBusinesses,
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
                find.text(
                  'Special Offer!',
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  '50% off on all items',
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  'Happy Hours',
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  'Buy 1 Get 1 Free',
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  'Test Restaurant',
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  'Test Cafe',
                ),
                findsOneWidget,
              );
            },
          );

          testWidgets(
            'should handle missing advertisement data gracefully',
            (
              WidgetTester tester,
            ) async {
              // Arrange
              final testBusinesses = [
                User(
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
                  // No advertisement data
                ),
              ];

              // Act
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: AdvertisementCarousel(
                      businessesWithAds:
                          testBusinesses,
                      onBusinessTap:
                          (
                            business,
                          ) {},
                    ),
                  ),
                ),
              );

              // Assert - should not crash and should handle gracefully
              expect(
                find.text(
                  'Test Business',
                ),
                findsOneWidget,
              );
            },
          );

          testWidgets(
            'should display advertisement carousel with correct navigation',
            (
              WidgetTester tester,
            ) async {
              // Arrange
              final testBusinesses = [
                User(
                  username:
                      'business1',
                  email:
                      'b1@example.com',
                  password:
                      'password',
                  type:
                      UserType.business,
                  businessName:
                      'Business 1',
                  advertisementTitle:
                      'Ad 1',
                ),
                User(
                  username:
                      'business2',
                  email:
                      'b2@example.com',
                  password:
                      'password',
                  type:
                      UserType.business,
                  businessName:
                      'Business 2',
                  advertisementTitle:
                      'Ad 2',
                ),
              ];

              // Act
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: AdvertisementCarousel(
                      businessesWithAds:
                          testBusinesses,
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
                find.text(
                  '1/2',
                ),
                findsOneWidget,
              ); // Page indicator
              expect(
                find.text(
                  'Ad 1',
                ),
                findsOneWidget,
              );

              // Test navigation
              await tester.drag(
                find.byType(
                  PageView,
                ),
                const Offset(
                  -300,
                  0,
                ),
              );
              await tester.pumpAndSettle();

              expect(
                find.text(
                  '2/2',
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  'Ad 2',
                ),
                findsOneWidget,
              );
            },
          );
        },
      );

      group(
        'Advertisement Manager Accuracy',
        () {
          testWidgets(
            'should validate advertisement input fields',
            (
              WidgetTester tester,
            ) async {
              String? capturedImageUrl;
              String? capturedTitle;
              String? capturedDescription;

              // Act
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: AdvertisementManager(
                      isEditing:
                          true,
                      onImageSelected:
                          (
                            url,
                          ) =>
                              capturedImageUrl =
                                  url,
                      onTitleChanged:
                          (
                            title,
                          ) =>
                              capturedTitle =
                                  title,
                      onDescriptionChanged:
                          (
                            description,
                          ) =>
                              capturedDescription =
                                  description,
                    ),
                  ),
                ),
              );

              // Test title input
              await tester.enterText(
                find
                    .byType(
                      TextField,
                    )
                    .first,
                'Test Advertisement Title',
              );
              await tester.pump();
              expect(
                capturedTitle,
                equals(
                  'Test Advertisement Title',
                ),
              );

              // Test description input
              await tester.enterText(
                find
                    .byType(
                      TextField,
                    )
                    .last,
                'Test advertisement description',
              );
              await tester.pump();
              expect(
                capturedDescription,
                equals(
                  'Test advertisement description',
                ),
              );
            },
          );

          testWidgets(
            'should handle empty input fields correctly',
            (
              WidgetTester tester,
            ) async {
              String? capturedTitle;
              String? capturedDescription;

              // Act
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: AdvertisementManager(
                      isEditing:
                          true,
                      onImageSelected:
                          (
                            url,
                          ) {},
                      onTitleChanged:
                          (
                            title,
                          ) =>
                              capturedTitle =
                                  title,
                      onDescriptionChanged:
                          (
                            description,
                          ) =>
                              capturedDescription =
                                  description,
                    ),
                  ),
                ),
              );

              // Test empty title
              await tester.enterText(
                find
                    .byType(
                      TextField,
                    )
                    .first,
                '',
              );
              await tester.pump();
              expect(
                capturedTitle,
                isNull,
              );

              // Test empty description
              await tester.enterText(
                find
                    .byType(
                      TextField,
                    )
                    .last,
                '',
              );
              await tester.pump();
              expect(
                capturedDescription,
                isNull,
              );
            },
          );

          testWidgets(
            'should display current advertisement data when editing',
            (
              WidgetTester tester,
            ) async {
              // Act
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: AdvertisementManager(
                      isEditing:
                          true,
                      currentImageUrl:
                          'https://example.com/current-image.jpg',
                      currentTitle:
                          'Current Title',
                      currentDescription:
                          'Current Description',
                      onImageSelected:
                          (
                            url,
                          ) {},
                      onTitleChanged:
                          (
                            title,
                          ) {},
                      onDescriptionChanged:
                          (
                            description,
                          ) {},
                    ),
                  ),
                ),
              );

              // Assert
              expect(
                find.text(
                  'Current Title',
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  'Current Description',
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  '(Editing)',
                ),
                findsOneWidget,
              );
            },
          );

          testWidgets(
            'should disable input fields when not editing',
            (
              WidgetTester tester,
            ) async {
              // Act
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: AdvertisementManager(
                      isEditing:
                          false,
                      currentTitle:
                          'Current Title',
                      currentDescription:
                          'Current Description',
                      onImageSelected:
                          (
                            url,
                          ) {},
                      onTitleChanged:
                          (
                            title,
                          ) {},
                      onDescriptionChanged:
                          (
                            description,
                          ) {},
                    ),
                  ),
                ),
              );

              // Assert
              final textFields = find.byType(
                TextField,
              );
              for (final field in textFields.evaluate()) {
                expect(
                  (field.widget
                          as TextField)
                      .enabled,
                  isFalse,
                );
              }
            },
          );
        },
      );

      group(
        'Advertisement Data Accuracy',
        () {
          test(
            'should filter businesses with advertisements correctly',
            () {
              // Arrange
              final allBusinesses = [
                User(
                  username:
                      'business1',
                  email:
                      'b1@example.com',
                  password:
                      'password',
                  type:
                      UserType.business,
                  advertisementTitle:
                      'Ad 1',
                ),
                User(
                  username:
                      'business2',
                  email:
                      'b2@example.com',
                  password:
                      'password',
                  type:
                      UserType.business,
                  // No advertisement
                ),
                User(
                  username:
                      'business3',
                  email:
                      'b3@example.com',
                  password:
                      'password',
                  type:
                      UserType.business,
                  advertisementDescription:
                      'Ad 3',
                ),
                User(
                  username:
                      'business4',
                  email:
                      'b4@example.com',
                  password:
                      'password',
                  type:
                      UserType.business,
                  advertisementImageUrl:
                      'https://example.com/image.jpg',
                ),
              ];

              // Act
              final businessesWithAds =
                  allBusinesses
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

              // Assert
              expect(
                businessesWithAds.length,
                equals(
                  3,
                ),
              );
              expect(
                businessesWithAds[0].username,
                equals(
                  'business1',
                ),
              );
              expect(
                businessesWithAds[1].username,
                equals(
                  'business3',
                ),
              );
              expect(
                businessesWithAds[2].username,
                equals(
                  'business4',
                ),
              );
            },
          );

          test(
            'should handle businesses with multiple advertisement fields',
            () {
              // Arrange
              final businessWithMultipleAds = User(
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

              // Act & Assert
              expect(
                businessWithMultipleAds.advertisementTitle,
                equals(
                  'Special Offer',
                ),
              );
              expect(
                businessWithMultipleAds.advertisementDescription,
                equals(
                  '50% off everything',
                ),
              );
              expect(
                businessWithMultipleAds.advertisementImageUrl,
                equals(
                  'https://example.com/image.jpg',
                ),
              );
            },
          );
        },
      );

      group(
        'Advertisement Error Handling',
        () {
          testWidgets(
            'should handle image loading errors gracefully',
            (
              WidgetTester tester,
            ) async {
              // Arrange
              final testBusinesses = [
                User(
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
                      'Test Ad',
                  advertisementImageUrl:
                      'https://invalid-url.com/image.jpg',
                ),
              ];

              // Act
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: AdvertisementCarousel(
                      businessesWithAds:
                          testBusinesses,
                      onBusinessTap:
                          (
                            business,
                          ) {},
                    ),
                  ),
                ),
              );

              // Assert - should not crash and should show error handling
              expect(
                find.text(
                  'Test Business',
                ),
                findsOneWidget,
              );
              expect(
                find.text(
                  'Test Ad',
                ),
                findsOneWidget,
              );
            },
          );

          testWidgets(
            'should handle empty business list',
            (
              WidgetTester tester,
            ) async {
              // Act
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: AdvertisementCarousel(
                      businessesWithAds:
                          [],
                      onBusinessTap:
                          (
                            business,
                          ) {},
                    ),
                  ),
                ),
              );

              // Assert - should not crash and should handle empty list
              expect(
                find.byType(
                  AdvertisementCarousel,
                ),
                findsOneWidget,
              );
            },
          );
        },
      );

      group(
        'Advertisement Interaction Testing',
        () {
          testWidgets(
            'should call onBusinessTap when advertisement is tapped',
            (
              WidgetTester tester,
            ) async {
              // Arrange
              User? tappedBusiness;
              final testBusinesses = [
                User(
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
                      'Test Ad',
                ),
              ];

              // Act
              await tester.pumpWidget(
                MaterialApp(
                  home: Scaffold(
                    body: AdvertisementCarousel(
                      businessesWithAds:
                          testBusinesses,
                      onBusinessTap:
                          (
                            business,
                          ) =>
                              tappedBusiness =
                                  business,
                    ),
                  ),
                ),
              );

              // Tap on the advertisement
              await tester.tap(
                find.text(
                  'Test Business',
                ),
              );
              await tester.pump();

              // Assert
              expect(
                tappedBusiness,
                isNotNull,
              );
              expect(
                tappedBusiness!.username,
                equals(
                  'test_business',
                ),
              );
            },
          );
        },
      );
    },
  );
}
