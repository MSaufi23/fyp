class Review {
  final String id;
  final String businessUsername;
  final String reviewerUsername;
  final int rating;
  final String comment;
  final DateTime timestamp;

  Review({
    required this.id,
    required this.businessUsername,
    required this.reviewerUsername,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory Review.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return Review(
      id:
          map['id']
              as String,
      businessUsername:
          map['businessUsername']
              as String,
      reviewerUsername:
          map['reviewerUsername']
              as String,
      rating:
          map['rating']
              as int,
      comment:
          map['comment']
              as String,
      timestamp: DateTime.parse(
        map['timestamp']
            as String,
      ),
    );
  }

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id':
          id,
      'businessUsername':
          businessUsername,
      'reviewerUsername':
          reviewerUsername,
      'rating':
          rating,
      'comment':
          comment,
      'timestamp':
          timestamp.toIso8601String(),
    };
  }
}
