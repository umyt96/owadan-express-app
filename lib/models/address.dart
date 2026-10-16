class Address {
  final int id;
  final String streetAddress;
  final String? apartmentAddress;
  final String country;
  final String phone;
  final bool isDefault;
  /// Ссылка на карту, если при оформлении указали местоположение по GPS.
  final String mapUrl;

  Address({
    required this.id,
    required this.streetAddress,
    this.apartmentAddress,
    required this.country,
    required this.phone,
    required this.isDefault,
    this.mapUrl = '',
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'],
        streetAddress: json['street_address'] ?? '',
        apartmentAddress: json['apartment_address'],
        country: json['country'] ?? '',
        phone: json['phone'] ?? '',
        isDefault: json['default'] ?? false,
        mapUrl: json['map_url'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'street_address': streetAddress,
        'apartment_address': apartmentAddress,
        'country': country,
        'phone': phone,
        'default': isDefault,
      };
}
