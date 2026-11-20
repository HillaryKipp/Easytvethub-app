import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_client.dart';
import '../../core/utils/formatters.dart';
import '../models/blog_models.dart';
import '../models/directory_models.dart';

class HomeDirectoryData {
  final List<Programme> programmes;
  final List<Department> departments;
  final List<Article> latestArticles;

  const HomeDirectoryData({
    required this.programmes,
    required this.departments,
    required this.latestArticles,
  });
}

class ProgrammeDetailData {
  final Programme programme;
  final List<Department> departments;

  const ProgrammeDetailData({
    required this.programme,
    required this.departments,
  });
}

class CourseDetailData {
  final Course course;
  final List<Course> otherLevelVariants;
  final List<Course> sameLevelDepartmentCourses;
  final List<Article> relatedArticles;

  const CourseDetailData({
    required this.course,
    required this.otherLevelVariants,
    required this.sameLevelDepartmentCourses,
    required this.relatedArticles,
  });
}

class UnitSiblingRef {
  final String name;
  final String slug;
  final int moduleNumber;

  const UnitSiblingRef({
    required this.name,
    required this.slug,
    required this.moduleNumber,
  });
}

class SharedCourseUnitRef {
  final String courseName;
  final String courseSlug;
  final int? level;
  final String departmentSlug;
  final String programmeSlug;
  final String unitSlug;

  const SharedCourseUnitRef({
    required this.courseName,
    required this.courseSlug,
    this.level,
    required this.departmentSlug,
    required this.programmeSlug,
    required this.unitSlug,
  });

  String get unitPath =>
      '/$programmeSlug/$departmentSlug/$courseSlug/$unitSlug';
}

class UnitDetailData {
  final UnitModel unit;
  final UnitSiblingRef? previousUnit;
  final UnitSiblingRef? nextUnit;
  final List<SharedCourseUnitRef> otherCourses;

  const UnitDetailData({
    required this.unit,
    this.previousUnit,
    this.nextUnit,
    this.otherCourses = const [],
  });
}

class DirectoryRepository {
  final SupabaseClient _client;

  DirectoryRepository(this._client);

  Future<HomeDirectoryData> getHomeData() async {
    final results = await Future.wait<dynamic>([
      _client
          .from('programmes')
          .select('id, name, slug, description, sort_order')
          .order('sort_order', ascending: true),
      _client
          .from('departments')
          .select(
            'id, programme_id, name, slug, sort_order, '
            'programme:programmes(id, name, slug, sort_order), '
            'courses(id, department_id, name, slug, level, published, updated_at)',
          )
          .order('sort_order', ascending: true),
      _client
          .from('articles')
          .select('*, author:authors(*)')
          .eq('published', true)
          .order('published_at', ascending: false)
          .limit(6),
    ]);

    final programmes = (results[0] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Programme.fromJson)
        .toList();

    final departments = (results[1] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Department.fromJson)
        .toList();

    final articles = (results[2] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Article.fromJson)
        .toList();

    return HomeDirectoryData(
      programmes: programmes,
      departments: departments,
      latestArticles: articles,
    );
  }

  Future<ProgrammeDetailData> getProgrammeBySlug(String programmeSlug) async {
    final progRow = await _client
        .from('programmes')
        .select('*')
        .eq('slug', programmeSlug)
        .single();

    final programme = Programme.fromJson(progRow);

    final deptRows = await _client
        .from('departments')
        .select(
          '*, courses(id, department_id, name, slug, level, published, updated_at, units(id))',
        )
        .eq('programme_id', programme.id)
        .order('sort_order', ascending: true);

    final departments = (deptRows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) {
          final dept = Department.fromJson(row);
          return Department(
            id: dept.id,
            programmeId: dept.programmeId,
            name: dept.name,
            slug: dept.slug,
            description: dept.description,
            intro: dept.intro,
            faq: dept.faq,
            sortOrder: dept.sortOrder,
            programme: programme,
            courses: dept.courses,
          );
        })
        .toList();

    return ProgrammeDetailData(
      programme: programme,
      departments: departments,
    );
  }

  Future<Department> getDepartmentBySlugs({
    required String programmeSlug,
    required String departmentSlug,
  }) async {
    final progRow = await _client
        .from('programmes')
        .select('*')
        .eq('slug', programmeSlug)
        .single();
    final programme = Programme.fromJson(progRow);

    final deptRow = await _client
        .from('departments')
        .select(
          '*, courses(id, department_id, name, slug, level, description, published, updated_at, units(id))',
        )
        .eq('programme_id', programme.id)
        .eq('slug', departmentSlug)
        .single();

    final dept = Department.fromJson(deptRow);
    return Department(
      id: dept.id,
      programmeId: dept.programmeId,
      name: dept.name,
      slug: dept.slug,
      description: dept.description,
      intro: dept.intro,
      faq: dept.faq,
      sortOrder: dept.sortOrder,
      programme: programme,
      courses: dept.courses,
    );
  }

  Future<List<Course>> getCoursesByLevel(int level) async {
    final rows = await _client
        .from('courses')
        .select(
          '*, department:departments(*, programme:programmes(*)), units(id)',
        )
        .eq('level', level)
        .eq('published', true)
        .order('name', ascending: true);

    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Course.fromJson)
        .toList();
  }

  Future<CourseDetailData> getCourseBySlugs({
    required String programmeSlug,
    required String departmentSlug,
    required String courseSlug,
  }) async {
    final progRow = await _client
        .from('programmes')
        .select('id')
        .eq('slug', programmeSlug)
        .single();
    final progId = progRow['id'] as String;

    final deptRow = await _client
        .from('departments')
        .select('id')
        .eq('programme_id', progId)
        .eq('slug', departmentSlug)
        .single();
    final deptId = deptRow['id'] as String;

    final courseRow = await _client
        .from('courses')
        .select(
          '*, '
          'department:departments(*, programme:programmes(*)), '
          'modules(*, units(*, resources(id)))',
        )
        .eq('department_id', deptId)
        .eq('slug', courseSlug)
        .eq('published', true)
        .single();

    final course = Course.fromJson(courseRow);

    // Fetch related courses in the same department + contextual revision articles
    final relatedResults = await Future.wait<dynamic>([
      _client
          .from('courses')
          .select(
            'id, department_id, name, slug, level, published, updated_at, '
            'department:departments(id, programme_id, name, slug, programme:programmes(id, name, slug)), '
            'units(id)',
          )
          .eq('department_id', deptId)
          .eq('published', true)
          .neq('id', course.id)
          .order('level', ascending: false),
      _client
          .from('articles')
          .select('*, author:authors(*)')
          .eq('published', true)
          .order('published_at', ascending: false)
          .limit(4),
    ]);

    final deptCourses = (relatedResults[0] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Course.fromJson)
        .toList();

    final baseName = _stripLevelSuffix(course.name);
    final otherLevels = deptCourses.where((c) {
      return c.level != course.level &&
          _stripLevelSuffix(c.name) == baseName;
    }).toList();

    final sameLevel = deptCourses
        .where((c) => c.level == course.level)
        .take(8)
        .toList();

    final articles = (relatedResults[1] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Article.fromJson)
        .toList();

    return CourseDetailData(
      course: course,
      otherLevelVariants: otherLevels,
      sameLevelDepartmentCourses: sameLevel,
      relatedArticles: articles,
    );
  }

  Future<UnitDetailData> getUnitBySlugs({
    required String programmeSlug,
    required String departmentSlug,
    required String courseSlug,
    required String unitSlug,
  }) async {
    final progRow = await _client
        .from('programmes')
        .select('id')
        .eq('slug', programmeSlug)
        .single();
    final progId = progRow['id'] as String;

    final deptRow = await _client
        .from('departments')
        .select('id')
        .eq('programme_id', progId)
        .eq('slug', departmentSlug)
        .single();
    final deptId = deptRow['id'] as String;

    final courseRow = await _client
        .from('courses')
        .select('id')
        .eq('department_id', deptId)
        .eq('slug', courseSlug)
        .eq('published', true)
        .single();
    final courseId = courseRow['id'] as String;

    final unitRow = await _client
        .from('units')
        .select(
          '*, '
          'module:modules(*), '
          'course:courses(*, department:departments(*, programme:programmes(*))), '
          'resources(*)',
        )
        .eq('course_id', courseId)
        .eq('slug', unitSlug)
        .eq('published', true)
        .single();

    final unit = UnitModel.fromJson(unitRow);

    // Fetch sibling units in the same course for Prev / Next navigation
    final siblingRows = await _client
        .from('modules')
        .select('module_number, units(id, name, slug, published)')
        .eq('course_id', courseId)
        .order('module_number', ascending: true);

    final orderedSiblings = <UnitSiblingRef>[];
    for (final m in (siblingRows as List<dynamic>).whereType<Map<String, dynamic>>()) {
      final modNum = (m['module_number'] as num?)?.toInt() ?? 1;
      final modUnits = (m['units'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .where((u) => (u['published'] as bool?) ?? true)
          .toList();
      for (final u in modUnits) {
        orderedSiblings.add(
          UnitSiblingRef(
            name: u['name'] as String? ?? '',
            slug: u['slug'] as String? ?? '',
            moduleNumber: modNum,
          ),
        );
      }
    }

    UnitSiblingRef? prevUnit;
    UnitSiblingRef? nextUnit;
    final currentIndex = orderedSiblings.indexWhere((u) => u.slug == unit.slug);
    if (currentIndex > 0) prevUnit = orderedSiblings[currentIndex - 1];
    if (currentIndex >= 0 && currentIndex < orderedSiblings.length - 1) {
      nextUnit = orderedSiblings[currentIndex + 1];
    }

    // Find other courses featuring this unit (via canonical_unit_id or unit_code/slug)
    final otherCourses = <SharedCourseUnitRef>[];
    try {
      final filterCol = unit.canonicalUnitId != null
          ? 'canonical_unit_id'
          : (unit.unitCode != null && unit.unitCode!.isNotEmpty
              ? 'unit_code'
              : 'slug');
      final filterVal = unit.canonicalUnitId ??
          (unit.unitCode != null && unit.unitCode!.isNotEmpty
              ? unit.unitCode!
              : unit.slug);

      final sharedRows = await _client
          .from('units')
          .select(
            'id, slug, course_id, '
            'course:courses(name, slug, level, published, '
            'department:departments(slug, programme:programmes(slug)))',
          )
          .eq(filterCol, filterVal)
          .eq('published', true)
          .neq('course_id', courseId)
          .limit(10);

      for (final row in (sharedRows as List<dynamic>).whereType<Map<String, dynamic>>()) {
        final c = row['course'];
        if (c is! Map<String, dynamic>) continue;
        if ((c['published'] as bool?) == false) continue;
        final d = c['department'];
        if (d is! Map<String, dynamic>) continue;
        final p = d['programme'];
        if (p is! Map<String, dynamic>) continue;

        otherCourses.add(
          SharedCourseUnitRef(
            courseName: c['name'] as String? ?? '',
            courseSlug: c['slug'] as String? ?? '',
            level: (c['level'] as num?)?.toInt(),
            departmentSlug: d['slug'] as String? ?? '',
            programmeSlug: p['slug'] as String? ?? '',
            unitSlug: row['slug'] as String? ?? unit.slug,
          ),
        );
      }
    } catch (_) {
      // Non-critical secondary query; gracefully skip if unavailable
    }

    return UnitDetailData(
      unit: unit,
      previousUnit: prevUnit,
      nextUnit: nextUnit,
      otherCourses: otherCourses,
    );
  }

  String _stripLevelSuffix(String courseName) {
    return toTitleCase(courseName)
        .toLowerCase()
        .replaceAll(RegExp(r'\blevel\s*[3-6]\b'), '')
        .replaceAll(RegExp(r'\b(diploma|certificate|artisan)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  return DirectoryRepository(ref.watch(supabaseClientProvider));
});

final homeDirectoryProvider = FutureProvider<HomeDirectoryData>((ref) async {
  return ref.watch(directoryRepositoryProvider).getHomeData();
});

final programmeDetailProvider =
    FutureProvider.family<ProgrammeDetailData, String>((ref, slug) async {
      return ref.watch(directoryRepositoryProvider).getProgrammeBySlug(slug);
    });

typedef DepartmentRouteKey = ({String programmeSlug, String departmentSlug});

final departmentDetailProvider =
    FutureProvider.family<Department, DepartmentRouteKey>((ref, key) async {
      return ref.watch(directoryRepositoryProvider).getDepartmentBySlugs(
        programmeSlug: key.programmeSlug,
        departmentSlug: key.departmentSlug,
      );
    });

final levelCoursesProvider = FutureProvider.family<List<Course>, int>((
  ref,
  level,
) async {
  return ref.watch(directoryRepositoryProvider).getCoursesByLevel(level);
});

typedef CourseRouteKey = ({
  String programmeSlug,
  String departmentSlug,
  String courseSlug,
});

final courseDetailProvider =
    FutureProvider.family<CourseDetailData, CourseRouteKey>((ref, key) async {
      return ref.watch(directoryRepositoryProvider).getCourseBySlugs(
        programmeSlug: key.programmeSlug,
        departmentSlug: key.departmentSlug,
        courseSlug: key.courseSlug,
      );
    });

typedef UnitRouteKey = ({
  String programmeSlug,
  String departmentSlug,
  String courseSlug,
  String unitSlug,
});

final unitDetailProvider =
    FutureProvider.family<UnitDetailData, UnitRouteKey>((ref, key) async {
      return ref.watch(directoryRepositoryProvider).getUnitBySlugs(
        programmeSlug: key.programmeSlug,
        departmentSlug: key.departmentSlug,
        courseSlug: key.courseSlug,
        unitSlug: key.unitSlug,
      );
    });
