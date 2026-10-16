class ContactInfo {
  final String? address;
  final String? contact;
  final String? contact2;
  final String? mail;
  final String? instagram;
  final String? facebook;
  final String? twitter;
  final String? whatsapp;
  final String? telegram;
  final String? vk;

  ContactInfo({
    this.address,
    this.contact,
    this.contact2,
    this.mail,
    this.instagram,
    this.facebook,
    this.twitter,
    this.whatsapp,
    this.telegram,
    this.vk,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
        address: json['address'],
        contact: json['contact'],
        contact2: json['contact2'],
        mail: json['mail'],
        instagram: json['instagram'],
        facebook: json['facebook'],
        twitter: json['twitter'],
        whatsapp: json['whatsapp'],
        telegram: json['telegram'],
        vk: json['vk'],
      );
}
