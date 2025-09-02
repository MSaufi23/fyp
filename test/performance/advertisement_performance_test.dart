import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp/widgets/advertisement_carousel.dart';
import 'package:fyp/models/user.dart';

void
main() {
  group(
    'Advertisement Performance Tests',
    () {
      testWidgets(
        'should load advertisements within acceptable time',
        (
          WidgetTester tester,
        ) async {
          // Arrange
          final testBusinesses = List.generate(
            10,
            (
              index,
            ) => User(
              username:
                  'business_$index',
              email:
                  'business$index@example.com',
              password:
                  'password',
              type:
                  UserType.business,
              businessName:
                  'Business $index',
              advertisementTitle:
                  'Ad $index',
              advertisementDescription:
                  'Description $index',
              advertisementImageUrl:
                  'https://example.com/image$index.jpg',
            ),
          );

          // Act & Assert
          final stopwatch =
              Stopwatch()..start();

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

          stopwatch.stop();

          // Assert that loading time is acceptable (e.g., less than 100ms)
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(
              100,
            ),
          );
        },
      );

      testWidgets(
        'should handle large number of advertisements efficiently',
        (
          WidgetTester tester,
        ) async {
          // Arrange
          final largeBusinessList = List.generate(
            50,
            (
              index,
            ) => User(
              username:
                  'business_$index',
              email:
                  'business$index@example.com',
              password:
                  'password',
              type:
                  UserType.business,
              businessName:
                  'Business $index',
              advertisementTitle:
                  'Ad $index',
              advertisementDescription:
                  'Description $index',
              advertisementImageUrl:
                  'https://example.com/image$index.jpg',
            ),
          );

          // Act
          final stopwatch =
              Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AdvertisementCarousel(
                  businessesWithAds:
                      largeBusinessList,
                  onBusinessTap:
                      (
                        business,
                      ) {},
                ),
              ),
            ),
          );

          stopwatch.stop();

          // Assert that it can handle large lists efficiently
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(
              500,
            ),
          );
        },
      );

      testWidgets(
        'should maintain smooth scrolling performance',
        (
          WidgetTester tester,
        ) async {
          // Arrange
          final testBusinesses = List.generate(
            20,
            (
              index,
            ) => User(
              username:
                  'business_$index',
              email:
                  'business$index@example.com',
              password:
                  'password',
              type:
                  UserType.business,
              businessName:
                  'Business $index',
              advertisementTitle:
                  'Ad $index',
              advertisementDescription:
                  'Description $index',
              advertisementImageUrl:
                  'https://example.com/image$index.jpg',
            ),
          );

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

          // Act - Test scrolling performance
          final scrollStopwatch =
              Stopwatch()..start();

          // Perform multiple scroll operations
          for (
            int i = 0;
            i <
                5;
            i++
          ) {
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
          }

          scrollStopwatch.stop();

          // Assert that scrolling is smooth
          expect(
            scrollStopwatch.elapsedMilliseconds,
            lessThan(
              2000,
            ),
          );
        },
      );

      testWidgets(
        'should handle memory efficiently with many advertisements',
        (
          WidgetTester tester,
        ) async {
          // Arrange
          final manyBusinesses = List.generate(
            100,
            (
              index,
            ) => User(
              username:
                  'business_$index',
              email:
                  'business$index@example.com',
              password:
                  'password',
              type:
                  UserType.business,
              businessName:
                  'Business $index',
              advertisementTitle:
                  'Ad $index',
              advertisementDescription:
                  'Description $index',
              advertisementImageUrl:
                  'https://example.com/image$index.jpg',
            ),
          );

          // Act
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AdvertisementCarousel(
                  businessesWithAds:
                      manyBusinesses,
                  onBusinessTap:
                      (
                        business,
                      ) {},
                ),
              ),
            ),
          );

          // Assert - should not crash and should handle large datasets
          expect(
            find.byType(
              AdvertisementCarousel,
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              '1/100',
            ),
            findsOneWidget,
          ); // Page indicator
        },
      );

      testWidgets(
        'should optimize image loading performance',
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
                  'Business 1',
              advertisementTitle:
                  'Ad 1',
              advertisementImageUrl:
                  'https://example.com/large-image.jpg',
            ),
            User(
              username:
                  'business_2',
              email:
                  'business2@example.com',
              password:
                  'password',
              type:
                  UserType.business,
              businessName:
                  'Business 2',
              advertisementTitle:
                  'Ad 2',
              advertisementImageUrl:
                  'https://example.com/another-large-image.jpg',
            ),
          ];

          // Act
          final imageLoadStopwatch =
              Stopwatch()..start();

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

          // Wait for images to load (simulate)
          await tester.pumpAndSettle();

          imageLoadStopwatch.stop();

          // Assert that image loading doesn't block the UI
          expect(
            imageLoadStopwatch.elapsedMilliseconds,
            lessThan(
              1000,
            ),
          );
        },
      );

      testWidgets(
        'should handle rapid user interactions efficiently',
        (
          WidgetTester tester,
        ) async {
          // Arrange
          final testBusinesses = List.generate(
            10,
            (
              index,
            ) => User(
              username:
                  'business_$index',
              email:
                  'business$index@example.com',
              password:
                  'password',
              type:
                  UserType.business,
              businessName:
                  'Business $index',
              advertisementTitle:
                  'Ad $index',
              advertisementDescription:
                  'Description $index',
            ),
          );

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

          // Act - Rapid interactions
          final interactionStopwatch =
              Stopwatch()..start();

          // Rapid taps and scrolls
          for (
            int i = 0;
            i <
                10;
            i++
          ) {
            await tester.tap(
              find.text(
                'Business $i',
              ),
            );
            await tester.pump();

            if (i <
                9) {
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
            }
          }

          interactionStopwatch.stop();

          // Assert that rapid interactions are handled efficiently
          expect(
            interactionStopwatch.elapsedMilliseconds,
            lessThan(
              3000,
            ),
          );
        },
      );

      testWidgets(
        'should maintain performance with complex advertisement content',
        (
          WidgetTester tester,
        ) async {
          // Arrange - Complex advertisements with long descriptions
          final complexBusinesses = List.generate(
            5,
            (
              index,
            ) => User(
              username:
                  'business_$index',
              email:
                  'business$index@example.com',
              password:
                  'password',
              type:
                  UserType.business,
              businessName:
                  'Complex Business $index',
              advertisementTitle:
                  'Complex Advertisement Title $index with Special Characters!',
              advertisementDescription:
                  'This is a very long advertisement description that contains a lot of text to test how the system handles complex content. It includes multiple sentences and various types of content to ensure proper rendering and performance.',
              advertisementImageUrl:
                  'https://example.com/complex-image-$index.jpg',
            ),
          );

          // Act
          final complexContentStopwatch =
              Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AdvertisementCarousel(
                  businessesWithAds:
                      complexBusinesses,
                  onBusinessTap:
                      (
                        business,
                      ) {},
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          complexContentStopwatch.stop();

          // Assert that complex content doesn't significantly impact performance
          expect(
            complexContentStopwatch.elapsedMilliseconds,
            lessThan(
              200,
            ),
          );
        },
      );

      testWidgets(
        'should handle empty state efficiently',
        (
          WidgetTester tester,
        ) async {
          // Act
          final emptyStateStopwatch =
              Stopwatch()..start();

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

          emptyStateStopwatch.stop();

          // Assert that empty state loads very quickly
          expect(
            emptyStateStopwatch.elapsedMilliseconds,
            lessThan(
              50,
            ),
          );
        },
      );
    },
  );
}
