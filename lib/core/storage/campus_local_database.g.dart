// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campus_local_database.dart';

// ignore_for_file: type=lint
class $AttendanceDraftRowsTable extends AttendanceDraftRows
    with TableInfo<$AttendanceDraftRowsTable, AttendanceDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceDraftRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _payloadVersionMeta = const VerificationMeta(
    'payloadVersion',
  );
  @override
  late final GeneratedColumn<int> payloadVersion = GeneratedColumn<int>(
    'payload_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _membershipIdMeta = const VerificationMeta(
    'membershipId',
  );
  @override
  late final GeneratedColumn<String> membershipId = GeneratedColumn<String>(
    'membership_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _institutionIdMeta = const VerificationMeta(
    'institutionId',
  );
  @override
  late final GeneratedColumn<String> institutionId = GeneratedColumn<String>(
    'institution_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectionKeyMeta = const VerificationMeta(
    'selectionKey',
  );
  @override
  late final GeneratedColumn<String> selectionKey = GeneratedColumn<String>(
    'selection_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseOfferingIdMeta = const VerificationMeta(
    'courseOfferingId',
  );
  @override
  late final GeneratedColumn<String> courseOfferingId = GeneratedColumn<String>(
    'course_offering_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timetableEntryIdMeta = const VerificationMeta(
    'timetableEntryId',
  );
  @override
  late final GeneratedColumn<String> timetableEntryId = GeneratedColumn<String>(
    'timetable_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectCodeMeta = const VerificationMeta(
    'subjectCode',
  );
  @override
  late final GeneratedColumn<String> subjectCode = GeneratedColumn<String>(
    'subject_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectNameMeta = const VerificationMeta(
    'subjectName',
  );
  @override
  late final GeneratedColumn<String> subjectName = GeneratedColumn<String>(
    'subject_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<String> startsAt = GeneratedColumn<String>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<String> endsAt = GeneratedColumn<String>(
    'ends_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionDateMeta = const VerificationMeta(
    'sessionDate',
  );
  @override
  late final GeneratedColumn<String> sessionDate = GeneratedColumn<String>(
    'session_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKey,
    payloadVersion,
    userId,
    membershipId,
    institutionId,
    selectionKey,
    courseOfferingId,
    timetableEntryId,
    subjectCode,
    subjectName,
    startsAt,
    endsAt,
    sessionDate,
    state,
    requestId,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_draft_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('payload_version')) {
      context.handle(
        _payloadVersionMeta,
        payloadVersion.isAcceptableOrUnknown(
          data['payload_version']!,
          _payloadVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadVersionMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('membership_id')) {
      context.handle(
        _membershipIdMeta,
        membershipId.isAcceptableOrUnknown(
          data['membership_id']!,
          _membershipIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_membershipIdMeta);
    }
    if (data.containsKey('institution_id')) {
      context.handle(
        _institutionIdMeta,
        institutionId.isAcceptableOrUnknown(
          data['institution_id']!,
          _institutionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_institutionIdMeta);
    }
    if (data.containsKey('selection_key')) {
      context.handle(
        _selectionKeyMeta,
        selectionKey.isAcceptableOrUnknown(
          data['selection_key']!,
          _selectionKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectionKeyMeta);
    }
    if (data.containsKey('course_offering_id')) {
      context.handle(
        _courseOfferingIdMeta,
        courseOfferingId.isAcceptableOrUnknown(
          data['course_offering_id']!,
          _courseOfferingIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseOfferingIdMeta);
    }
    if (data.containsKey('timetable_entry_id')) {
      context.handle(
        _timetableEntryIdMeta,
        timetableEntryId.isAcceptableOrUnknown(
          data['timetable_entry_id']!,
          _timetableEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timetableEntryIdMeta);
    }
    if (data.containsKey('subject_code')) {
      context.handle(
        _subjectCodeMeta,
        subjectCode.isAcceptableOrUnknown(
          data['subject_code']!,
          _subjectCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectCodeMeta);
    }
    if (data.containsKey('subject_name')) {
      context.handle(
        _subjectNameMeta,
        subjectName.isAcceptableOrUnknown(
          data['subject_name']!,
          _subjectNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectNameMeta);
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endsAtMeta);
    }
    if (data.containsKey('session_date')) {
      context.handle(
        _sessionDateMeta,
        sessionDate.isAcceptableOrUnknown(
          data['session_date']!,
          _sessionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionDateMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceDraftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      payloadVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payload_version'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      membershipId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}membership_id'],
      )!,
      institutionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution_id'],
      )!,
      selectionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selection_key'],
      )!,
      courseOfferingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_offering_id'],
      )!,
      timetableEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timetable_entry_id'],
      )!,
      subjectCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_code'],
      )!,
      subjectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_name'],
      )!,
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}starts_at'],
      )!,
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ends_at'],
      )!,
      sessionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_date'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $AttendanceDraftRowsTable createAlias(String alias) {
    return $AttendanceDraftRowsTable(attachedDatabase, alias);
  }
}

class AttendanceDraftRow extends DataClass
    implements Insertable<AttendanceDraftRow> {
  final String id;
  final String scopeKey;
  final int payloadVersion;
  final String userId;
  final String membershipId;
  final String institutionId;
  final String selectionKey;
  final String courseOfferingId;
  final String timetableEntryId;
  final String subjectCode;
  final String subjectName;
  final String startsAt;
  final String endsAt;
  final String sessionDate;
  final String state;
  final String? requestId;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const AttendanceDraftRow({
    required this.id,
    required this.scopeKey,
    required this.payloadVersion,
    required this.userId,
    required this.membershipId,
    required this.institutionId,
    required this.selectionKey,
    required this.courseOfferingId,
    required this.timetableEntryId,
    required this.subjectCode,
    required this.subjectName,
    required this.startsAt,
    required this.endsAt,
    required this.sessionDate,
    required this.state,
    this.requestId,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_key'] = Variable<String>(scopeKey);
    map['payload_version'] = Variable<int>(payloadVersion);
    map['user_id'] = Variable<String>(userId);
    map['membership_id'] = Variable<String>(membershipId);
    map['institution_id'] = Variable<String>(institutionId);
    map['selection_key'] = Variable<String>(selectionKey);
    map['course_offering_id'] = Variable<String>(courseOfferingId);
    map['timetable_entry_id'] = Variable<String>(timetableEntryId);
    map['subject_code'] = Variable<String>(subjectCode);
    map['subject_name'] = Variable<String>(subjectName);
    map['starts_at'] = Variable<String>(startsAt);
    map['ends_at'] = Variable<String>(endsAt);
    map['session_date'] = Variable<String>(sessionDate);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || requestId != null) {
      map['request_id'] = Variable<String>(requestId);
    }
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  AttendanceDraftRowsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceDraftRowsCompanion(
      id: Value(id),
      scopeKey: Value(scopeKey),
      payloadVersion: Value(payloadVersion),
      userId: Value(userId),
      membershipId: Value(membershipId),
      institutionId: Value(institutionId),
      selectionKey: Value(selectionKey),
      courseOfferingId: Value(courseOfferingId),
      timetableEntryId: Value(timetableEntryId),
      subjectCode: Value(subjectCode),
      subjectName: Value(subjectName),
      startsAt: Value(startsAt),
      endsAt: Value(endsAt),
      sessionDate: Value(sessionDate),
      state: Value(state),
      requestId: requestId == null && nullToAbsent
          ? const Value.absent()
          : Value(requestId),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory AttendanceDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceDraftRow(
      id: serializer.fromJson<String>(json['id']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      payloadVersion: serializer.fromJson<int>(json['payloadVersion']),
      userId: serializer.fromJson<String>(json['userId']),
      membershipId: serializer.fromJson<String>(json['membershipId']),
      institutionId: serializer.fromJson<String>(json['institutionId']),
      selectionKey: serializer.fromJson<String>(json['selectionKey']),
      courseOfferingId: serializer.fromJson<String>(json['courseOfferingId']),
      timetableEntryId: serializer.fromJson<String>(json['timetableEntryId']),
      subjectCode: serializer.fromJson<String>(json['subjectCode']),
      subjectName: serializer.fromJson<String>(json['subjectName']),
      startsAt: serializer.fromJson<String>(json['startsAt']),
      endsAt: serializer.fromJson<String>(json['endsAt']),
      sessionDate: serializer.fromJson<String>(json['sessionDate']),
      state: serializer.fromJson<String>(json['state']),
      requestId: serializer.fromJson<String?>(json['requestId']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'payloadVersion': serializer.toJson<int>(payloadVersion),
      'userId': serializer.toJson<String>(userId),
      'membershipId': serializer.toJson<String>(membershipId),
      'institutionId': serializer.toJson<String>(institutionId),
      'selectionKey': serializer.toJson<String>(selectionKey),
      'courseOfferingId': serializer.toJson<String>(courseOfferingId),
      'timetableEntryId': serializer.toJson<String>(timetableEntryId),
      'subjectCode': serializer.toJson<String>(subjectCode),
      'subjectName': serializer.toJson<String>(subjectName),
      'startsAt': serializer.toJson<String>(startsAt),
      'endsAt': serializer.toJson<String>(endsAt),
      'sessionDate': serializer.toJson<String>(sessionDate),
      'state': serializer.toJson<String>(state),
      'requestId': serializer.toJson<String?>(requestId),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  AttendanceDraftRow copyWith({
    String? id,
    String? scopeKey,
    int? payloadVersion,
    String? userId,
    String? membershipId,
    String? institutionId,
    String? selectionKey,
    String? courseOfferingId,
    String? timetableEntryId,
    String? subjectCode,
    String? subjectName,
    String? startsAt,
    String? endsAt,
    String? sessionDate,
    String? state,
    Value<String?> requestId = const Value.absent(),
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => AttendanceDraftRow(
    id: id ?? this.id,
    scopeKey: scopeKey ?? this.scopeKey,
    payloadVersion: payloadVersion ?? this.payloadVersion,
    userId: userId ?? this.userId,
    membershipId: membershipId ?? this.membershipId,
    institutionId: institutionId ?? this.institutionId,
    selectionKey: selectionKey ?? this.selectionKey,
    courseOfferingId: courseOfferingId ?? this.courseOfferingId,
    timetableEntryId: timetableEntryId ?? this.timetableEntryId,
    subjectCode: subjectCode ?? this.subjectCode,
    subjectName: subjectName ?? this.subjectName,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    sessionDate: sessionDate ?? this.sessionDate,
    state: state ?? this.state,
    requestId: requestId.present ? requestId.value : this.requestId,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  AttendanceDraftRow copyWithCompanion(AttendanceDraftRowsCompanion data) {
    return AttendanceDraftRow(
      id: data.id.present ? data.id.value : this.id,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      payloadVersion: data.payloadVersion.present
          ? data.payloadVersion.value
          : this.payloadVersion,
      userId: data.userId.present ? data.userId.value : this.userId,
      membershipId: data.membershipId.present
          ? data.membershipId.value
          : this.membershipId,
      institutionId: data.institutionId.present
          ? data.institutionId.value
          : this.institutionId,
      selectionKey: data.selectionKey.present
          ? data.selectionKey.value
          : this.selectionKey,
      courseOfferingId: data.courseOfferingId.present
          ? data.courseOfferingId.value
          : this.courseOfferingId,
      timetableEntryId: data.timetableEntryId.present
          ? data.timetableEntryId.value
          : this.timetableEntryId,
      subjectCode: data.subjectCode.present
          ? data.subjectCode.value
          : this.subjectCode,
      subjectName: data.subjectName.present
          ? data.subjectName.value
          : this.subjectName,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      sessionDate: data.sessionDate.present
          ? data.sessionDate.value
          : this.sessionDate,
      state: data.state.present ? data.state.value : this.state,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceDraftRow(')
          ..write('id: $id, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('userId: $userId, ')
          ..write('membershipId: $membershipId, ')
          ..write('institutionId: $institutionId, ')
          ..write('selectionKey: $selectionKey, ')
          ..write('courseOfferingId: $courseOfferingId, ')
          ..write('timetableEntryId: $timetableEntryId, ')
          ..write('subjectCode: $subjectCode, ')
          ..write('subjectName: $subjectName, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('sessionDate: $sessionDate, ')
          ..write('state: $state, ')
          ..write('requestId: $requestId, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scopeKey,
    payloadVersion,
    userId,
    membershipId,
    institutionId,
    selectionKey,
    courseOfferingId,
    timetableEntryId,
    subjectCode,
    subjectName,
    startsAt,
    endsAt,
    sessionDate,
    state,
    requestId,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceDraftRow &&
          other.id == this.id &&
          other.scopeKey == this.scopeKey &&
          other.payloadVersion == this.payloadVersion &&
          other.userId == this.userId &&
          other.membershipId == this.membershipId &&
          other.institutionId == this.institutionId &&
          other.selectionKey == this.selectionKey &&
          other.courseOfferingId == this.courseOfferingId &&
          other.timetableEntryId == this.timetableEntryId &&
          other.subjectCode == this.subjectCode &&
          other.subjectName == this.subjectName &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.sessionDate == this.sessionDate &&
          other.state == this.state &&
          other.requestId == this.requestId &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class AttendanceDraftRowsCompanion extends UpdateCompanion<AttendanceDraftRow> {
  final Value<String> id;
  final Value<String> scopeKey;
  final Value<int> payloadVersion;
  final Value<String> userId;
  final Value<String> membershipId;
  final Value<String> institutionId;
  final Value<String> selectionKey;
  final Value<String> courseOfferingId;
  final Value<String> timetableEntryId;
  final Value<String> subjectCode;
  final Value<String> subjectName;
  final Value<String> startsAt;
  final Value<String> endsAt;
  final Value<String> sessionDate;
  final Value<String> state;
  final Value<String?> requestId;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const AttendanceDraftRowsCompanion({
    this.id = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.payloadVersion = const Value.absent(),
    this.userId = const Value.absent(),
    this.membershipId = const Value.absent(),
    this.institutionId = const Value.absent(),
    this.selectionKey = const Value.absent(),
    this.courseOfferingId = const Value.absent(),
    this.timetableEntryId = const Value.absent(),
    this.subjectCode = const Value.absent(),
    this.subjectName = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.sessionDate = const Value.absent(),
    this.state = const Value.absent(),
    this.requestId = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceDraftRowsCompanion.insert({
    required String id,
    required String scopeKey,
    required int payloadVersion,
    required String userId,
    required String membershipId,
    required String institutionId,
    required String selectionKey,
    required String courseOfferingId,
    required String timetableEntryId,
    required String subjectCode,
    required String subjectName,
    required String startsAt,
    required String endsAt,
    required String sessionDate,
    required String state,
    this.requestId = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scopeKey = Value(scopeKey),
       payloadVersion = Value(payloadVersion),
       userId = Value(userId),
       membershipId = Value(membershipId),
       institutionId = Value(institutionId),
       selectionKey = Value(selectionKey),
       courseOfferingId = Value(courseOfferingId),
       timetableEntryId = Value(timetableEntryId),
       subjectCode = Value(subjectCode),
       subjectName = Value(subjectName),
       startsAt = Value(startsAt),
       endsAt = Value(endsAt),
       sessionDate = Value(sessionDate),
       state = Value(state),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<AttendanceDraftRow> custom({
    Expression<String>? id,
    Expression<String>? scopeKey,
    Expression<int>? payloadVersion,
    Expression<String>? userId,
    Expression<String>? membershipId,
    Expression<String>? institutionId,
    Expression<String>? selectionKey,
    Expression<String>? courseOfferingId,
    Expression<String>? timetableEntryId,
    Expression<String>? subjectCode,
    Expression<String>? subjectName,
    Expression<String>? startsAt,
    Expression<String>? endsAt,
    Expression<String>? sessionDate,
    Expression<String>? state,
    Expression<String>? requestId,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (payloadVersion != null) 'payload_version': payloadVersion,
      if (userId != null) 'user_id': userId,
      if (membershipId != null) 'membership_id': membershipId,
      if (institutionId != null) 'institution_id': institutionId,
      if (selectionKey != null) 'selection_key': selectionKey,
      if (courseOfferingId != null) 'course_offering_id': courseOfferingId,
      if (timetableEntryId != null) 'timetable_entry_id': timetableEntryId,
      if (subjectCode != null) 'subject_code': subjectCode,
      if (subjectName != null) 'subject_name': subjectName,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (sessionDate != null) 'session_date': sessionDate,
      if (state != null) 'state': state,
      if (requestId != null) 'request_id': requestId,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceDraftRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKey,
    Value<int>? payloadVersion,
    Value<String>? userId,
    Value<String>? membershipId,
    Value<String>? institutionId,
    Value<String>? selectionKey,
    Value<String>? courseOfferingId,
    Value<String>? timetableEntryId,
    Value<String>? subjectCode,
    Value<String>? subjectName,
    Value<String>? startsAt,
    Value<String>? endsAt,
    Value<String>? sessionDate,
    Value<String>? state,
    Value<String?>? requestId,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return AttendanceDraftRowsCompanion(
      id: id ?? this.id,
      scopeKey: scopeKey ?? this.scopeKey,
      payloadVersion: payloadVersion ?? this.payloadVersion,
      userId: userId ?? this.userId,
      membershipId: membershipId ?? this.membershipId,
      institutionId: institutionId ?? this.institutionId,
      selectionKey: selectionKey ?? this.selectionKey,
      courseOfferingId: courseOfferingId ?? this.courseOfferingId,
      timetableEntryId: timetableEntryId ?? this.timetableEntryId,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      sessionDate: sessionDate ?? this.sessionDate,
      state: state ?? this.state,
      requestId: requestId ?? this.requestId,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (payloadVersion.present) {
      map['payload_version'] = Variable<int>(payloadVersion.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (membershipId.present) {
      map['membership_id'] = Variable<String>(membershipId.value);
    }
    if (institutionId.present) {
      map['institution_id'] = Variable<String>(institutionId.value);
    }
    if (selectionKey.present) {
      map['selection_key'] = Variable<String>(selectionKey.value);
    }
    if (courseOfferingId.present) {
      map['course_offering_id'] = Variable<String>(courseOfferingId.value);
    }
    if (timetableEntryId.present) {
      map['timetable_entry_id'] = Variable<String>(timetableEntryId.value);
    }
    if (subjectCode.present) {
      map['subject_code'] = Variable<String>(subjectCode.value);
    }
    if (subjectName.present) {
      map['subject_name'] = Variable<String>(subjectName.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<String>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<String>(endsAt.value);
    }
    if (sessionDate.present) {
      map['session_date'] = Variable<String>(sessionDate.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceDraftRowsCompanion(')
          ..write('id: $id, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('payloadVersion: $payloadVersion, ')
          ..write('userId: $userId, ')
          ..write('membershipId: $membershipId, ')
          ..write('institutionId: $institutionId, ')
          ..write('selectionKey: $selectionKey, ')
          ..write('courseOfferingId: $courseOfferingId, ')
          ..write('timetableEntryId: $timetableEntryId, ')
          ..write('subjectCode: $subjectCode, ')
          ..write('subjectName: $subjectName, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('sessionDate: $sessionDate, ')
          ..write('state: $state, ')
          ..write('requestId: $requestId, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceDraftMarkRowsTable extends AttendanceDraftMarkRows
    with TableInfo<$AttendanceDraftMarkRowsTable, AttendanceDraftMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceDraftMarkRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _draftIdMeta = const VerificationMeta(
    'draftId',
  );
  @override
  late final GeneratedColumn<String> draftId = GeneratedColumn<String>(
    'draft_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES attendance_draft_rows (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _enrolmentIdMeta = const VerificationMeta(
    'enrolmentId',
  );
  @override
  late final GeneratedColumn<String> enrolmentId = GeneratedColumn<String>(
    'enrolment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentUserIdMeta = const VerificationMeta(
    'studentUserId',
  );
  @override
  late final GeneratedColumn<String> studentUserId = GeneratedColumn<String>(
    'student_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    draftId,
    enrolmentId,
    studentUserId,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_draft_mark_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceDraftMarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('draft_id')) {
      context.handle(
        _draftIdMeta,
        draftId.isAcceptableOrUnknown(data['draft_id']!, _draftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_draftIdMeta);
    }
    if (data.containsKey('enrolment_id')) {
      context.handle(
        _enrolmentIdMeta,
        enrolmentId.isAcceptableOrUnknown(
          data['enrolment_id']!,
          _enrolmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_enrolmentIdMeta);
    }
    if (data.containsKey('student_user_id')) {
      context.handle(
        _studentUserIdMeta,
        studentUserId.isAcceptableOrUnknown(
          data['student_user_id']!,
          _studentUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentUserIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {draftId, studentUserId};
  @override
  AttendanceDraftMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceDraftMarkRow(
      draftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_id'],
      )!,
      enrolmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enrolment_id'],
      )!,
      studentUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_user_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $AttendanceDraftMarkRowsTable createAlias(String alias) {
    return $AttendanceDraftMarkRowsTable(attachedDatabase, alias);
  }
}

class AttendanceDraftMarkRow extends DataClass
    implements Insertable<AttendanceDraftMarkRow> {
  final String draftId;
  final String enrolmentId;
  final String studentUserId;
  final String status;
  const AttendanceDraftMarkRow({
    required this.draftId,
    required this.enrolmentId,
    required this.studentUserId,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['draft_id'] = Variable<String>(draftId);
    map['enrolment_id'] = Variable<String>(enrolmentId);
    map['student_user_id'] = Variable<String>(studentUserId);
    map['status'] = Variable<String>(status);
    return map;
  }

  AttendanceDraftMarkRowsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceDraftMarkRowsCompanion(
      draftId: Value(draftId),
      enrolmentId: Value(enrolmentId),
      studentUserId: Value(studentUserId),
      status: Value(status),
    );
  }

  factory AttendanceDraftMarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceDraftMarkRow(
      draftId: serializer.fromJson<String>(json['draftId']),
      enrolmentId: serializer.fromJson<String>(json['enrolmentId']),
      studentUserId: serializer.fromJson<String>(json['studentUserId']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'draftId': serializer.toJson<String>(draftId),
      'enrolmentId': serializer.toJson<String>(enrolmentId),
      'studentUserId': serializer.toJson<String>(studentUserId),
      'status': serializer.toJson<String>(status),
    };
  }

  AttendanceDraftMarkRow copyWith({
    String? draftId,
    String? enrolmentId,
    String? studentUserId,
    String? status,
  }) => AttendanceDraftMarkRow(
    draftId: draftId ?? this.draftId,
    enrolmentId: enrolmentId ?? this.enrolmentId,
    studentUserId: studentUserId ?? this.studentUserId,
    status: status ?? this.status,
  );
  AttendanceDraftMarkRow copyWithCompanion(
    AttendanceDraftMarkRowsCompanion data,
  ) {
    return AttendanceDraftMarkRow(
      draftId: data.draftId.present ? data.draftId.value : this.draftId,
      enrolmentId: data.enrolmentId.present
          ? data.enrolmentId.value
          : this.enrolmentId,
      studentUserId: data.studentUserId.present
          ? data.studentUserId.value
          : this.studentUserId,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceDraftMarkRow(')
          ..write('draftId: $draftId, ')
          ..write('enrolmentId: $enrolmentId, ')
          ..write('studentUserId: $studentUserId, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(draftId, enrolmentId, studentUserId, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceDraftMarkRow &&
          other.draftId == this.draftId &&
          other.enrolmentId == this.enrolmentId &&
          other.studentUserId == this.studentUserId &&
          other.status == this.status);
}

class AttendanceDraftMarkRowsCompanion
    extends UpdateCompanion<AttendanceDraftMarkRow> {
  final Value<String> draftId;
  final Value<String> enrolmentId;
  final Value<String> studentUserId;
  final Value<String> status;
  final Value<int> rowid;
  const AttendanceDraftMarkRowsCompanion({
    this.draftId = const Value.absent(),
    this.enrolmentId = const Value.absent(),
    this.studentUserId = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceDraftMarkRowsCompanion.insert({
    required String draftId,
    required String enrolmentId,
    required String studentUserId,
    required String status,
    this.rowid = const Value.absent(),
  }) : draftId = Value(draftId),
       enrolmentId = Value(enrolmentId),
       studentUserId = Value(studentUserId),
       status = Value(status);
  static Insertable<AttendanceDraftMarkRow> custom({
    Expression<String>? draftId,
    Expression<String>? enrolmentId,
    Expression<String>? studentUserId,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (draftId != null) 'draft_id': draftId,
      if (enrolmentId != null) 'enrolment_id': enrolmentId,
      if (studentUserId != null) 'student_user_id': studentUserId,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceDraftMarkRowsCompanion copyWith({
    Value<String>? draftId,
    Value<String>? enrolmentId,
    Value<String>? studentUserId,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return AttendanceDraftMarkRowsCompanion(
      draftId: draftId ?? this.draftId,
      enrolmentId: enrolmentId ?? this.enrolmentId,
      studentUserId: studentUserId ?? this.studentUserId,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (draftId.present) {
      map['draft_id'] = Variable<String>(draftId.value);
    }
    if (enrolmentId.present) {
      map['enrolment_id'] = Variable<String>(enrolmentId.value);
    }
    if (studentUserId.present) {
      map['student_user_id'] = Variable<String>(studentUserId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceDraftMarkRowsCompanion(')
          ..write('draftId: $draftId, ')
          ..write('enrolmentId: $enrolmentId, ')
          ..write('studentUserId: $studentUserId, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CampusLocalDatabase extends GeneratedDatabase {
  _$CampusLocalDatabase(QueryExecutor e) : super(e);
  $CampusLocalDatabaseManager get managers => $CampusLocalDatabaseManager(this);
  late final $AttendanceDraftRowsTable attendanceDraftRows =
      $AttendanceDraftRowsTable(this);
  late final $AttendanceDraftMarkRowsTable attendanceDraftMarkRows =
      $AttendanceDraftMarkRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    attendanceDraftRows,
    attendanceDraftMarkRows,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'attendance_draft_rows',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('attendance_draft_mark_rows', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$AttendanceDraftRowsTableCreateCompanionBuilder =
    AttendanceDraftRowsCompanion Function({
      required String id,
      required String scopeKey,
      required int payloadVersion,
      required String userId,
      required String membershipId,
      required String institutionId,
      required String selectionKey,
      required String courseOfferingId,
      required String timetableEntryId,
      required String subjectCode,
      required String subjectName,
      required String startsAt,
      required String endsAt,
      required String sessionDate,
      required String state,
      Value<String?> requestId,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$AttendanceDraftRowsTableUpdateCompanionBuilder =
    AttendanceDraftRowsCompanion Function({
      Value<String> id,
      Value<String> scopeKey,
      Value<int> payloadVersion,
      Value<String> userId,
      Value<String> membershipId,
      Value<String> institutionId,
      Value<String> selectionKey,
      Value<String> courseOfferingId,
      Value<String> timetableEntryId,
      Value<String> subjectCode,
      Value<String> subjectName,
      Value<String> startsAt,
      Value<String> endsAt,
      Value<String> sessionDate,
      Value<String> state,
      Value<String?> requestId,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$AttendanceDraftRowsTableReferences
    extends
        BaseReferences<
          _$CampusLocalDatabase,
          $AttendanceDraftRowsTable,
          AttendanceDraftRow
        > {
  $$AttendanceDraftRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $AttendanceDraftMarkRowsTable,
    List<AttendanceDraftMarkRow>
  >
  _attendanceDraftMarkRowsRefsTable(_$CampusLocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attendanceDraftMarkRows,
        aliasName:
            'attendance_draft_rows__id__attendance_draft_mark_rows__draft_id',
      );

  $$AttendanceDraftMarkRowsTableProcessedTableManager
  get attendanceDraftMarkRowsRefs {
    final manager = $$AttendanceDraftMarkRowsTableTableManager(
      $_db,
      $_db.attendanceDraftMarkRows,
    ).filter((f) => f.draftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceDraftMarkRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AttendanceDraftRowsTableFilterComposer
    extends Composer<_$CampusLocalDatabase, $AttendanceDraftRowsTable> {
  $$AttendanceDraftRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get institutionId => $composableBuilder(
    column: $table.institutionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectionKey => $composableBuilder(
    column: $table.selectionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseOfferingId => $composableBuilder(
    column: $table.courseOfferingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timetableEntryId => $composableBuilder(
    column: $table.timetableEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectCode => $composableBuilder(
    column: $table.subjectCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionDate => $composableBuilder(
    column: $table.sessionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> attendanceDraftMarkRowsRefs(
    Expression<bool> Function($$AttendanceDraftMarkRowsTableFilterComposer f) f,
  ) {
    final $$AttendanceDraftMarkRowsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceDraftMarkRows,
          getReferencedColumn: (t) => t.draftId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceDraftMarkRowsTableFilterComposer(
                $db: $db,
                $table: $db.attendanceDraftMarkRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AttendanceDraftRowsTableOrderingComposer
    extends Composer<_$CampusLocalDatabase, $AttendanceDraftRowsTable> {
  $$AttendanceDraftRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get institutionId => $composableBuilder(
    column: $table.institutionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectionKey => $composableBuilder(
    column: $table.selectionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseOfferingId => $composableBuilder(
    column: $table.courseOfferingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timetableEntryId => $composableBuilder(
    column: $table.timetableEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectCode => $composableBuilder(
    column: $table.subjectCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionDate => $composableBuilder(
    column: $table.sessionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceDraftRowsTableAnnotationComposer
    extends Composer<_$CampusLocalDatabase, $AttendanceDraftRowsTable> {
  $$AttendanceDraftRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<int> get payloadVersion => $composableBuilder(
    column: $table.payloadVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get institutionId => $composableBuilder(
    column: $table.institutionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectionKey => $composableBuilder(
    column: $table.selectionKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get courseOfferingId => $composableBuilder(
    column: $table.courseOfferingId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timetableEntryId => $composableBuilder(
    column: $table.timetableEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectCode => $composableBuilder(
    column: $table.subjectCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<String> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<String> get sessionDate => $composableBuilder(
    column: $table.sessionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  Expression<T> attendanceDraftMarkRowsRefs<T extends Object>(
    Expression<T> Function($$AttendanceDraftMarkRowsTableAnnotationComposer a)
    f,
  ) {
    final $$AttendanceDraftMarkRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceDraftMarkRows,
          getReferencedColumn: (t) => t.draftId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceDraftMarkRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceDraftMarkRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AttendanceDraftRowsTableTableManager
    extends
        RootTableManager<
          _$CampusLocalDatabase,
          $AttendanceDraftRowsTable,
          AttendanceDraftRow,
          $$AttendanceDraftRowsTableFilterComposer,
          $$AttendanceDraftRowsTableOrderingComposer,
          $$AttendanceDraftRowsTableAnnotationComposer,
          $$AttendanceDraftRowsTableCreateCompanionBuilder,
          $$AttendanceDraftRowsTableUpdateCompanionBuilder,
          (AttendanceDraftRow, $$AttendanceDraftRowsTableReferences),
          AttendanceDraftRow,
          PrefetchHooks Function({bool attendanceDraftMarkRowsRefs})
        > {
  $$AttendanceDraftRowsTableTableManager(
    _$CampusLocalDatabase db,
    $AttendanceDraftRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceDraftRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceDraftRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttendanceDraftRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<int> payloadVersion = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> membershipId = const Value.absent(),
                Value<String> institutionId = const Value.absent(),
                Value<String> selectionKey = const Value.absent(),
                Value<String> courseOfferingId = const Value.absent(),
                Value<String> timetableEntryId = const Value.absent(),
                Value<String> subjectCode = const Value.absent(),
                Value<String> subjectName = const Value.absent(),
                Value<String> startsAt = const Value.absent(),
                Value<String> endsAt = const Value.absent(),
                Value<String> sessionDate = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> requestId = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceDraftRowsCompanion(
                id: id,
                scopeKey: scopeKey,
                payloadVersion: payloadVersion,
                userId: userId,
                membershipId: membershipId,
                institutionId: institutionId,
                selectionKey: selectionKey,
                courseOfferingId: courseOfferingId,
                timetableEntryId: timetableEntryId,
                subjectCode: subjectCode,
                subjectName: subjectName,
                startsAt: startsAt,
                endsAt: endsAt,
                sessionDate: sessionDate,
                state: state,
                requestId: requestId,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scopeKey,
                required int payloadVersion,
                required String userId,
                required String membershipId,
                required String institutionId,
                required String selectionKey,
                required String courseOfferingId,
                required String timetableEntryId,
                required String subjectCode,
                required String subjectName,
                required String startsAt,
                required String endsAt,
                required String sessionDate,
                required String state,
                Value<String?> requestId = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => AttendanceDraftRowsCompanion.insert(
                id: id,
                scopeKey: scopeKey,
                payloadVersion: payloadVersion,
                userId: userId,
                membershipId: membershipId,
                institutionId: institutionId,
                selectionKey: selectionKey,
                courseOfferingId: courseOfferingId,
                timetableEntryId: timetableEntryId,
                subjectCode: subjectCode,
                subjectName: subjectName,
                startsAt: startsAt,
                endsAt: endsAt,
                sessionDate: sessionDate,
                state: state,
                requestId: requestId,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttendanceDraftRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attendanceDraftMarkRowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (attendanceDraftMarkRowsRefs) db.attendanceDraftMarkRows,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attendanceDraftMarkRowsRefs)
                    await $_getPrefetchedData<
                      AttendanceDraftRow,
                      $AttendanceDraftRowsTable,
                      AttendanceDraftMarkRow
                    >(
                      currentTable: table,
                      referencedTable: $$AttendanceDraftRowsTableReferences
                          ._attendanceDraftMarkRowsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AttendanceDraftRowsTableReferences(
                            db,
                            table,
                            p0,
                          ).attendanceDraftMarkRowsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.draftId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AttendanceDraftRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$CampusLocalDatabase,
      $AttendanceDraftRowsTable,
      AttendanceDraftRow,
      $$AttendanceDraftRowsTableFilterComposer,
      $$AttendanceDraftRowsTableOrderingComposer,
      $$AttendanceDraftRowsTableAnnotationComposer,
      $$AttendanceDraftRowsTableCreateCompanionBuilder,
      $$AttendanceDraftRowsTableUpdateCompanionBuilder,
      (AttendanceDraftRow, $$AttendanceDraftRowsTableReferences),
      AttendanceDraftRow,
      PrefetchHooks Function({bool attendanceDraftMarkRowsRefs})
    >;
typedef $$AttendanceDraftMarkRowsTableCreateCompanionBuilder =
    AttendanceDraftMarkRowsCompanion Function({
      required String draftId,
      required String enrolmentId,
      required String studentUserId,
      required String status,
      Value<int> rowid,
    });
typedef $$AttendanceDraftMarkRowsTableUpdateCompanionBuilder =
    AttendanceDraftMarkRowsCompanion Function({
      Value<String> draftId,
      Value<String> enrolmentId,
      Value<String> studentUserId,
      Value<String> status,
      Value<int> rowid,
    });

final class $$AttendanceDraftMarkRowsTableReferences
    extends
        BaseReferences<
          _$CampusLocalDatabase,
          $AttendanceDraftMarkRowsTable,
          AttendanceDraftMarkRow
        > {
  $$AttendanceDraftMarkRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AttendanceDraftRowsTable _draftIdTable(_$CampusLocalDatabase db) =>
      db.attendanceDraftRows.createAlias(
        'attendance_draft_mark_rows__draft_id__attendance_draft_rows__id',
      );

  $$AttendanceDraftRowsTableProcessedTableManager get draftId {
    final $_column = $_itemColumn<String>('draft_id')!;

    final manager = $$AttendanceDraftRowsTableTableManager(
      $_db,
      $_db.attendanceDraftRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_draftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttendanceDraftMarkRowsTableFilterComposer
    extends Composer<_$CampusLocalDatabase, $AttendanceDraftMarkRowsTable> {
  $$AttendanceDraftMarkRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get enrolmentId => $composableBuilder(
    column: $table.enrolmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentUserId => $composableBuilder(
    column: $table.studentUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$AttendanceDraftRowsTableFilterComposer get draftId {
    final $$AttendanceDraftRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftId,
      referencedTable: $db.attendanceDraftRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceDraftRowsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceDraftRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceDraftMarkRowsTableOrderingComposer
    extends Composer<_$CampusLocalDatabase, $AttendanceDraftMarkRowsTable> {
  $$AttendanceDraftMarkRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get enrolmentId => $composableBuilder(
    column: $table.enrolmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentUserId => $composableBuilder(
    column: $table.studentUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$AttendanceDraftRowsTableOrderingComposer get draftId {
    final $$AttendanceDraftRowsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.draftId,
          referencedTable: $db.attendanceDraftRows,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceDraftRowsTableOrderingComposer(
                $db: $db,
                $table: $db.attendanceDraftRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AttendanceDraftMarkRowsTableAnnotationComposer
    extends Composer<_$CampusLocalDatabase, $AttendanceDraftMarkRowsTable> {
  $$AttendanceDraftMarkRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get enrolmentId => $composableBuilder(
    column: $table.enrolmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get studentUserId => $composableBuilder(
    column: $table.studentUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$AttendanceDraftRowsTableAnnotationComposer get draftId {
    final $$AttendanceDraftRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.draftId,
          referencedTable: $db.attendanceDraftRows,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceDraftRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceDraftRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AttendanceDraftMarkRowsTableTableManager
    extends
        RootTableManager<
          _$CampusLocalDatabase,
          $AttendanceDraftMarkRowsTable,
          AttendanceDraftMarkRow,
          $$AttendanceDraftMarkRowsTableFilterComposer,
          $$AttendanceDraftMarkRowsTableOrderingComposer,
          $$AttendanceDraftMarkRowsTableAnnotationComposer,
          $$AttendanceDraftMarkRowsTableCreateCompanionBuilder,
          $$AttendanceDraftMarkRowsTableUpdateCompanionBuilder,
          (AttendanceDraftMarkRow, $$AttendanceDraftMarkRowsTableReferences),
          AttendanceDraftMarkRow,
          PrefetchHooks Function({bool draftId})
        > {
  $$AttendanceDraftMarkRowsTableTableManager(
    _$CampusLocalDatabase db,
    $AttendanceDraftMarkRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceDraftMarkRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AttendanceDraftMarkRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttendanceDraftMarkRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> draftId = const Value.absent(),
                Value<String> enrolmentId = const Value.absent(),
                Value<String> studentUserId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceDraftMarkRowsCompanion(
                draftId: draftId,
                enrolmentId: enrolmentId,
                studentUserId: studentUserId,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String draftId,
                required String enrolmentId,
                required String studentUserId,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => AttendanceDraftMarkRowsCompanion.insert(
                draftId: draftId,
                enrolmentId: enrolmentId,
                studentUserId: studentUserId,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttendanceDraftMarkRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({draftId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (draftId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.draftId,
                                referencedTable:
                                    $$AttendanceDraftMarkRowsTableReferences
                                        ._draftIdTable(db),
                                referencedColumn:
                                    $$AttendanceDraftMarkRowsTableReferences
                                        ._draftIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttendanceDraftMarkRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$CampusLocalDatabase,
      $AttendanceDraftMarkRowsTable,
      AttendanceDraftMarkRow,
      $$AttendanceDraftMarkRowsTableFilterComposer,
      $$AttendanceDraftMarkRowsTableOrderingComposer,
      $$AttendanceDraftMarkRowsTableAnnotationComposer,
      $$AttendanceDraftMarkRowsTableCreateCompanionBuilder,
      $$AttendanceDraftMarkRowsTableUpdateCompanionBuilder,
      (AttendanceDraftMarkRow, $$AttendanceDraftMarkRowsTableReferences),
      AttendanceDraftMarkRow,
      PrefetchHooks Function({bool draftId})
    >;

class $CampusLocalDatabaseManager {
  final _$CampusLocalDatabase _db;
  $CampusLocalDatabaseManager(this._db);
  $$AttendanceDraftRowsTableTableManager get attendanceDraftRows =>
      $$AttendanceDraftRowsTableTableManager(_db, _db.attendanceDraftRows);
  $$AttendanceDraftMarkRowsTableTableManager get attendanceDraftMarkRows =>
      $$AttendanceDraftMarkRowsTableTableManager(
        _db,
        _db.attendanceDraftMarkRows,
      );
}
