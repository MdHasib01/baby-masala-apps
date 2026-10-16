import '../../core/utils/json.dart';

/// Age groups shared by recipes, age tips and child age calculation.
const ageGroups = ['under_6m', '6_8m', '9_12m', '1_2y', '2y_plus'];

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.ageGroup,
    required this.ageGroupLabel,
    required this.image,
    this.videoUrl,
    required this.prepTime,
    this.ingredients = const [],
    this.steps = const [],
    this.textureNotes = '',
    this.allergens = '',
    this.shopProductId,
    this.saved = false,
  });

  final String id;
  final String title;
  final String ageGroup;
  final String ageGroupLabel;
  final String image;
  final String? videoUrl;
  final String prepTime;
  final List<String> ingredients;
  final List<String> steps;
  final String textureNotes;
  final String allergens;
  final String? shopProductId;
  final bool saved;

  factory Recipe.fromJson(Json j) => Recipe(
        id: jStr(j, 'id'),
        title: jStr(j, 'title'),
        ageGroup: jStr(j, 'ageGroup'),
        ageGroupLabel: jStr(j, 'ageGroupLabel'),
        image: jStr(j, 'image'),
        videoUrl: jStrN(j, 'videoUrl'),
        prepTime: jStr(j, 'prepTime'),
        ingredients: jStrList(j, 'ingredients'),
        steps: jStrList(j, 'steps'),
        textureNotes: jStr(j, 'textureNotes'),
        allergens: jStr(j, 'allergens'),
        shopProductId: jStrN(j, 'shopProductId'),
        saved: jBool(j, 'saved'),
      );
}
