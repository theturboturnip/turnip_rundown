// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_migration_test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoVersionIndicatorVerOne _$NoVersionIndicatorVerOneFromJson(
        Map<String, dynamic> json) =>
    NoVersionIndicatorVerOne(
      name: json['name'] as String,
      birthYear: (json['birthYear'] as num).toInt(),
      birthMonth: (json['birthMonth'] as num).toInt(),
      birthDay: (json['birthDay'] as num).toInt(),
    );

Map<String, dynamic> _$NoVersionIndicatorVerOneToJson(
        NoVersionIndicatorVerOne instance) =>
    <String, dynamic>{
      'name': instance.name,
      'birthYear': instance.birthYear,
      'birthMonth': instance.birthMonth,
      'birthDay': instance.birthDay,
    };

VerOne _$VerOneFromJson(Map<String, dynamic> json) => VerOne(
      name: json['name'] as String,
      birthYear: (json['birthYear'] as num).toInt(),
      birthMonth: (json['birthMonth'] as num).toInt(),
      birthDay: (json['birthDay'] as num).toInt(),
    );

Map<String, dynamic> _$VerOneToJson(VerOne instance) => <String, dynamic>{
      'version': instance.version,
      'name': instance.name,
      'birthYear': instance.birthYear,
      'birthMonth': instance.birthMonth,
      'birthDay': instance.birthDay,
    };

VerTwo _$VerTwoFromJson(Map<String, dynamic> json) => VerTwo(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      birthYear: (json['birthYear'] as num).toInt(),
      birthMonth: (json['birthMonth'] as num).toInt(),
      birthDay: (json['birthDay'] as num).toInt(),
    );

Map<String, dynamic> _$VerTwoToJson(VerTwo instance) => <String, dynamic>{
      'version': instance.version,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'birthYear': instance.birthYear,
      'birthMonth': instance.birthMonth,
      'birthDay': instance.birthDay,
    };

VerThree _$VerThreeFromJson(Map<String, dynamic> json) => VerThree(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      birthYear: (json['birthYear'] as num).toInt(),
      birthMonth: (json['birthMonth'] as num).toInt(),
      birthDay: (json['birthDay'] as num).toInt(),
      prefersCakeToBeer: json['prefersCakeToBeer'] as bool,
    );

Map<String, dynamic> _$VerThreeToJson(VerThree instance) => <String, dynamic>{
      'version': instance.version,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'birthYear': instance.birthYear,
      'birthMonth': instance.birthMonth,
      'birthDay': instance.birthDay,
      'prefersCakeToBeer': instance.prefersCakeToBeer,
    };

VerFour _$VerFourFromJson(Map<String, dynamic> json) => VerFour(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      birthday: DateTime.parse(json['birthday'] as String),
      prefersCakeToBeer: json['prefersCakeToBeer'] as bool,
    );

Map<String, dynamic> _$VerFourToJson(VerFour instance) => <String, dynamic>{
      'version': instance.version,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'birthday': dtToStr(instance.birthday),
      'prefersCakeToBeer': instance.prefersCakeToBeer,
    };
