import 'dart:convert';

/// Alle Daten einer Visitenkarte.
///
/// Wird als JSON ausschliesslich auf dem Geraet gespeichert - es gibt keinen
/// Server und keinen Netzwerkzugriff.
class ContactCard {
  const ContactCard({
    this.firstName = '',
    this.lastName = '',
    this.jobTitle = '',
    this.company = '',
    this.street = '',
    this.postalCode = '',
    this.city = '',
    this.country = '',
    this.phone = '',
    this.mobile = '',
    this.email = '',
    this.website = '',
    this.photoPath,
  });

  factory ContactCard.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] as String?)?.trim() ?? '';
    final photo = (json['photoPath'] as String?)?.trim();
    return ContactCard(
      firstName: read('firstName'),
      lastName: read('lastName'),
      jobTitle: read('jobTitle'),
      company: read('company'),
      street: read('street'),
      postalCode: read('postalCode'),
      city: read('city'),
      country: read('country'),
      phone: read('phone'),
      mobile: read('mobile'),
      email: read('email'),
      website: read('website'),
      photoPath: (photo == null || photo.isEmpty) ? null : photo,
    );
  }

  /// Liest eine Karte aus einem JSON-String. Bei defekten Daten wird eine
  /// leere Karte zurueckgegeben, damit die App immer startet.
  factory ContactCard.decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return ContactCard.fromJson(decoded);
    } on FormatException {
      // Ignorieren - es wird die leere Karte verwendet.
    }
    return const ContactCard();
  }

  final String firstName;
  final String lastName;

  /// Position / Titel, z. B. "Geschaeftsfuehrer".
  final String jobTitle;
  final String company;
  final String street;
  final String postalCode;
  final String city;
  final String country;
  final String phone;
  final String mobile;
  final String email;
  final String website;

  /// Absoluter Pfad zum Foto im App-Verzeichnis (null = kein Foto).
  final String? photoPath;

  String get fullName =>
      [firstName, lastName].where((p) => p.isNotEmpty).join(' ');

  /// "12345 Stadt" bzw. nur der vorhandene Teil.
  String get cityLine =>
      [postalCode, city].where((p) => p.isNotEmpty).join(' ');

  /// Mehrzeilige Anschrift fuer die Anzeige.
  String get addressBlock => [
    street,
    [cityLine, country].where((p) => p.isNotEmpty).join(', '),
  ].where((p) => p.isNotEmpty).join('\n');

  /// Initialen als Platzhalter, solange kein Foto hinterlegt ist.
  String get initials {
    final letters = [
      firstName,
      lastName,
    ].where((p) => p.isNotEmpty).map((p) => p.substring(0, 1)).join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }

  /// true, wenn noch nichts eingetragen wurde (erster App-Start).
  bool get isEmpty =>
      fullName.isEmpty &&
      company.isEmpty &&
      jobTitle.isEmpty &&
      email.isEmpty &&
      phone.isEmpty &&
      mobile.isEmpty;

  ContactCard copyWith({
    String? firstName,
    String? lastName,
    String? jobTitle,
    String? company,
    String? street,
    String? postalCode,
    String? city,
    String? country,
    String? phone,
    String? mobile,
    String? email,
    String? website,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return ContactCard(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      street: street ?? this.street,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      website: website ?? this.website,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'firstName': firstName,
    'lastName': lastName,
    'jobTitle': jobTitle,
    'company': company,
    'street': street,
    'postalCode': postalCode,
    'city': city,
    'country': country,
    'phone': phone,
    'mobile': mobile,
    'email': email,
    'website': website,
    'photoPath': photoPath,
  };

  String encode() => jsonEncode(toJson());
}
