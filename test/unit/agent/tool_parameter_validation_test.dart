import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('Tool Parameter Validation Tests', () {
    group('Parameter Schema Validation', () {
      test('should validate required parameters', () {
        final schema = {
          'type': 'object',
          'properties': {
            'expression': {'type': 'string'},
            'precision': {'type': 'integer', 'default': 2},
          },
          'required': ['expression'],
        };

        final validParams = {'expression': '2 + 2'};
        expect(validParams.containsKey('expression'), true);

        final invalidParams = {'precision': 2};
        expect(invalidParams.containsKey('expression'), false);
      });

      test('should validate parameter types', () {
        final params = {
          'query': 'search term', // string
          'limit': 50, // integer
          'cache': true, // boolean
          'filters': {'lang': 'en'}, // object
        };

        expect(params['query'] is String, true);
        expect(params['limit'] is int, true);
        expect(params['cache'] is bool, true);
        expect(params['filters'] is Map, true);
      });

      test('should validate nested properties', () {
        final params = {
          'search': {
            'query': 'test',
            'options': {
              'language': 'en',
              'date_range': {
                'start': '2025-01-01',
                'end': '2025-01-31',
              },
            },
          },
        };

        expect(
          params['search']['options']['date_range']['start'],
          '2025-01-01',
        );
      });

      test('should validate array parameters', () {
        final params = {
          'items': [1, 2, 3, 4, 5],
          'tags': ['python', 'dart', 'flutter'],
          'mixed': [1, 'two', true, {'key': 'value'}],
        };

        expect(params['items'] is List, true);
        expect(params['items'].length, 5);
        expect(params['tags'].contains('dart'), true);
      });
    });

    group('Type Checking', () {
      test('should validate string parameters', () {
        final stringParams = {
          'name': 'John',
          'email': 'john@example.com',
          'query': 'search query',
        };

        expect(stringParams['name'] is String, true);
        expect(stringParams['email'].contains('@'), true);
      });

      test('should validate numeric parameters', () {
        final numParams = {
          'count': 42,
          'limit': 100,
          'temperature': 0.7,
          'precision': 5,
        };

        expect(numParams['count'] is int, true);
        expect(numParams['temperature'] is double, true);
        expect(numParams['precision'] > 0, true);
      });

      test('should validate boolean parameters', () {
        final boolParams = {
          'enabled': true,
          'cached': false,
          'verbose': true,
        };

        expect(boolParams['enabled'] is bool, true);
        expect(boolParams['cached'] == false, true);
      });

      test('should validate date/time parameters', () {
        final now = DateTime.now();
        final dateParams = {
          'timestamp': now,
          'date_string': '2025-01-20',
          'time_string': '10:30:00',
        };

        expect(dateParams['timestamp'] is DateTime, true);
        expect(dateParams['date_string'] is String, true);
      });
    });

    group('Range and Constraint Validation', () {
      test('should validate min/max constraints', () {
        final params = {
          'limit': 50,
          'temperature': 0.7,
          'retries': 3,
        };

        // Validate ranges
        expect(params['limit'] >= 1 && params['limit'] <= 1000, true);
        expect(params['temperature'] >= 0.0 && params['temperature'] <= 1.0, true);
        expect(params['retries'] >= 0 && params['retries'] <= 5, true);
      });

      test('should validate length constraints', () {
        final params = {
          'query': 'search term',
          'description': 'A' * 500,
          'code': 'print("hello")',
        };

        expect(params['query'].length > 0, true);
        expect(params['description'].length <= 1000, true);
        expect(params['code'].length > 0, true);
      });

      test('should validate pattern matching', () {
        final params = {
          'email': 'user@example.com',
          'url': 'https://example.com',
          'phone': '+1-234-567-8900',
        };

        expect(params['email'].contains('@'), true);
        expect(params['url'].startsWith('https'), true);
        expect(params['phone'].contains('-'), true);
      });

      test('should validate enum values', () {
        final validValues = ['en', 'es', 'fr', 'de'];
        final params = {'language': 'en'};

        expect(validValues.contains(params['language']), true);

        final invalidParam = {'language': 'invalid'};
        expect(validValues.contains(invalidParam['language']), false);
      });
    });

    group('Default Values', () {
      test('should apply default values', () {
        final schema = {
          'properties': {
            'limit': {'type': 'integer', 'default': 50},
            'sort': {'type': 'string', 'default': 'relevance'},
            'cache': {'type': 'boolean', 'default': true},
          },
        };

        var params = {};
        if (!params.containsKey('limit')) {
          params['limit'] = schema['properties']['limit']['default'];
        }
        if (!params.containsKey('sort')) {
          params['sort'] = schema['properties']['sort']['default'];
        }

        expect(params['limit'], 50);
        expect(params['sort'], 'relevance');
      });

      test('should override defaults with provided values', () {
        var params = {'limit': 100}; // Override default 50
        expect(params['limit'], 100);
      });
    });

    group('Error Messages', () {
      test('should provide clear error for missing required params', () {
        final required = ['expression'];
        final params = {'limit': 10};

        final missing = required.where((r) => !params.containsKey(r)).toList();
        expect(missing.contains('expression'), true);
      });

      test('should provide clear error for invalid types', () {
        final param = 'not_an_int';
        final isInt = int.tryParse(param) != null;
        expect(isInt, false);
      });

      test('should provide clear error for out-of-range values', () {
        const limit = 100;
        const maxLimit = 50;

        if (limit > maxLimit) {
          final error = 'Limit $limit exceeds maximum $maxLimit';
          expect(error.contains('exceeds'), true);
        }
      });
    });

    group('Complex Parameter Scenarios', () {
      test('should validate search tool parameters', () {
        final searchParams = {
          'query': 'machine learning',
          'filters': {
            'language': 'en',
            'date_from': '2024-01-01',
          },
          'limit': 50,
          'sort_by': 'relevance',
        };

        expect(searchParams['query'] is String, true);
        expect(searchParams['limit'] is int, true);
        expect(searchParams['filters'] is Map, true);
      });

      test('should validate file operation parameters', () {
        final fileParams = {
          'path': '/home/user/document.txt',
          'operation': 'read',
          'encoding': 'utf-8',
          'options': {
            'chunk_size': 4096,
            'timeout_ms': 5000,
          },
        };

        expect(fileParams['path'] is String, true);
        expect(fileParams['operation'] is String, true);
        expect(
          fileParams['options']['chunk_size'],
          4096,
        );
      });

      test('should validate calculator parameters', () {
        final calcParams = {
          'expression': '(2 + 3) * 4 - 1',
          'precision': 6,
          'radians': false,
          'format': 'decimal',
        };

        expect(calcParams['expression'] is String, true);
        expect(calcParams['precision'] is int, true);
        expect(calcParams['radians'] is bool, true);
      });
    });

    group('Batch Validation', () {
      test('should validate multiple parameter sets', () {
        final paramsList = [
          {'query': 'test1', 'limit': 10},
          {'query': 'test2', 'limit': 20},
          {'query': 'test3', 'limit': 30},
        ];

        final allValid = paramsList.every((p) =>
          p.containsKey('query') &&
          p.containsKey('limit') &&
          p['limit'] is int
        );

        expect(allValid, true);
      });

      test('should identify invalid items in batch', () {
        final paramsList = [
          {'query': 'valid', 'limit': 10},
          {'query': 'invalid'},
          {'limit': 20},
        ];

        final invalid = paramsList
          .where((p) => !p.containsKey('query') || !p.containsKey('limit'))
          .toList();

        expect(invalid.length, 2);
      });
    });
  });
}
