import 'dart:convert';

UserProfile userProfileFromJson(String str) =>
    UserProfile.fromJson(json.decode(str));

String userProfileToJson(UserProfile data) => json.encode(data.toJson());

class UserProfile {
  final String nome;
  final String cognome;
  final String email;
  final String? dataNascita;
  final String? codFiscale;
  final String? referral;
  final String? parentId;
  final String? numTel;

  // Seller fields
  final bool? isSeller;
  final String? sellerStatus; // 'pending', 'verified', 'rejected'
  final String? stripeAccountId;
  final DateTime? sellerVerifiedAt;

  UserProfile({
    required this.nome,
    required this.cognome,
    required this.email,
    this.dataNascita,
    this.codFiscale,
    this.referral,
    this.parentId,
    this.numTel,
    this.isSeller,
    this.sellerStatus,
    this.stripeAccountId,
    this.sellerVerifiedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        nome: json["nome"] ?? '',
        cognome: json["cognome"] ?? '',
        email: json["email"] ?? '',
        dataNascita: json["dataNascita"],
        codFiscale: json["codFiscale"],
        referral: json["referral"]?.toString(),
        parentId: json["parentId"],
        numTel: json["numTel"],
        isSeller: json["isSeller"],
        sellerStatus: json["sellerStatus"],
        stripeAccountId: json["stripeAccountId"],
        sellerVerifiedAt: json["sellerVerifiedAt"] != null
            ? DateTime.parse(json["sellerVerifiedAt"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "nome": nome,
        "cognome": cognome,
        "email": email,
        "dataNascita": dataNascita,
        "codFiscale": codFiscale,
        "referral": referral,
        "parentId": parentId,
        "numTel": numTel,
        "isSeller": isSeller,
        "sellerStatus": sellerStatus,
        "stripeAccountId": stripeAccountId,
        "sellerVerifiedAt": sellerVerifiedAt?.toIso8601String(),
      };

  UserProfile copyWith({
    String? nome,
    String? cognome,
    String? email,
    String? dataNascita,
    String? codFiscale,
    String? referral,
    String? parentId,
    String? numTel,
    bool? isSeller,
    String? sellerStatus,
    String? stripeAccountId,
    DateTime? sellerVerifiedAt,
  }) {
    return UserProfile(
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      email: email ?? this.email,
      dataNascita: dataNascita ?? this.dataNascita,
      codFiscale: codFiscale ?? this.codFiscale,
      referral: referral ?? this.referral,
      parentId: parentId ?? this.parentId,
      numTel: numTel ?? this.numTel,
      isSeller: isSeller ?? this.isSeller,
      sellerStatus: sellerStatus ?? this.sellerStatus,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      sellerVerifiedAt: sellerVerifiedAt ?? this.sellerVerifiedAt,
    );
  }
}
