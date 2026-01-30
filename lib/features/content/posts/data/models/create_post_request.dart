class CreatePostRequest {
  final int type;
  final String text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int visibility;

  CreatePostRequest({
    required this.type,
    required this.text,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.visibility,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'visibility': visibility,
    };
  }
}
