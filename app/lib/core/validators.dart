// Shared input validation rules, so the same policy is enforced everywhere it
// applies (e.g. sign-up and the settings password change must agree).

/// Password policy: at least 10 characters, including at least one letter and
/// one digit. Other characters (symbols) are allowed.
final RegExp passwordRegex = RegExp(r"^(?=.*[A-Za-z])(?=.*\d).{10,}$");

/// Whether [value] satisfies the password policy above.
bool isValidPassword(String value) => passwordRegex.hasMatch(value);

/// Email shape check, used by sign-up, sign-in, and the settings email change so
/// they all accept the same thing (a local part, an @, a domain with a TLD).
final RegExp emailRegex = RegExp(
  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
);

/// Whether [value] looks like a valid email address.
bool isValidEmail(String value) => emailRegex.hasMatch(value);
