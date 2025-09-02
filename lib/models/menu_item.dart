class MenuItem {
  String id;
  String name;
  String description;
  double price;
  String? imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
  });

  factory MenuItem.fromMap(
    String id,
    Map<
      dynamic,
      dynamic
    >
    data,
  ) {
    return MenuItem(
      id:
          id,
      name:
          data['name'] ??
          '',
      description:
          data['description'] ??
          '',
      price:
          (data['price']
                  as num?)
              ?.toDouble() ??
          0.0,
      imageUrl:
          data['imageUrl'],
    );
  }

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'name':
          name,
      'description':
          description,
      'price':
          price,
      'imageUrl':
          imageUrl,
    };
  }
}
