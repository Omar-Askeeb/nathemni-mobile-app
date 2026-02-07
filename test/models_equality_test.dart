import 'package:flutter_test/flutter_test.dart';
import 'package:nathemni/features/people/data/person_model.dart';
import 'package:nathemni/features/commitments/data/commitment_model.dart';

void main() {
  group('PersonModel Equality', () {
    test('Two PersonModel instances with same properties should be equal', () {
      final person1 = PersonModel(
        id: 1,
        userId: 1,
        name: 'Person A',
        phone: '123456789',
        email: 'person@test.com',
        type: 'friend',
        notes: 'test note',
        syncStatus: 'pending',
      );

      final person2 = PersonModel(
        id: 1,
        userId: 1,
        name: 'Person A',
        phone: '123456789',
        email: 'person@test.com',
        type: 'friend',
        notes: 'test note',
        syncStatus: 'pending',
      );

      expect(person1, equals(person2));
      expect(person1.hashCode, equals(person2.hashCode));
    });

    test('Two PersonModel instances with different properties should not be equal', () {
      final person1 = PersonModel(
        id: 1,
        userId: 1,
        name: 'Person A',
      );

      final person2 = PersonModel(
        id: 2,
        userId: 1,
        name: 'Person B',
      );

      expect(person1, isNot(equals(person2)));
    });
  });

  group('CommitmentModel Equality', () {
    test('Two CommitmentModel instances with same properties should be equal', () {
      final now = DateTime.now();
      final commitment1 = CommitmentModel(
        id: 1,
        userId: 1,
        personId: 2,
        title: 'Debt 1',
        amount: 100.0,
        type: 'debt_to_me',
        dueDate: now,
        status: 'pending',
      );

      final commitment2 = CommitmentModel(
        id: 1,
        userId: 1,
        personId: 2,
        title: 'Debt 1',
        amount: 100.0,
        type: 'debt_to_me',
        dueDate: now,
        status: 'pending',
      );

      expect(commitment1, equals(commitment2));
      expect(commitment1.hashCode, equals(commitment2.hashCode));
    });
  });
}
