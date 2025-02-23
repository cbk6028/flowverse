class Book {
  int id;
  String name;
  String path;
  String image;

  Book(this.id, this.name, this.path, this.image);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'image': image,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        json['id'],
        json['name'],
        json['path'],
        json['image'],
      );
}
