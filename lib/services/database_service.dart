import 'package:firebase_database/firebase_database.dart';
import '../models/user.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart'; // Import for currentUser
import '../models/menu_item.dart';
import '../models/report.dart';
import '../models/review.dart';

class DatabaseService {
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref();

  static DatabaseReference get database =>
      FirebaseDatabase.instance.ref();

  String _formatTimeOfDay(
    TimeOfDay time,
  ) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Helper to get user type path
  String _getUserTypePath(
    UserType type,
  ) {
    switch (type) {
      case UserType.admin:
        return 'admin';
      case UserType.business:
        return 'business';
      default:
        return 'normalUser';
    }
  }

  // Admin operations
  Future<
    void
  >
  createAdminUser(
    User admin,
  ) async {
    try {
      // Verify that the user type is admin
      if (admin.type !=
          UserType.admin) {
        throw Exception(
          'User must be of type admin',
        );
      }

      final Map<
        String,
        dynamic
      >
      adminData = {
        'username':
            admin.username,
        'email':
            admin.email,
        'password':
            admin.password,
        'type':
            UserType.admin.toString(),
        'createdAt':
            ServerValue.timestamp,
      };

      await _database
          .child(
            'users/admin/${admin.username}',
          )
          .set(
            adminData,
          );
    } catch (
      e
    ) {
      throw Exception(
        'Failed to create admin user: $e',
      );
    }
  }

  Future<
    bool
  >
  isAdmin(
    String username,
  ) async {
    try {
      final snapshot =
          await _database
              .child(
                'users/$username',
              )
              .get();
      if (snapshot.exists) {
        final data =
            snapshot.value
                as Map<
                  dynamic,
                  dynamic
                >;
        return data['type'] ==
            UserType.admin.toString();
      }
      return false;
    } catch (
      e
    ) {
      throw Exception(
        'Failed to check admin status: $e',
      );
    }
  }

  // User operations
  Future<
    void
  >
  createUser(
    User user,
  ) async {
    try {
      final userTypePath = _getUserTypePath(
        user.type,
      );
      final Map<
        String,
        dynamic
      >
      userData = {
        'username':
            user.username,
        'email':
            user.email,
        'password':
            user.password,
        'type':
            user.type.toString(),
        'profileEmoji':
            user.profileEmoji,
        'profilePictureUrl':
            user.profilePictureUrl,
      };

      if (user.type ==
          UserType.business) {
        userData.addAll(
          {
            'businessName':
                user.businessName,
            'businessDescription':
                user.businessDescription,
            'businessAddress':
                user.businessAddress,
            'businessPhone':
                user.businessPhone,
            'businessEmail':
                user.businessEmail,
            'openingTime':
                user.openingTime !=
                        null
                    ? _formatTimeOfDay(
                      user.openingTime!,
                    )
                    : null,
            'closingTime':
                user.closingTime !=
                        null
                    ? _formatTimeOfDay(
                      user.closingTime!,
                    )
                    : null,
            'businessLocation': {
              'latitude':
                  user.businessLocation?.latitude,
              'longitude':
                  user.businessLocation?.longitude,
            },
            'advertisementImageUrl':
                user.advertisementImageUrl,
            'advertisementTitle':
                user.advertisementTitle,
            'advertisementDescription':
                user.advertisementDescription,
          },
        );
      }

      await _database
          .child(
            'users/$userTypePath/${user.username}',
          )
          .set(
            userData,
          );
    } catch (
      e
    ) {
      throw Exception(
        'Failed to create user: $e',
      );
    }
  }

  Future<
    User?
  >
  getUser(
    String username,
  ) async {
    for (final type in [
      UserType.admin,
      UserType.business,
      UserType.user,
    ]) {
      final userTypePath = _getUserTypePath(
        type,
      );
      final snapshot =
          await _database
              .child(
                'users/$userTypePath/$username',
              )
              .get();
      if (snapshot.exists) {
        final data =
            snapshot.value
                as Map<
                  dynamic,
                  dynamic
                >;
        final user = User(
          username:
              data['username']
                  as String,
          email:
              data['email']
                  as String,
          password:
              data['password']
                  as String,
          type:
              type,
          profileEmoji:
              data['profileEmoji']
                  as String?,
          profilePictureUrl:
              data['profilePictureUrl']
                  as String?,
        );

        // If it's a business user, add the business details
        if (user.type ==
            UserType.business) {
          user.businessName =
              data['businessName']
                  as String?;
          user.businessDescription =
              data['businessDescription']
                  as String?;
          user.businessAddress =
              data['businessAddress']
                  as String?;
          user.businessPhone =
              data['businessPhone']
                  as String?;
          user.businessEmail =
              data['businessEmail']
                  as String?;

          // Parse opening and closing times
          if (data['openingTime'] !=
              null) {
            final openingTimeStr =
                data['openingTime']
                    as String;
            final parts = openingTimeStr.split(
              ':',
            );
            user.openingTime = TimeOfDay(
              hour: int.parse(
                parts[0],
              ),
              minute: int.parse(
                parts[1],
              ),
            );
          }

          if (data['closingTime'] !=
              null) {
            final closingTimeStr =
                data['closingTime']
                    as String;
            final parts = closingTimeStr.split(
              ':',
            );
            user.closingTime = TimeOfDay(
              hour: int.parse(
                parts[0],
              ),
              minute: int.parse(
                parts[1],
              ),
            );
          }

          // Parse business location
          if (data['businessLocation'] !=
              null) {
            final location =
                data['businessLocation']
                    as Map<
                      dynamic,
                      dynamic
                    >;
            user.businessLocation = LatLng(
              (location['latitude']
                      as num)
                  .toDouble(),
              (location['longitude']
                      as num)
                  .toDouble(),
            );
          }

          // Add advertisement fields
          user.advertisementImageUrl =
              data['advertisementImageUrl']
                  as String?;
          user.advertisementTitle =
              data['advertisementTitle']
                  as String?;
          user.advertisementDescription =
              data['advertisementDescription']
                  as String?;
        }

        return user;
      }
    }
    return null;
  }

  Future<
    void
  >
  updateUser(
    User user,
  ) async {
    final userTypePath = _getUserTypePath(
      user.type,
    );
    final Map<
      String,
      dynamic
    >
    userData = {
      'email':
          user.email,
      'password':
          user.password,
      'type':
          user.type.toString(),
      'profileEmoji':
          user.profileEmoji,
      'profilePictureUrl':
          user.profilePictureUrl,
    };

    if (user.type ==
        UserType.business) {
      userData.addAll(
        {
          'businessName':
              user.businessName,
          'businessDescription':
              user.businessDescription,
          'businessAddress':
              user.businessAddress,
          'businessPhone':
              user.businessPhone,
          'businessEmail':
              user.businessEmail,
          'openingTime':
              user.openingTime !=
                      null
                  ? _formatTimeOfDay(
                    user.openingTime!,
                  )
                  : null,
          'closingTime':
              user.closingTime !=
                      null
                  ? _formatTimeOfDay(
                    user.closingTime!,
                  )
                  : null,
          'businessLocation': {
            'latitude':
                user.businessLocation?.latitude,
            'longitude':
                user.businessLocation?.longitude,
          },
          'advertisementImageUrl':
              user.advertisementImageUrl,
          'advertisementTitle':
              user.advertisementTitle,
          'advertisementDescription':
              user.advertisementDescription,
        },
      );
    }

    await _database
        .child(
          'users/$userTypePath/${user.username}',
        )
        .update(
          userData,
        );
  }

  Future<
    void
  >
  deleteUser(
    User user,
  ) async {
    final userTypePath = _getUserTypePath(
      user.type,
    );
    await _database
        .child(
          'users/$userTypePath/${user.username}',
        )
        .remove();
  }

  // Business operations
  Future<
    List<
      User
    >
  >
  getAllBusinesses() async {
    print(
      'getAllBusinesses called',
    );
    final snapshot =
        await _database
            .child(
              'users/business',
            )
            .get();
    print(
      'Business snapshot exists: ${snapshot.exists}',
    );
    if (snapshot.exists) {
      final data =
          snapshot.value
              as Map<
                dynamic,
                dynamic
              >;
      print(
        'Business data keys: ${data.keys}',
      );
      final result =
          data.entries.map(
            (
              entry,
            ) {
              final userData =
                  entry.value
                      as Map<
                        dynamic,
                        dynamic
                      >;
              return User(
                username:
                    userData['username'],
                email:
                    userData['email'],
                password:
                    userData['password'],
                type:
                    UserType.business,
                businessName:
                    userData['businessName'],
                businessDescription:
                    userData['businessDescription'],
                businessAddress:
                    userData['businessAddress'],
                businessPhone:
                    userData['businessPhone'],
                businessEmail:
                    userData['businessEmail'],
                profileEmoji:
                    userData['profileEmoji'],
                profilePictureUrl:
                    userData['profilePictureUrl'],
                openingTime:
                    userData['openingTime'] !=
                            null
                        ? TimeOfDay(
                          hour: int.parse(
                            userData['openingTime'].split(
                              ':',
                            )[0],
                          ),
                          minute: int.parse(
                            userData['openingTime'].split(
                              ':',
                            )[1],
                          ),
                        )
                        : null,
                closingTime:
                    userData['closingTime'] !=
                            null
                        ? TimeOfDay(
                          hour: int.parse(
                            userData['closingTime'].split(
                              ':',
                            )[0],
                          ),
                          minute: int.parse(
                            userData['closingTime'].split(
                              ':',
                            )[1],
                          ),
                        )
                        : null,
                businessLocation:
                    userData['businessLocation'] !=
                            null
                        ? LatLng(
                          (userData['businessLocation']['latitude']
                                  as num)
                              .toDouble(),
                          (userData['businessLocation']['longitude']
                                  as num)
                              .toDouble(),
                        )
                        : null,
                advertisementImageUrl:
                    userData['advertisementImageUrl'],
                advertisementTitle:
                    userData['advertisementTitle'],
                advertisementDescription:
                    userData['advertisementDescription'],
              );
            },
          ).toList();

      return result;
    }
    return [];
  }

  Future<
    void
  >
  updateUserProfile(
    String username,
    Map<
      String,
      dynamic
    >
    updates,
  ) async {
    try {
      final userTypePath = _getUserTypePath(
        currentUser!.type,
      );
      await _database
          .child(
            'users/$userTypePath/$username',
          )
          .update(
            updates,
          );
    } catch (
      e
    ) {
      throw Exception(
        'Failed to update user profile: $e',
      );
    }
  }

  Future<
    bool
  >
  isSuperAdmin() async {
    if (currentUser ==
        null)
      return false;
    return currentUser!.username ==
        'admin1';
  }

  Future<
    void
  >
  deleteUserByType(
    String username,
    UserType userType,
  ) async {
    try {
      final userTypePath = _getUserTypePath(
        userType,
      );
      await _database
          .child(
            'users/$userTypePath/$username',
          )
          .remove();
    } catch (
      e
    ) {
      throw Exception(
        'Failed to delete user: $e',
      );
    }
  }

  Future<
    void
  >
  updateUserByType(
    String username,
    UserType userType,
    Map<
      String,
      dynamic
    >
    updates,
  ) async {
    try {
      final userTypePath = _getUserTypePath(
        userType,
      );
      await _database
          .child(
            'users/$userTypePath/$username',
          )
          .update(
            updates,
          );
    } catch (
      e
    ) {
      throw Exception(
        'Failed to update user: $e',
      );
    }
  }

  // Menu management for business owners
  Future<
    void
  >
  addMenuItem(
    String businessUsername,
    MenuItem item,
  ) async {
    final ref =
        _database
            .child(
              'users/business/$businessUsername/menu',
            )
            .push();
    await ref.set(
      item.toMap(),
    );
  }

  Future<
    void
  >
  updateMenuItem(
    String businessUsername,
    MenuItem item,
  ) async {
    await _database
        .child(
          'users/business/$businessUsername/menu/${item.id}',
        )
        .update(
          item.toMap(),
        );
  }

  Future<
    void
  >
  deleteMenuItem(
    String businessUsername,
    String menuItemId,
  ) async {
    await _database
        .child(
          'users/business/$businessUsername/menu/$menuItemId',
        )
        .remove();
  }

  Future<
    List<
      MenuItem
    >
  >
  getMenuItems(
    String businessUsername,
  ) async {
    final snapshot =
        await _database
            .child(
              'users/business/$businessUsername/menu',
            )
            .get();
    if (snapshot.exists) {
      final data =
          snapshot.value
              as Map<
                dynamic,
                dynamic
              >;
      return data.entries
          .map<
            MenuItem
          >(
            (
              entry,
            ) => MenuItem.fromMap(
              entry.key,
              entry.value,
            ),
          )
          .toList();
    }
    return [];
  }

  // Fetch all users (business and normal) with location data
  Future<
    List<
      User
    >
  >
  getAllUsersWithLocation() async {
    List<
      User
    >
    usersWithLocation =
        [];

    // Fetch business users
    final businessSnapshot =
        await _database
            .child(
              'users/business',
            )
            .get();
    if (businessSnapshot.exists) {
      final data =
          businessSnapshot.value
              as Map<
                dynamic,
                dynamic
              >;
      usersWithLocation.addAll(
        data.entries.map(
          (
            entry,
          ) {
            final userData =
                entry.value
                    as Map<
                      dynamic,
                      dynamic
                    >;
            return User(
              username:
                  userData['username'],
              email:
                  userData['email'],
              password:
                  userData['password'],
              type:
                  UserType.business,
              businessName:
                  userData['businessName'],
              businessDescription:
                  userData['businessDescription'],
              businessAddress:
                  userData['businessAddress'],
              businessPhone:
                  userData['businessPhone'],
              businessEmail:
                  userData['businessEmail'],
              profileEmoji:
                  userData['profileEmoji'],
              profilePictureUrl:
                  userData['profilePictureUrl'],
              openingTime:
                  userData['openingTime'] !=
                          null
                      ? TimeOfDay(
                        hour: int.parse(
                          userData['openingTime'].split(
                            ':',
                          )[0],
                        ),
                        minute: int.parse(
                          userData['openingTime'].split(
                            ':',
                          )[1],
                        ),
                      )
                      : null,
              closingTime:
                  userData['closingTime'] !=
                          null
                      ? TimeOfDay(
                        hour: int.parse(
                          userData['closingTime'].split(
                            ':',
                          )[0],
                        ),
                        minute: int.parse(
                          userData['closingTime'].split(
                            ':',
                          )[1],
                        ),
                      )
                      : null,
              businessLocation:
                  userData['businessLocation'] !=
                          null
                      ? LatLng(
                        (userData['businessLocation']['latitude']
                                as num)
                            .toDouble(),
                        (userData['businessLocation']['longitude']
                                as num)
                            .toDouble(),
                      )
                      : null,
              advertisementImageUrl:
                  userData['advertisementImageUrl'],
              advertisementTitle:
                  userData['advertisementTitle'],
              advertisementDescription:
                  userData['advertisementDescription'],
            );
          },
        ),
      );
    }

    // Fetch normal users
    final normalSnapshot =
        await _database
            .child(
              'users/normalUser',
            )
            .get();
    if (normalSnapshot.exists) {
      final data =
          normalSnapshot.value
              as Map<
                dynamic,
                dynamic
              >;
      usersWithLocation.addAll(
        data.entries
            .map(
              (
                entry,
              ) {
                final userData =
                    entry.value
                        as Map<
                          dynamic,
                          dynamic
                        >;
                // Only add if location exists
                if (userData['businessLocation'] !=
                    null) {
                  return User(
                    username:
                        userData['username'],
                    email:
                        userData['email'],
                    password:
                        userData['password'],
                    type:
                        UserType.user,
                    businessLocation: LatLng(
                      (userData['businessLocation']['latitude']
                              as num)
                          .toDouble(),
                      (userData['businessLocation']['longitude']
                              as num)
                          .toDouble(),
                    ),
                  );
                }
                return null;
              },
            )
            .whereType<
              User
            >(),
      );
    }

    return usersWithLocation;
  }

  // Add a review for a business
  Future<
    void
  >
  addBusinessReview({
    required String businessUsername,
    required String reviewerUsername,
    required int rating,
    required String comment,
  }) async {
    final reviewRef =
        _database
            .child(
              'users/business/$businessUsername/reviews',
            )
            .push();
    await reviewRef.set(
      {
        'reviewer':
            reviewerUsername,
        'rating':
            rating,
        'comment':
            comment,
        'timestamp':
            ServerValue.timestamp,
      },
    );
  }

  // Get all reviews for a business
  Future<
    List<
      Review
    >
  >
  getBusinessReviews(
    String businessUsername,
  ) async {
    final snapshot =
        await _database
            .child(
              'users/business/$businessUsername/reviews',
            )
            .get();
    if (!snapshot.exists) return [];

    final List<
      Review
    >
    reviews =
        [];
    final Map<
      dynamic,
      dynamic
    >
    reviewsMap =
        snapshot.value
            as Map<
              dynamic,
              dynamic
            >;

    reviewsMap.forEach(
      (
        key,
        value,
      ) {
        final reviewMap = Map<
          String,
          dynamic
        >.from(
          value,
        );
        final dynamic ts =
            reviewMap['timestamp'];
        DateTime timestamp;
        if (ts
            is int) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(
            ts,
          );
        } else if (ts
            is String) {
          timestamp =
              DateTime.tryParse(
                ts,
              ) ??
              DateTime.now();
        } else {
          timestamp =
              DateTime.now();
        }
        reviews.add(
          Review(
            id:
                key.toString(),
            businessUsername:
                businessUsername,
            reviewerUsername:
                reviewMap['reviewer'],
            rating:
                reviewMap['rating'],
            comment:
                reviewMap['comment'],
            timestamp:
                timestamp,
          ),
        );
      },
    );

    // Sort reviews by timestamp, newest first
    reviews.sort(
      (
        a,
        b,
      ) => b.timestamp.compareTo(
        a.timestamp,
      ),
    );

    return reviews;
  }

  // Calculate average rating for a business
  Future<
    double
  >
  getBusinessAverageRating(
    String businessUsername,
  ) async {
    final reviews = await getBusinessReviews(
      businessUsername,
    );
    if (reviews.isEmpty) return 0.0;
    final total = reviews.fold<
      int
    >(
      0,
      (
        sum,
        review,
      ) =>
          sum +
          review.rating,
    );
    return total /
        reviews.length;
  }

  // Report management
  Future<
    void
  >
  createReport(
    Report report,
  ) async {
    try {
      await _database
          .child(
            'reports/${report.id}',
          )
          .set(
            report.toMap(),
          );
    } catch (
      e
    ) {
      throw Exception(
        'Failed to create report: $e',
      );
    }
  }

  Future<
    List<
      Report
    >
  >
  getAllReports() async {
    try {
      final snapshot =
          await _database
              .child(
                'reports',
              )
              .get();
      if (snapshot.exists) {
        final data =
            snapshot.value
                as Map<
                  dynamic,
                  dynamic
                >;
        return data.entries
            .map<
              Report
            >(
              (
                entry,
              ) => Report.fromMap(
                entry.value,
              ),
            )
            .toList()
          ..sort(
            (
              a,
              b,
            ) => b.timestamp.compareTo(
              a.timestamp,
            ),
          ); // Sort by newest first
      }
      return [];
    } catch (
      e
    ) {
      throw Exception(
        'Failed to get reports: $e',
      );
    }
  }

  Future<
    void
  >
  updateReportStatus(
    String reportId,
    ReportStatus status, {
    String? adminResponse,
  }) async {
    try {
      final updates = {
        'status':
            status.toString(),
        if (adminResponse !=
            null)
          'adminResponse':
              adminResponse,
      };
      await _database
          .child(
            'reports/$reportId',
          )
          .update(
            updates,
          );
    } catch (
      e
    ) {
      throw Exception(
        'Failed to update report: $e',
      );
    }
  }

  Future<
    List<
      Report
    >
  >
  getUserReports(
    String username,
  ) async {
    try {
      final snapshot =
          await _database
              .child(
                'reports',
              )
              .get();
      if (snapshot.exists) {
        final data =
            snapshot.value
                as Map<
                  dynamic,
                  dynamic
                >;
        return data.entries
            .map<
              Report
            >(
              (
                entry,
              ) => Report.fromMap(
                entry.value,
              ),
            )
            .where(
              (
                report,
              ) =>
                  report.reporterUsername ==
                  username,
            )
            .toList()
          ..sort(
            (
              a,
              b,
            ) => b.timestamp.compareTo(
              a.timestamp,
            ),
          );
      }
      return [];
    } catch (
      e
    ) {
      throw Exception(
        'Failed to get user reports: $e',
      );
    }
  }

  Future<
    List<
      Report
    >
  >
  getReports() async {
    final snapshot =
        await _database
            .child(
              'reports',
            )
            .get();
    if (snapshot.value ==
        null)
      return [];

    final List<
      Report
    >
    reports =
        [];
    final Map<
      dynamic,
      dynamic
    >
    reportsMap =
        snapshot.value
            as Map<
              dynamic,
              dynamic
            >;

    reportsMap.forEach(
      (
        key,
        value,
      ) {
        reports.add(
          Report.fromMap(
            Map<
              String,
              dynamic
            >.from(
              value,
            ),
          ),
        );
      },
    );

    return reports;
  }

  Future<
    void
  >
  addReview(
    Review review,
  ) async {
    await _database
        .child(
          'reviews',
        )
        .child(
          review.id,
        )
        .set(
          review.toMap(),
        );
  }

  Future<
    void
  >
  deleteReview(
    String reviewId,
    String businessUsername,
  ) async {
    await _database
        .child(
          'users/business/$businessUsername/reviews',
        )
        .child(
          reviewId,
        )
        .remove();
  }

  // Get all reviews for admin management
  Future<
    List<
      Review
    >
  >
  getAllReviews() async {
    try {
      final List<
        Review
      >
      allReviews =
          [];

      // Get all business users
      final businessSnapshot =
          await _database
              .child(
                'users/business',
              )
              .get();

      if (businessSnapshot.exists) {
        final businessData =
            businessSnapshot.value
                as Map<
                  dynamic,
                  dynamic
                >;

        // Iterate through each business
        for (final businessEntry in businessData.entries) {
          final businessUsername =
              businessEntry.key
                  as String;
          final businessUserData =
              businessEntry.value
                  as Map<
                    dynamic,
                    dynamic
                  >;

          // Check if this business has reviews
          if (businessUserData.containsKey(
            'reviews',
          )) {
            final reviewsData =
                businessUserData['reviews']
                    as Map<
                      dynamic,
                      dynamic
                    >;

            // Process each review for this business
            for (final reviewEntry in reviewsData.entries) {
              final reviewId =
                  reviewEntry.key
                      as String;
              final reviewData =
                  reviewEntry.value
                      as Map<
                        dynamic,
                        dynamic
                      >;

              // Parse timestamp
              final dynamic ts =
                  reviewData['timestamp'];
              DateTime timestamp;
              if (ts
                  is int) {
                timestamp = DateTime.fromMillisecondsSinceEpoch(
                  ts,
                );
              } else if (ts
                  is String) {
                timestamp =
                    DateTime.tryParse(
                      ts,
                    ) ??
                    DateTime.now();
              } else {
                timestamp =
                    DateTime.now();
              }

              // Create Review object
              final review = Review(
                id:
                    reviewId,
                businessUsername:
                    businessUsername,
                reviewerUsername:
                    reviewData['reviewer'] ??
                    '',
                rating:
                    reviewData['rating'] ??
                    0,
                comment:
                    reviewData['comment'] ??
                    '',
                timestamp:
                    timestamp,
              );

              allReviews.add(
                review,
              );
            }
          }
        }
      }

      // Sort by timestamp, newest first
      allReviews.sort(
        (
          a,
          b,
        ) => b.timestamp.compareTo(
          a.timestamp,
        ),
      );

      return allReviews;
    } catch (
      e
    ) {
      throw Exception(
        'Failed to get reviews: $e',
      );
    }
  }

  // Get all advertisements for admin management
  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  getAllAdvertisements() async {
    try {
      final snapshot =
          await _database
              .child(
                'users/business',
              )
              .get();
      if (snapshot.exists) {
        final data =
            snapshot.value
                as Map<
                  dynamic,
                  dynamic
                >;
        final List<
          Map<
            String,
            dynamic
          >
        >
        advertisements =
            [];

        data.forEach(
          (
            username,
            userData,
          ) {
            final userMap =
                userData
                    as Map<
                      dynamic,
                      dynamic
                    >;
            if (userMap['advertisementImageUrl'] !=
                    null ||
                userMap['advertisementTitle'] !=
                    null ||
                userMap['advertisementDescription'] !=
                    null) {
              advertisements.add(
                {
                  'username':
                      username,
                  'businessName':
                      userMap['businessName'] ??
                      '',
                  'advertisementImageUrl':
                      userMap['advertisementImageUrl'],
                  'advertisementTitle':
                      userMap['advertisementTitle'],
                  'advertisementDescription':
                      userMap['advertisementDescription'],
                },
              );
            }
          },
        );
        return advertisements;
      }
      return [];
    } catch (
      e
    ) {
      throw Exception(
        'Failed to get advertisements: $e',
      );
    }
  }

  // Delete advertisement for a business
  Future<
    void
  >
  deleteAdvertisement(
    String username,
  ) async {
    try {
      await _database
          .child(
            'users/business/$username',
          )
          .update(
            {
              'advertisementImageUrl':
                  null,
              'advertisementTitle':
                  null,
              'advertisementDescription':
                  null,
            },
          );
    } catch (
      e
    ) {
      throw Exception(
        'Failed to delete advertisement: $e',
      );
    }
  }

  Future<
    void
  >
  deleteReport(
    String reportId,
  ) async {
    try {
      await _database
          .child(
            'reports',
          )
          .child(
            reportId,
          )
          .remove();
    } catch (
      e
    ) {
      throw Exception(
        'Failed to delete report: $e',
      );
    }
  }
}
