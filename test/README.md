# Advertisement Accuracy Testing

This directory contains comprehensive tests for the advertisement system in your Flutter app.

## Test Structure

```
test/
├── advertisement_accuracy_test.dart      # Main accuracy tests
├── integration/
│   └── advertisement_integration_test.dart  # Integration tests
├── performance/
│   └── advertisement_performance_test.dart  # Performance tests
├── validation/
│   └── advertisement_validation_test.dart   # Data validation tests
└── README.md
```

## Running the Tests

### Prerequisites

First, install the required dependencies:

```bash
flutter pub get
```

### Generate Mock Files

Before running tests, generate the mock files:

```bash
flutter packages pub run build_runner build
```

### Run All Tests

```bash
flutter test
```

### Run Specific Test Categories

```bash
# Run only accuracy tests
flutter test test/advertisement_accuracy_test.dart

# Run only integration tests
flutter test test/integration/

# Run only performance tests
flutter test test/performance/

# Run only validation tests
flutter test test/validation/
```

### Run Tests with Coverage

```bash
flutter test --coverage
```

### Generate Coverage Report

```bash
# Install lcov if not already installed
# On Windows: choco install lcov
# On macOS: brew install lcov
# On Linux: sudo apt-get install lcov

genhtml coverage/lcov.info -o coverage/html
```

## Test Categories

### 1. Accuracy Tests (`advertisement_accuracy_test.dart`)

Tests the core functionality and accuracy of advertisement display:

- **Display Accuracy**: Verifies that advertisement data is displayed correctly
- **Input Validation**: Tests form validation and user input handling
- **Data Filtering**: Ensures businesses with ads are filtered correctly
- **Error Handling**: Tests graceful handling of missing or invalid data
- **Interaction Testing**: Verifies user interactions work as expected

### 2. Integration Tests (`integration/advertisement_integration_test.dart`)

Tests the complete advertisement workflow:

- **End-to-End Workflow**: Tests the complete advertisement creation and display flow
- **Business Data Integration**: Tests with realistic business data
- **Form Integration**: Tests advertisement manager with form validation
- **Navigation Integration**: Tests advertisement display with navigation
- **Data Persistence**: Tests advertisement data persistence

### 3. Performance Tests (`performance/advertisement_performance_test.dart`)

Tests performance and efficiency:

- **Loading Performance**: Ensures advertisements load within acceptable time
- **Large Dataset Handling**: Tests performance with many advertisements
- **Scrolling Performance**: Tests smooth scrolling through advertisements
- **Memory Efficiency**: Tests memory usage with large datasets
- **Image Loading**: Tests image loading performance
- **Rapid Interactions**: Tests handling of rapid user interactions

### 4. Validation Tests (`validation/advertisement_validation_test.dart`)

Tests data validation and integrity:

- **URL Validation**: Validates advertisement image URLs
- **Content Length**: Tests title and description length limits
- **Data Integrity**: Validates business advertisement data
- **Content Quality**: Tests advertisement content quality rules
- **Business Type Validation**: Ensures only businesses can have ads
- **Uniqueness Validation**: Tests advertisement uniqueness
- **Targeting Validation**: Tests location-based targeting

## Test Data

The tests use various types of test data:

- **Valid Business Data**: Complete business profiles with advertisements
- **Invalid Data**: Missing or malformed advertisement data
- **Edge Cases**: Empty lists, null values, extreme lengths
- **Performance Data**: Large datasets for performance testing

## Expected Results

### Accuracy Tests

- All advertisement data should display correctly
- Form validation should work properly
- Error handling should be graceful
- User interactions should function as expected

### Performance Tests

- Loading time should be < 100ms for 10 advertisements
- Large datasets (50+ ads) should load in < 500ms
- Scrolling should be smooth (< 2000ms for 5 scrolls)
- Memory usage should be efficient

### Validation Tests

- All validation rules should be enforced
- Invalid data should be rejected
- Quality checks should pass for good content
- Business type restrictions should be enforced

## Troubleshooting

### Common Issues

1. **Mock Generation Errors**

   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build
   ```

2. **Test Timeout Errors**

   - Increase timeout in test configuration
   - Check for infinite loops in test code

3. **Import Errors**
   - Ensure all dependencies are installed
   - Check import paths are correct

### Debugging Tests

To debug a specific test:

```bash
flutter test --verbose test/advertisement_accuracy_test.dart
```

To run tests in debug mode:

```bash
flutter test --debug test/advertisement_accuracy_test.dart
```

## Adding New Tests

When adding new tests:

1. **Follow Naming Convention**: Use descriptive test names
2. **Group Related Tests**: Use `group()` to organize related tests
3. **Use Arrange-Act-Assert**: Structure tests clearly
4. **Test Edge Cases**: Include boundary conditions
5. **Mock Dependencies**: Use mocks for external dependencies

Example:

```dart
testWidgets('should handle new advertisement feature', (WidgetTester tester) async {
  // Arrange
  final testData = createTestData();

  // Act
  await tester.pumpWidget(createTestWidget(testData));

  // Assert
  expect(find.text('Expected Result'), findsOneWidget);
});
```

## Continuous Integration

For CI/CD integration, add these commands to your pipeline:

```yaml
- name: Install dependencies
  run: flutter pub get

- name: Generate mocks
  run: flutter packages pub run build_runner build

- name: Run tests
  run: flutter test --coverage

- name: Generate coverage report
  run: genhtml coverage/lcov.info -o coverage/html
```

This comprehensive testing suite ensures your advertisement system is accurate, performant, and reliable across all scenarios.
