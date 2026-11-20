enum ResourceType {
  cuttingList('cutting_list', 'Cutting List'),
  candidateTool('candidate_tool', 'Candidate Tool'),
  assessorGuide('assessor_guide', 'Assessor Guide'),
  pastPaper('past_paper', 'Past Paper'),
  markingScheme('marking_scheme', 'Marking Scheme'),
  other('other', 'Assessment Document');

  final String dbValue;
  final String label;
  const ResourceType(this.dbValue, this.label);

  static ResourceType fromDb(String? value) {
    return ResourceType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ResourceType.other,
    );
  }
}

class FaqItem {
  final String question;
  final String answer;
  const FaqItem({required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
      );
}

class Programme {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? intro;
  final List<FaqItem> faq;
  final int sortOrder;

  const Programme({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.intro,
    this.faq = const [],
    this.sortOrder = 0,
  });

  bool get isModular => slug.toLowerCase().contains('modular');
  bool get isKnec => slug.toLowerCase().contains('knec');

  factory Programme.fromJson(Map<String, dynamic> json) => Programme(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String?,
        intro: json['intro'] as String?,
        faq: _parseFaq(json['faq']),
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class Department {
  final String id;
  final String programmeId;
  final String name;
  final String slug;
  final String? description;
  final String? intro;
  final List<FaqItem> faq;
  final int sortOrder;
  final Programme? programme;
  final List<Course> courses;

  const Department({
    required this.id,
    required this.programmeId,
    required this.name,
    required this.slug,
    this.description,
    this.intro,
    this.faq = const [],
    this.sortOrder = 0,
    this.programme,
    this.courses = const [],
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id: json['id'] as String,
        programmeId: json['programme_id'] as String? ?? '',
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String?,
        intro: json['intro'] as String?,
        faq: _parseFaq(json['faq']),
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        programme: json['programme'] is Map<String, dynamic>
            ? Programme.fromJson(json['programme'] as Map<String, dynamic>)
            : null,
        courses: (json['courses'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Course.fromJson)
            .where((c) => c.published)
            .toList(),
      );
}

class Course {
  final String id;
  final String departmentId;
  final String name;
  final String slug;
  final int? level;
  final String? description;
  final String? intro;
  final List<FaqItem> faq;
  final bool published;
  final DateTime updatedAt;
  final Department? department;
  final List<CourseModule> modules;
  final int? unitCount;

  const Course({
    required this.id,
    required this.departmentId,
    required this.name,
    required this.slug,
    this.level,
    this.description,
    this.intro,
    this.faq = const [],
    this.published = true,
    required this.updatedAt,
    this.department,
    this.modules = const [],
    this.unitCount,
  });

  int get totalUnits {
    if (modules.isNotEmpty) {
      return modules.fold<int>(0, (sum, m) => sum + m.units.length);
    }
    return unitCount ?? 0;
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    final parsedModules = (json['modules'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CourseModule.fromJson)
        .toList()
      ..sort((a, b) => a.moduleNumber.compareTo(b.moduleNumber));

    int? derivedUnitCount;
    if (json['units'] is List) {
      derivedUnitCount = (json['units'] as List).length;
    }

    return Course(
      id: json['id'] as String,
      departmentId: json['department_id'] as String? ?? '',
      name: json['name'] as String,
      slug: json['slug'] as String,
      level: (json['level'] as num?)?.toInt(),
      description: json['description'] as String?,
      intro: json['intro'] as String?,
      faq: _parseFaq(json['faq']),
      published: json['published'] as bool? ?? true,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      department: json['department'] is Map<String, dynamic>
          ? Department.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      modules: parsedModules,
      unitCount: derivedUnitCount,
    );
  }
}

class CourseModule {
  final String id;
  final String courseId;
  final int moduleNumber;
  final String? title;
  final List<UnitModel> units;

  const CourseModule({
    required this.id,
    required this.courseId,
    required this.moduleNumber,
    this.title,
    this.units = const [],
  });

  factory CourseModule.fromJson(Map<String, dynamic> json) => CourseModule(
        id: json['id'] as String,
        courseId: json['course_id'] as String? ?? '',
        moduleNumber: (json['module_number'] as num?)?.toInt() ?? 1,
        title: json['title'] as String?,
        units: (json['units'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(UnitModel.fromJson)
            .where((u) => u.published)
            .toList(),
      );
}

class UnitModel {
  final String id;
  final String moduleId;
  final String courseId;
  final String name;
  final String slug;
  final String? unitCode;
  final String? description;
  final String? intro;
  final String? canonicalUnitId;
  final bool published;
  final DateTime updatedAt;
  final List<ResourceModel> resources;
  final CourseModule? module;
  final Course? course;

  const UnitModel({
    required this.id,
    required this.moduleId,
    required this.courseId,
    required this.name,
    required this.slug,
    this.unitCode,
    this.description,
    this.intro,
    this.canonicalUnitId,
    this.published = true,
    required this.updatedAt,
    this.resources = const [],
    this.module,
    this.course,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    final parsedResources = (json['resources'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ResourceModel.fromJson)
        .toList();
    parsedResources.sort(ResourceModel.compare);

    return UnitModel(
      id: json['id'] as String,
      moduleId: json['module_id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      name: json['name'] as String,
      slug: json['slug'] as String,
      unitCode: json['unit_code'] as String?,
      description: json['description'] as String?,
      intro: json['intro'] as String?,
      canonicalUnitId: json['canonical_unit_id'] as String?,
      published: json['published'] as bool? ?? true,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      resources: parsedResources,
      module: json['module'] is Map<String, dynamic>
          ? CourseModule.fromJson(json['module'] as Map<String, dynamic>)
          : null,
      course: json['course'] is Map<String, dynamic>
          ? Course.fromJson(json['course'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ResourceModel {
  final String id;
  final String unitId;
  final ResourceType type;
  final String? title;
  final String fileUrl;
  final int? year;
  final int sortOrder;

  const ResourceModel({
    required this.id,
    required this.unitId,
    required this.type,
    this.title,
    required this.fileUrl,
    this.year,
    this.sortOrder = 0,
  });

  /// Sorts by sort_order ASC, then year DESC (exact parity with lib/data.ts).
  static int compare(ResourceModel a, ResourceModel b) {
    final orderCmp = a.sortOrder.compareTo(b.sortOrder);
    if (orderCmp != 0) return orderCmp;
    return (b.year ?? 0).compareTo(a.year ?? 0);
  }

  /// Display title matching web: explicit title or `{unitName} - {year} {typeLabel}`.
  String displayTitle(String unitName) {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    final parts = <String>[
      if (year != null) '$year',
      type.label,
    ];
    return '$unitName - ${parts.join(' ')}';
  }

  factory ResourceModel.fromJson(Map<String, dynamic> json) => ResourceModel(
        id: json['id'] as String,
        unitId: json['unit_id'] as String? ?? '',
        type: ResourceType.fromDb(json['type'] as String?),
        title: json['title'] as String?,
        fileUrl: json['file_url'] as String? ?? '',
        year: (json['year'] as num?)?.toInt(),
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}

List<FaqItem> _parseFaq(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(FaqItem.fromJson)
      .where((item) => item.question.isNotEmpty)
      .toList();
}
