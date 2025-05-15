import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:test/test.dart';
import 'package:turnip_rundown/util.dart';

part 'json_migration_test.g.dart';

@JsonSerializable()
class NoVersionIndicatorVerOne extends Equatable {
  final String name;
  final int birthYear;
  final int birthMonth;
  final int birthDay;

  factory NoVersionIndicatorVerOne.fromJson(Map<String, dynamic> json) => _$NoVersionIndicatorVerOneFromJson(json);
  Map<String, dynamic> toJson() => _$NoVersionIndicatorVerOneToJson(this);

  const NoVersionIndicatorVerOne({
    required this.name,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
  });

  @override
  List<Object?> get props => [name, birthYear, birthMonth, birthDay];
}

@JsonSerializable()
class VerOne extends Equatable {
  @JsonKey(includeFromJson: false, includeToJson: true)
  final int version = 1;

  final String name;
  final int birthYear;
  final int birthMonth;
  final int birthDay;

  factory VerOne.fromJson(Map<String, dynamic> json) => _$VerOneFromJson(json);
  Map<String, dynamic> toJson() => _$VerOneToJson(this);

  const VerOne({
    required this.name,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
  });

  @override
  List<Object?> get props => [name, birthYear, birthMonth, birthDay];
}

@JsonSerializable()
class VerTwo extends Equatable {
  @JsonKey(includeFromJson: false, includeToJson: true)
  final int version = 2;

  final String firstName;
  final String lastName;
  final int birthYear;
  final int birthMonth;
  final int birthDay;

  factory VerTwo.fromJson(Map<String, dynamic> json) => _$VerTwoFromJson(json);
  Map<String, dynamic> toJson() => _$VerTwoToJson(this);

  const VerTwo({
    required this.firstName,
    required this.lastName,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
  });

  @override
  List<Object?> get props => [firstName, lastName, birthYear, birthMonth, birthDay];
}

@JsonSerializable()
class VerThree extends Equatable {
  @JsonKey(includeFromJson: false, includeToJson: true)
  final int version = 3;

  final String firstName;
  final String lastName;
  final int birthYear;
  final int birthMonth;
  final int birthDay;
  final bool prefersCakeToBeer;

  factory VerThree.fromJson(Map<String, dynamic> json) => _$VerThreeFromJson(json);
  Map<String, dynamic> toJson() => _$VerThreeToJson(this);

  const VerThree({
    required this.firstName,
    required this.lastName,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
    required this.prefersCakeToBeer,
  });

  @override
  List<Object?> get props => [firstName, lastName, birthYear, birthMonth, birthDay, prefersCakeToBeer];
}

String dtToStr(DateTime dt) => dt.toIso8601String();

@JsonSerializable()
class VerFour extends Equatable {
  @JsonKey(includeFromJson: false, includeToJson: true)
  final int version = 4;

  final String firstName;
  final String lastName;
  @JsonKey(fromJson: DateTime.parse, toJson: dtToStr)
  final DateTime birthday;
  final bool prefersCakeToBeer;

  factory VerFour.fromJson(Map<String, dynamic> json) => _$VerFourFromJson(json);
  Map<String, dynamic> toJson() => _$VerFourToJson(this);

  const VerFour({
    required this.firstName,
    required this.lastName,
    required this.birthday,
    required this.prefersCakeToBeer,
  });

  @override
  List<Object?> get props => [firstName, lastName, birthday, prefersCakeToBeer];
}

void main() {
  group("-> v4", () {
    final migration = JsonMigration.chainStart(
      load: VerOne.fromJson,
      migrate: (VerOne v1) {
        final names = v1.name.split(" ");
        final firstName = names[0];
        final lastName = names.skip(1).join(" ");
        return VerTwo(
          firstName: firstName,
          lastName: lastName,
          birthYear: v1.birthYear,
          birthMonth: v1.birthMonth,
          birthDay: v1.birthDay,
        );
      },
    )
        .chain(
          load: VerTwo.fromJson,
          migrate: (VerTwo v2) {
            return VerThree(
              firstName: v2.firstName,
              lastName: v2.lastName,
              birthYear: v2.birthYear,
              birthMonth: v2.birthMonth,
              birthDay: v2.birthDay,
              prefersCakeToBeer: true,
            );
          },
        )
        .chain(
            load: VerThree.fromJson,
            migrate: (VerThree v3) {
              return VerFour(
                firstName: v3.firstName,
                lastName: v3.lastName,
                birthday: DateTime(v3.birthYear, v3.birthMonth, v3.birthDay),
                prefersCakeToBeer: v3.prefersCakeToBeer,
              );
            })
        .complete(
          versionKey: "version",
          makeDefault: null,
          load: VerFour.fromJson,
        );

    test("v1 -> v4", () {
      final v1Json = const VerOne(
        name: "Bingle Bongle",
        birthYear: 2004,
        birthMonth: 12,
        birthDay: 1,
      ).toJson();
      final v1ToV4 = migration.fromJson(v1Json);
      expect(
        v1ToV4,
        VerFour(
          firstName: "Bingle",
          lastName: "Bongle",
          birthday: DateTime(2004, 12, 1),
          prefersCakeToBeer: true,
        ),
      );
    });
    test("v2 -> v4", () {
      final v2Json = const VerTwo(
        firstName: "Chadler",
        lastName: "Big",
        birthYear: 2003,
        birthMonth: 12,
        birthDay: 1,
      ).toJson();
      final v2ToV4 = migration.fromJson(v2Json);
      expect(
        v2ToV4,
        VerFour(
          firstName: "Chadler",
          lastName: "Big",
          birthday: DateTime(2003, 12, 1),
          prefersCakeToBeer: true,
        ),
      );
    });
    test("v3 -> v4", () {
      final v3Json = const VerThree(
        firstName: "Chadler",
        lastName: "Big",
        birthYear: 2003,
        birthMonth: 12,
        birthDay: 1,
        prefersCakeToBeer: false,
      ).toJson();
      final v3ToV4 = migration.fromJson(v3Json);
      expect(
        v3ToV4,
        VerFour(
          firstName: "Chadler",
          lastName: "Big",
          birthday: DateTime(2003, 12, 1),
          prefersCakeToBeer: false,
        ),
      );
    });
    test("v4 -> v4", () {
      final v4Json = VerFour(
        firstName: "Chadler",
        lastName: "Big",
        birthday: DateTime(2005, 9, 10),
        prefersCakeToBeer: false,
      ).toJson();
      final v4 = migration.fromJson(v4Json);
      expect(
        v4,
        VerFour(
          firstName: "Chadler",
          lastName: "Big",
          birthday: DateTime(2005, 9, 10),
          prefersCakeToBeer: false,
        ),
      );
    });
  });
  group(
    "single steps",
    () {
      test("v1 -> v1", () {
        final oneStep = JsonMigration.singleComplete(
          versionKey: "version",
          usesVersionKey: false,
          load: VerOne.fromJson,
          makeDefault: null,
        );
        const v1 = VerOne(
          name: "Bingle Bongle",
          birthYear: 2004,
          birthMonth: 12,
          birthDay: 1,
        );
        final newV1 = oneStep.fromJson(v1.toJson());
        expect(
          newV1,
          v1,
        );
      });
      test("v1 -> v2", () {
        final migration = JsonMigration.chainStart(
          load: VerOne.fromJson,
          migrate: (VerOne v1) {
            final names = v1.name.split(" ");
            final firstName = names[0];
            final lastName = names.skip(1).join(" ");
            return VerTwo(
              firstName: firstName,
              lastName: lastName,
              birthYear: v1.birthYear,
              birthMonth: v1.birthMonth,
              birthDay: v1.birthDay,
            );
          },
        ).complete(
          versionKey: "version",
          load: VerTwo.fromJson,
          makeDefault: null,
        );

        final v1Json = const VerOne(
          name: "Bingle Bongle",
          birthYear: 2004,
          birthMonth: 12,
          birthDay: 1,
        ).toJson();
        final v1ToV2 = migration.fromJson(v1Json);
        expect(
          v1ToV2,
          const VerTwo(
            firstName: "Bingle",
            lastName: "Bongle",
            birthYear: 2004,
            birthMonth: 12,
            birthDay: 1,
          ),
        );
      });
      test("v2 -> v3", () {
        final migration = JsonMigration.chainStart(
          load: VerOne.fromJson,
          migrate: (VerOne v1) {
            final names = v1.name.split(" ");
            final firstName = names[0];
            final lastName = names.skip(1).join(" ");
            return VerTwo(
              firstName: firstName,
              lastName: lastName,
              birthYear: v1.birthYear,
              birthMonth: v1.birthMonth,
              birthDay: v1.birthDay,
            );
          },
        )
            .chain(
              load: VerTwo.fromJson,
              migrate: (VerTwo v2) {
                return VerThree(
                  firstName: v2.firstName,
                  lastName: v2.lastName,
                  birthYear: v2.birthYear,
                  birthMonth: v2.birthMonth,
                  birthDay: v2.birthDay,
                  prefersCakeToBeer: true,
                );
              },
            )
            .complete(
              versionKey: "version",
              load: VerThree.fromJson,
              makeDefault: null,
            );
        final v2Json = const VerTwo(
          firstName: "Chadler",
          lastName: "Big",
          birthYear: 2003,
          birthMonth: 12,
          birthDay: 1,
        ).toJson();
        final v2ToV4 = migration.fromJson(v2Json);
        expect(
          v2ToV4,
          const VerThree(
            firstName: "Chadler",
            lastName: "Big",
            birthYear: 2003,
            birthMonth: 12,
            birthDay: 1,
            prefersCakeToBeer: true,
          ),
        );
      });
    },
  );

  group(
    "weird bits",
    () {
      test("falls back to a version correctly", () {
        final migrator = JsonMigration.singleComplete(
          versionKey: "version",
          usesVersionKey: false,
          load: NoVersionIndicatorVerOne.fromJson,
          makeDefault: null,
        );
        const val = NoVersionIndicatorVerOne(
          name: "name",
          birthYear: 3,
          birthMonth: 3,
          birthDay: 3,
        );
        expect(migrator.fromJson(val.toJson()), val);
      });

      const defaultV1 = VerOne(
        name: "Constant",
        birthYear: 1,
        birthMonth: 2,
        birthDay: 3,
      );

      const noVersionV1Json = {
        "name": "jimmy",
        "birthYear": 3,
        "birthMonth": 3,
        "birthDay": 3,
      };

      test(
        "throws when version not present and no fallback and no default",
        () {
          final migrator = JsonMigration.singleComplete(
            versionKey: "version",
            usesVersionKey: true,
            load: VerOne.fromJson,
            makeDefault: null,
          );
          expect(
            () {
              migrator.fromJson(noVersionV1Json);
            },
            throwsA(stringContainsInOrder(["version key not present"])),
          );
        },
      );
      test(
        "returns default when version not present and no fallback",
        () {
          final migrator = JsonMigration.singleComplete(
            versionKey: "version",
            usesVersionKey: true,
            load: VerOne.fromJson,
            makeDefault: () => defaultV1,
          );
          expect(
            migrator.fromJson(noVersionV1Json),
            defaultV1,
          );
        },
      );

      const invalidV1Json = {
        "version": 1,
        "name": "jimmy",
        "birthYear": "FREDERICK",
        "birthMonth": 3,
        "birthDay": 3,
      };

      test(
        "throws when invalid JSON and no default",
        () {
          final migrator = JsonMigration.singleComplete(
            versionKey: "version",
            usesVersionKey: true,
            load: VerOne.fromJson,
            makeDefault: null,
          );
          expect(
            () {
              migrator.fromJson(invalidV1Json);
            },
            throwsA(stringContainsInOrder(["exception during migration"])),
          );
        },
      );
      test(
        "returns default when invalid JSON and no default",
        () {
          final migrator = JsonMigration.singleComplete(
            versionKey: "version",
            usesVersionKey: true,
            load: VerOne.fromJson,
            makeDefault: () => defaultV1,
          );
          expect(
            migrator.fromJson(invalidV1Json),
            defaultV1,
          );
        },
      );

      const strVersionV1Json = {
        "version": "FREDERICK",
        "name": "jimmy",
        "birthYear": 3,
        "birthMonth": 3,
        "birthDay": 3,
      };

      test(
        "throws when version present but not integer and no default",
        () {
          final migrator = JsonMigration.singleComplete(
            versionKey: "version",
            usesVersionKey: true,
            load: VerOne.fromJson,
            makeDefault: null,
          );
          expect(
            () {
              migrator.fromJson(strVersionV1Json);
            },
            throwsA(stringContainsInOrder(["not an integer"])),
          );
        },
      );
      test(
        "returns default when version present but not integer",
        () {
          final migrator = JsonMigration.singleComplete(
            versionKey: "version",
            usesVersionKey: true,
            load: VerOne.fromJson,
            makeDefault: () => defaultV1,
          );
          expect(
            migrator.fromJson(strVersionV1Json),
            defaultV1,
          );
        },
      );
      test(
        "throws when version OOB",
        () {
          final migrator = JsonMigration.singleComplete(
            versionKey: "version",
            usesVersionKey: true,
            load: VerOne.fromJson,
            makeDefault: null,
          );
          expect(
            () {
              migrator.fromJson({
                "version": 2,
                "name": "jimmy",
                "birthYear": 3,
                "birthMonth": 3,
                "birthDay": 3,
              });
            },
            throwsA(stringContainsInOrder(["out of bounds"])),
          );
          expect(
            () {
              migrator.fromJson({
                "version": 0,
                "name": "jimmy",
                "birthYear": 3,
                "birthMonth": 3,
                "birthDay": 3,
              });
            },
            throwsA(stringContainsInOrder(["out of bounds"])),
          );
        },
      );
    },
  );
}
