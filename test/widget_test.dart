import 'package:dio/dio.dart';
import 'package:easytvethub/core/config/env.dart';
import 'package:easytvethub/core/theme/app_colors.dart';
import 'package:easytvethub/core/theme/app_theme.dart';
import 'package:easytvethub/core/utils/drive_link_helper.dart';
import 'package:easytvethub/core/utils/formatters.dart';
import 'package:easytvethub/data/models/directory_models.dart';
import 'package:easytvethub/data/models/search_document.dart';
import 'package:easytvethub/data/repositories/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain formatters', () {
    test('toTitleCase preserves TVET acronyms and minor words', () {
      expect(
        toTitleCase('ict and cdacc past papers for tvet'),
        'ICT and CDACC Past Papers for TVET',
      );
      expect(
        toTitleCase('hiv/aids awareness and ohs with ppe'),
        'HIV/AIDS Awareness and OHS with PPE',
      );
      expect(
        toTitleCase('ui/ux design and gis mapping in knec'),
        'UI/UX Design and GIS Mapping in KNEC',
      );
    });

    test('getKnecTierName maps KNQF levels accurately', () {
      expect(getKnecTierName(6), 'Diploma');
      expect(getKnecTierName(5), 'Certificate');
      expect(getKnecTierName(4), 'Artisan');
      expect(getKnecTierName(3), 'Level 3');
    });

    test('normalizeDepartmentName merges equivalent department names', () {
      expect(
        normalizeDepartmentName('Applied Sciences Department'),
        'APPLIED SCIENCE',
      );
      expect(
        normalizeDepartmentName('  APPLIED SCIENCE  '),
        'APPLIED SCIENCE',
      );
    });
  });

  group('DriveLinkHelper', () {
    test('converts Google Drive /file/d/ and /open?id= share URLs', () {
      expect(
        DriveLinkHelper.toDirectDownloadUrl(
          'https://drive.google.com/file/d/1AbC_dEf234/view?usp=sharing',
        ),
        'https://drive.google.com/uc?export=download&id=1AbC_dEf234',
      );
      expect(
        DriveLinkHelper.toDirectDownloadUrl(
          'https://drive.google.com/open?id=9XyZ-12345',
        ),
        'https://drive.google.com/uc?export=download&id=9XyZ-12345',
      );
      expect(
        DriveLinkHelper.toDirectDownloadUrl(
          'https://easytvethub.com/files/sample.pdf',
        ),
        'https://easytvethub.com/files/sample.pdf',
      );
    });

    test('detects HTML Content-Type for Drive interstitial fallback', () {
      expect(
        DriveLinkHelper.isHtmlContentType('text/html; charset=utf-8'),
        isTrue,
      );
      expect(DriveLinkHelper.isHtmlContentType('application/pdf'), isFalse);
    });
  });

  group('ResourceModel sorting', () {
    test('sorts by sort_order ASC then year DESC', () {
      final list = [
        const ResourceModel(
          id: '1',
          unitId: 'u1',
          type: ResourceType.pastPaper,
          fileUrl: 'https://example.com/1.pdf',
          year: 2022,
          sortOrder: 2,
        ),
        const ResourceModel(
          id: '2',
          unitId: 'u1',
          type: ResourceType.pastPaper,
          fileUrl: 'https://example.com/2.pdf',
          year: 2023,
          sortOrder: 1,
        ),
        const ResourceModel(
          id: '3',
          unitId: 'u1',
          type: ResourceType.pastPaper,
          fileUrl: 'https://example.com/3.pdf',
          year: 2025,
          sortOrder: 1,
        ),
      ]..sort(ResourceModel.compare);

      expect(list.map((r) => r.id).toList(), ['3', '2', '1']);
    });
  });

  group('SearchRepository filtering & ranking', () {
    final repo = SearchRepository(Dio());
    const docs = [
      SearchDocument(
        id: 'c1',
        type: 'course',
        name: 'ICT Technician Level 6',
        level: 6,
        path: '/modular-cdacc-courses-cycle-3/ict/ict-technician-level-6/',
        breadcrumb: 'Modular CDACC > ICT',
      ),
      SearchDocument(
        id: 'u1',
        type: 'unit',
        name: 'Computer Networking',
        code: 'ICT/CU/IT/CR/01/6/A',
        level: 6,
        path: '/modular-cdacc-courses-cycle-3/ict/ict-technician-level-6/computer-networking/',
        breadcrumb: 'Modular CDACC > ICT > ICT Technician Level 6',
        resourceCount: 4,
      ),
      SearchDocument(
        id: 'u2',
        type: 'unit',
        name: 'Electrical Installation',
        code: 'ENG/CU/EL/CR/02/4/A',
        level: 4,
        path: '/knec-courses/electrical/artisan-electrical/electrical-installation/',
        breadcrumb: 'KNEC > Electrical > Artisan Electrical',
        resourceCount: 2,
      ),
    ];

    test('filters by type and level', () {
      final unitsL6 = repo.search(
        docs: docs,
        query: '',
        typeFilter: 'unit',
        levelFilter: 6,
      );
      expect(unitsL6.length, 1);
      expect(unitsL6.first.id, 'u1');
    });

    test('ranks exact/prefix name matches above breadcrumb matches', () {
      final results = repo.search(docs: docs, query: 'ICT');
      expect(results.first.id, 'c1');
      expect(results.length, 2);
    });
  });

  test('AppTheme and Env configuration tokens are valid', () {
    expect(AppColors.purple.toARGB32(), 0xFF662C91);
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.surface);
    expect(Env.isConfigured, isTrue);
  });
}
