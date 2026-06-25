class DiaryImage {
  final int? diaryImageId;
  final int diaryId;
  final String diaryImageUrl;
  final int diaryImageOrder;
  final bool diaryImageIsRepresentative;
  final String? diaryImageCreatedAt;

  const DiaryImage({
    this.diaryImageId,
    required this.diaryId,
    required this.diaryImageUrl,
    required this.diaryImageOrder,
    required this.diaryImageIsRepresentative,
    this.diaryImageCreatedAt,
  });

  factory DiaryImage.fromJson(Map<String, dynamic> json) {
    return DiaryImage(
      diaryImageId: json['diaryImageId'] ?? json['DIARY_IMAGE_ID'],
      diaryId: json['diaryId'] ?? json['DIARY_ID'],
      diaryImageUrl: json['diaryImageUrl'] ?? json['DIARY_IMAGE_URL'] ?? '',
      diaryImageOrder:
          json['diaryImageOrder'] ?? json['DIARY_IMAGE_ORDER'] ?? 0,
      diaryImageIsRepresentative:
          json['diaryImageIsRepresentative'] ??
          json['DIARY_IMAGE_IS_REPRESENTATIVE'] ??
          false,
      diaryImageCreatedAt:
          json['diaryImageCreatedAt'] ?? json['DIARY_IMAGE_CREATED_AT'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (diaryImageId != null) 'diaryImageId': diaryImageId,
      'diaryId': diaryId,
      'diaryImageUrl': diaryImageUrl,
      'diaryImageOrder': diaryImageOrder,
      'diaryImageIsRepresentative': diaryImageIsRepresentative,
    };
  }
}
