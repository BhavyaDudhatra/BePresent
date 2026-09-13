import 'package:drift/drift.dart';

class Schools extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
}

class Admins extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();
  TextColumn get passwordHash => text()();
  TextColumn get pin => text().nullable()();
  IntColumn get schoolId => integer().references(Schools, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
}

class Teachers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();
  TextColumn get passwordHash => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(Constant(true))();
  IntColumn get schoolId => integer().references(Schools, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
}

class Classes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get section => text().nullable()();
  IntColumn get schoolId => integer().references(Schools, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
}

class Divisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get schoolId => integer().references(Schools, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  List<Set<Column>> get uniqueKeys => [{name, classId}];
}

class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get rollNumber => text().withLength(min: 1, max: 20)();
  TextColumn get gender => text().nullable()();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  IntColumn get divisionId => integer().references(Divisions, #id)();
  IntColumn get schoolId => integer().references(Schools, #id)();
  BoolColumn get isActive => boolean().withDefault(Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  List<Set<Column>> get uniqueKeys => [{rollNumber, divisionId}];
}

class ParentGuardians extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().withLength(min: 10, max: 15)();
  TextColumn get relationship => text().withLength(min: 1, max: 50)();
  BoolColumn get isPrimary => boolean().withDefault(Constant(true))();
  IntColumn get studentId => integer().references(Students, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
}

class AttendanceStatuses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 20).unique()();
  TextColumn get label => text()();
  TextColumn get color => text()();
}

class Attendances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer().references(Students, #id)();
  IntColumn get statusId => integer().references(AttendanceStatuses, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get teacherId => integer().references(Teachers, #id)();
  TextColumn get remarks => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  List<Set<Column>> get uniqueKeys => [{studentId, date}];
}

class TeacherClassAssignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get teacherId => integer().references(Teachers, #id)();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get divisionId => integer().references(Divisions, #id)();
  IntColumn get schoolId => integer().references(Schools, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  List<Set<Column>> get uniqueKeys => [{teacherId, classId, divisionId}];
}

class HomeworkAssignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get teacherId => integer().references(Teachers, #id)();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get divisionId => integer().references(Divisions, #id)();
  IntColumn get schoolId => integer().references(Schools, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  List<Set<Column>> get uniqueKeys => [{teacherId, classId, divisionId, title, dueDate}];
}

class HomeworkSubmissions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assignmentId =>
      integer().references(HomeworkAssignments, #id)();
  IntColumn get studentId => integer().references(Students, #id)();
  TextColumn get submissionText => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get attachmentName => text().nullable()();
  TextColumn get feedback => text().nullable()();
  DateTimeColumn get feedbackAt => dateTime().nullable()();
  DateTimeColumn get submittedAt => dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  List<Set<Column>> get uniqueKeys => [{assignmentId, studentId}];
}

class Settings extends Table {
  TextColumn get key => text().withLength(min: 1, max: 100)();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
