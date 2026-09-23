/// Accumulates the sign-up fields as the user moves through the steps.
/// The account (auth user + profile) is created only at the final step.
class SignUpData {
  SignUpData({required this.email, required this.password});

  final String email;
  final String password;
  DateTime? birthDate;
  String? gender;
}
