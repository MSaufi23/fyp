import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum UserType {
  user,
  business,
  admin,
}

class User {
  final String username;
  final String email;
  final String password;
  final UserType type;
  String? businessName;
  String? businessDescription;
  String? businessAddress;
  String? businessPhone;
  String? businessEmail;
  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  LatLng? businessLocation;
  final String? profileEmoji;
  String? profilePictureUrl;
  String? advertisementImageUrl;
  String? advertisementTitle;
  String? advertisementDescription;

  User({
    required this.username,
    required this.email,
    required this.password,
    required this.type,
    this.businessName,
    this.businessDescription,
    this.businessAddress,
    this.businessPhone,
    this.businessEmail,
    this.openingTime,
    this.closingTime,
    this.businessLocation,
    this.profileEmoji,
    this.profilePictureUrl,
    this.advertisementImageUrl,
    this.advertisementTitle,
    this.advertisementDescription,
  });

  // Factory constructor for normal user
  factory User.normal({
    required String username,
    required String email,
    required String password,
  }) {
    return User(
      username:
          username,
      email:
          email,
      password:
          password,
      type:
          UserType.user,
    );
  }

  // Factory constructor for business owner
  factory User.business({
    required String username,
    required String email,
    required String password,
    required String businessName,
    required String businessDescription,
    required String businessAddress,
    required String businessPhone,
    required String businessEmail,
    required TimeOfDay openingTime,
    required TimeOfDay closingTime,
    required LatLng businessLocation,
  }) {
    return User(
      username:
          username,
      email:
          email,
      password:
          password,
      type:
          UserType.business,
      businessName:
          businessName,
      businessDescription:
          businessDescription,
      businessAddress:
          businessAddress,
      businessPhone:
          businessPhone,
      businessEmail:
          businessEmail,
      openingTime:
          openingTime,
      closingTime:
          closingTime,
      businessLocation:
          businessLocation,
    );
  }

  // Example business user
  static User get exampleBusinessUser {
    return User.business(
      username:
          'business123',
      email:
          'business@example.com',
      password:
          'business123',
      businessName:
          'Example Business',
      businessDescription:
          'A sample business for testing purposes',
      businessAddress:
          '123 Business Street, Malacca City, 75000, Malaysia',
      businessPhone:
          '+60123456789',
      businessEmail:
          'contact@examplebusiness.com',
      openingTime: const TimeOfDay(
        hour:
            9,
        minute:
            0,
      ),
      closingTime: const TimeOfDay(
        hour:
            18,
        minute:
            0,
      ),
      businessLocation: const LatLng(
        2.1896,
        102.2501,
      ), // Malacca City coordinates
    );
  }

  // Example normal user
  static User get exampleNormalUser {
    return User.normal(
      username:
          'user123',
      email:
          'user@example.com',
      password:
          'password123',
    );
  }

  factory User.fromMap(
    Map<
      dynamic,
      dynamic
    >
    map,
    String username,
  ) {
    return User(
      username:
          username,
      email:
          map['email'] ??
          '',
      password:
          map['password'] ??
          '',
      type: UserType.values.firstWhere(
        (
          e,
        ) =>
            e.toString() ==
            map['type'],
        orElse:
            () =>
                UserType.user,
      ),
      businessName:
          map['businessName'],
      businessDescription:
          map['businessDescription'],
      businessAddress:
          map['businessAddress'],
      businessPhone:
          map['businessPhone'],
      businessEmail:
          map['businessEmail'],
      openingTime:
          map['openingTime'] !=
                  null
              ? TimeOfDay(
                hour: int.parse(
                  map['openingTime'].split(
                    ':',
                  )[0],
                ),
                minute: int.parse(
                  map['openingTime'].split(
                    ':',
                  )[1],
                ),
              )
              : null,
      closingTime:
          map['closingTime'] !=
                  null
              ? TimeOfDay(
                hour: int.parse(
                  map['closingTime'].split(
                    ':',
                  )[0],
                ),
                minute: int.parse(
                  map['closingTime'].split(
                    ':',
                  )[1],
                ),
              )
              : null,
      businessLocation:
          map['businessLocation'] !=
                  null
              ? LatLng(
                map['businessLocation']['latitude'],
                map['businessLocation']['longitude'],
              )
              : null,
      profileEmoji:
          map['profileEmoji'],
      profilePictureUrl:
          map['profilePictureUrl'],
      advertisementImageUrl:
          map['advertisementImageUrl'],
      advertisementTitle:
          map['advertisementTitle'],
      advertisementDescription:
          map['advertisementDescription'],
    );
  }
}
