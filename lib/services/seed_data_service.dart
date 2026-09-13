import 'package:drift/drift.dart';

import '../core/utils/password_utils.dart';
import '../database/app_database.dart';

class SeedDataService {
  final AppDatabase _db;

  SeedDataService(this._db);

  Future<void> seedIfEmpty() async {
    final schools = await _db.select(_db.schools).get();
    if (schools.isNotEmpty) return;

    await _db.transaction(() async {
      final schoolId = await _db.into(_db.schools).insert(
            SchoolsCompanion.insert(
              name: 'Sunrise Public School',
              address: const Value('123 Main Street, Springfield'),
              phone: const Value('+1-555-0100'),
              email: const Value('info@sunriseschool.example'),
            ),
          );

      final adminHash = PasswordUtils.hashPassword('admin123');
      await _db.into(_db.admins).insert(
            AdminsCompanion.insert(
              name: 'School Administrator',
              username: 'admin',
              passwordHash: adminHash,
              schoolId: schoolId,
            ),
          );

      final teacherHash = PasswordUtils.hashPassword('teacher123');
      final teacher1Id = await _db.into(_db.teachers).insert(
            TeachersCompanion.insert(
              name: 'Ms. Anjali Sharma',
              username: 'sharma',
              passwordHash: teacherHash,
              phone: const Value('+1-555-0101'),
              email: const Value('sharma@sunriseschool.example'),
              schoolId: schoolId,
            ),
          );
      final teacher2Id = await _db.into(_db.teachers).insert(
            TeachersCompanion.insert(
              name: 'Mr. Rajesh Verma',
              username: 'verma',
              passwordHash: teacherHash,
              phone: const Value('+1-555-0102'),
              email: const Value('verma@sunriseschool.example'),
              schoolId: schoolId,
            ),
          );
      final teacher3Id = await _db.into(_db.teachers).insert(
            TeachersCompanion.insert(
              name: 'Mrs. Kavita Singh',
              username: 'singh',
              passwordHash: teacherHash,
              phone: const Value('+1-555-0103'),
              email: const Value('singh@sunriseschool.example'),
              schoolId: schoolId,
            ),
          );

      final class8Id =
          await _db.into(_db.classes).insert(
                ClassesCompanion.insert(name: '8', schoolId: schoolId),
              );
      final class9Id =
          await _db.into(_db.classes).insert(
                ClassesCompanion.insert(name: '9', schoolId: schoolId),
              );
      final class10Id =
          await _db.into(_db.classes).insert(
                ClassesCompanion.insert(name: '10', schoolId: schoolId),
              );

      final div8aId =
          await _db.into(_db.divisions).insert(
                DivisionsCompanion.insert(
                  name: 'A',
                  classId: class8Id,
                  schoolId: schoolId,
                ),
              );
      final div8bId =
          await _db.into(_db.divisions).insert(
                DivisionsCompanion.insert(
                  name: 'B',
                  classId: class8Id,
                  schoolId: schoolId,
                ),
              );
      final div9aId =
          await _db.into(_db.divisions).insert(
                DivisionsCompanion.insert(
                  name: 'A',
                  classId: class9Id,
                  schoolId: schoolId,
                ),
              );
      final div10aId =
          await _db.into(_db.divisions).insert(
                DivisionsCompanion.insert(
                  name: 'A',
                  classId: class10Id,
                  schoolId: schoolId,
                ),
              );

      await _db.into(_db.teacherClassAssignments).insert(
            TeacherClassAssignmentsCompanion.insert(
              teacherId: teacher1Id,
              classId: class8Id,
              divisionId: div8aId,
              schoolId: schoolId,
            ),
          );
      await _db.into(_db.teacherClassAssignments).insert(
            TeacherClassAssignmentsCompanion.insert(
              teacherId: teacher1Id,
              classId: class9Id,
              divisionId: div9aId,
              schoolId: schoolId,
            ),
          );
      await _db.into(_db.teacherClassAssignments).insert(
            TeacherClassAssignmentsCompanion.insert(
              teacherId: teacher2Id,
              classId: class8Id,
              divisionId: div8bId,
              schoolId: schoolId,
            ),
          );
      await _db.into(_db.teacherClassAssignments).insert(
            TeacherClassAssignmentsCompanion.insert(
              teacherId: teacher3Id,
              classId: class10Id,
              divisionId: div10aId,
              schoolId: schoolId,
            ),
          );

      final students8a = <({String name, String roll, String gender, DateTime dob})>[
        (name: 'Rahul Patel',    roll: '101', gender: 'Male',   dob: DateTime(2012, 5, 12)),
        (name: 'Priya Sharma',   roll: '102', gender: 'Female', dob: DateTime(2012, 8, 3)),
        (name: 'Amit Kumar',     roll: '103', gender: 'Male',   dob: DateTime(2011, 11, 21)),
        (name: 'Sneha Reddy',    roll: '104', gender: 'Female', dob: DateTime(2012, 1, 15)),
        (name: 'Vikram Singh',   roll: '105', gender: 'Male',   dob: DateTime(2012, 7, 7)),
        (name: 'Ananya Gupta',   roll: '106', gender: 'Female', dob: DateTime(2011, 9, 19)),
        (name: 'Rohan Mehta',    roll: '107', gender: 'Male',   dob: DateTime(2012, 3, 28)),
        (name: 'Isha Verma',     roll: '108', gender: 'Female', dob: DateTime(2012, 10, 11)),
        (name: 'Karan Joshi',    roll: '109', gender: 'Male',   dob: DateTime(2012, 6, 2)),
        (name: 'Meera Nair',     roll: '110', gender: 'Female', dob: DateTime(2012, 2, 14)),
        (name: 'Arjun Malhotra', roll: '111', gender: 'Male',   dob: DateTime(2011, 12, 25)),
        (name: 'Divya Rao',      roll: '112', gender: 'Female', dob: DateTime(2012, 4, 9)),
        (name: 'Siddharth Chawla', roll: '113', gender: 'Male',   dob: DateTime(2012, 8, 30)),
        (name: 'Nisha Kapoor',   roll: '114', gender: 'Female', dob: DateTime(2012, 1, 18)),
        (name: 'Aditya Bansal',  roll: '115', gender: 'Male',   dob: DateTime(2012, 9, 5)),
      ];

      final students9a = <({String name, String roll, String gender, DateTime dob})>[
        (name: 'Aarav Gupta',    roll: '101', gender: 'Male',   dob: DateTime(2011, 6, 14)),
        (name: 'Diya Patel',     roll: '102', gender: 'Female', dob: DateTime(2011, 9, 22)),
        (name: 'Kabir Shah',     roll: '103', gender: 'Male',   dob: DateTime(2011, 3, 8)),
        (name: 'Anika Joshi',    roll: '104', gender: 'Female', dob: DateTime(2011, 12, 30)),
        (name: 'Reyansh Kumar',  roll: '105', gender: 'Male',   dob: DateTime(2011, 7, 17)),
        (name: 'Aadhya Iyer',    roll: '106', gender: 'Female', dob: DateTime(2011, 10, 4)),
        (name: 'Vivaan Rao',     roll: '107', gender: 'Male',   dob: DateTime(2011, 5, 21)),
        (name: 'Sara Singh',     roll: '108', gender: 'Female', dob: DateTime(2011, 2, 11)),
        (name: 'Arnav Malhotra', roll: '109', gender: 'Male',   dob: DateTime(2011, 8, 15)),
        (name: 'Myra Mehra',     roll: '110', gender: 'Female', dob: DateTime(2011, 1, 27)),
      ];

      for (final s in students8a) {
        final studentId = await _db.into(_db.students).insert(
              StudentsCompanion.insert(
                name: s.name,
                rollNumber: s.roll,
                gender: Value(s.gender),
                dateOfBirth: Value(s.dob),
                divisionId: div8aId,
                schoolId: schoolId,
              ),
            );
        await _db.into(_db.parentGuardians).insert(
              ParentGuardiansCompanion.insert(
                name: 'Guardian of ${s.name}',
                phone: '+1-555-0${100 + (s.gender == 'Male' ? 0 : 1) + students8a.indexOf(s) * 2}',
                relationship: s.gender == 'Male' ? 'Father' : 'Mother',
                studentId: studentId,
              ),
            );
      }

      for (final s in students9a) {
        final studentId = await _db.into(_db.students).insert(
              StudentsCompanion.insert(
                name: s.name,
                rollNumber: s.roll,
                gender: Value(s.gender),
                dateOfBirth: Value(s.dob),
                divisionId: div9aId,
                schoolId: schoolId,
              ),
            );
        await _db.into(_db.parentGuardians).insert(
              ParentGuardiansCompanion.insert(
                name: 'Guardian of ${s.name}',
                phone: '+1-555-0${200 + (s.gender == 'Male' ? 0 : 1) + students9a.indexOf(s) * 2}',
                relationship: s.gender == 'Male' ? 'Father' : 'Mother',
                studentId: studentId,
              ),
            );
      }
    });
  }
}