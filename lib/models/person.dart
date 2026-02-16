class Person {
  final String name;
  final String? nameOriginal;
  final String? codeName;
  final int? physicPower;
  final int? magicPower;
  final int? utilityPower;
  final int? totalPower;
  final String? dob;
  final String? race;
  final String? attributes;
  final String? gender;
  final String? assSize;
  final String? boobsSize;
  final int? heightCm;
  final int? weightKg;
  final String? profession;
  final String? combat;
  final String? favoriteFoods;
  final String? job;
  final String? physics;
  final String? knownAs;
  final String? personality;
  final String? interest;
  final String? likes;
  final String? dislikes;
  final String? concubine;
  final String? faction;
  final int? armyId;
  final String? armyName;
  final int? deptId;
  final String? deptName;
  final int? age;
  final String? proxy;
  final String? originArmyName;

  Person({
    required this.name,
    this.nameOriginal,
    this.codeName,
    this.physicPower,
    this.magicPower,
    this.utilityPower,
    this.totalPower,
    this.dob,
    this.race,
    this.attributes,
    this.gender,
    this.assSize,
    this.boobsSize,
    this.heightCm,
    this.weightKg,
    this.profession,
    this.combat,
    this.favoriteFoods,
    this.job,
    this.physics,
    this.knownAs,
    this.personality,
    this.interest,
    this.likes,
    this.dislikes,
    this.concubine,
    this.faction,
    this.armyId,
    this.armyName,
    this.deptId,
    this.deptName,
    this.age,
    this.proxy,
    this.originArmyName,
  });

  String get id => name;

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      name: json['name'] as String,
      nameOriginal: json['nameOriginal'] as String?,
      codeName: json['codeName'] as String?,
      physicPower: json['physicPower'] as int?,
      magicPower: json['magicPower'] as int?,
      utilityPower: json['utilityPower'] as int?,
      totalPower: json['totalPower'] as int?,
      dob: json['dob'] as String?,
      race: json['race'] as String?,
      attributes: json['attributes'] as String?,
      gender: json['gender'] as String?,
      assSize: json['assSize'] as String?,
      boobsSize: json['boobsSize'] as String?,
      heightCm: json['heightCm'] as int?,
      weightKg: json['weightKg'] as int?,
      profession: json['profession'] as String?,
      combat: json['combat'] as String?,
      favoriteFoods: json['favoriteFoods'] as String?,
      job: json['job'] as String?,
      physics: json['physics'] as String?,
      knownAs: json['knownAs'] as String?,
      personality: json['personality'] as String?,
      interest: json['interest'] as String?,
      likes: json['likes'] as String?,
      dislikes: json['dislikes'] as String?,
      concubine: json['concubine'] as String?,
      faction: json['faction'] as String?,
      armyId: json['armyId'] as int?,
      armyName: json['armyName'] as String?,
      deptId: json['deptId'] as int?,
      deptName: json['deptName'] as String?,
      age: json['age'] as int?,
      proxy: json['proxy'] as String?,
      originArmyName: json['originArmyName'] as String?,
    );
  }

  Person copyWith({int? totalPower}) {
    return Person(
      name: name,
      nameOriginal: nameOriginal,
      codeName: codeName,
      physicPower: physicPower,
      magicPower: magicPower,
      utilityPower: utilityPower,
      totalPower: totalPower ?? this.totalPower,
      dob: dob,
      race: race,
      attributes: attributes,
      gender: gender,
      assSize: assSize,
      boobsSize: boobsSize,
      heightCm: heightCm,
      weightKg: weightKg,
      profession: profession,
      combat: combat,
      favoriteFoods: favoriteFoods,
      job: job,
      physics: physics,
      knownAs: knownAs,
      personality: personality,
      interest: interest,
      likes: likes,
      dislikes: dislikes,
      concubine: concubine,
      faction: faction,
      armyId: armyId,
      armyName: armyName,
      deptId: deptId,
      deptName: deptName,
      age: age,
      proxy: proxy,
      originArmyName: originArmyName,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'nameOriginal': nameOriginal,
    'codeName': codeName,
    'physicPower': physicPower,
    'magicPower': magicPower,
    'utilityPower': utilityPower,
    'totalPower': totalPower,
    'dob': dob,
    'race': race,
    'attributes': attributes,
    'gender': gender,
    'assSize': assSize,
    'boobsSize': boobsSize,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'profession': profession,
    'combat': combat,
    'favoriteFoods': favoriteFoods,
    'job': job,
    'physics': physics,
    'knownAs': knownAs,
    'personality': personality,
    'interest': interest,
    'likes': likes,
    'dislikes': dislikes,
    'concubine': concubine,
    'faction': faction,
    'armyId': armyId,
    'armyName': armyName,
    'deptId': deptId,
    'deptName': deptName,
    'age': age,
    'proxy': proxy,
    'originArmyName': originArmyName,
  };
}
