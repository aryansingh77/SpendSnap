import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserProfileModel extends Equatable {
  const UserProfileModel({
    required this.uid,
    required this.name,
    required this.email,
    this.monthlyIncome = 0.0,
    this.currency = '₹',
  });

  final String uid;
  final String name;
  final String email;
  final double monthlyIncome;
  final String currency;

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'monthlyIncome': monthlyIncome,
    'currency': currency,
  };

  factory UserProfileModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfileModel(
      uid: doc.id,
      name: data['name'] as String,
      email: data['email'] as String,
      monthlyIncome: (data['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? '₹',
    );
  }

  UserProfileModel copyWith({String? name, double? monthlyIncome}) =>
      UserProfileModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        monthlyIncome: monthlyIncome ?? this.monthlyIncome,
        currency: currency,
      );

  @override
  List<Object?> get props => [uid, name, email, monthlyIncome, currency];
}
