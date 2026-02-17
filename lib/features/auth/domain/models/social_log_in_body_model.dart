class SocialLogInBodyModel {
  String? email;
  String? token;
  String? uniqueId;
  String? medium;
  int? accessToken;
  String? loginType;
  String? verified;
  String? guestId;
  String? idToken;

  SocialLogInBodyModel({this.email, this.token, this.uniqueId, this.medium, this.accessToken, this.loginType, this.verified, this.guestId, this.idToken});

  SocialLogInBodyModel.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    token = json['token'];
    uniqueId = json['unique_id'];
    medium = json['medium'];
    accessToken = json['access_token'];
    loginType = json['login_type'];
    verified = json['verified'];
    guestId = json['guest_id'];
    idToken = json['id_token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['token'] = token;
    data['unique_id'] = uniqueId;
    data['medium'] = medium;
    if(accessToken != null) {
      data['access_token'] = accessToken;
    }
    data['login_type'] = loginType;
    if(verified != null) {
      data['verified'] = verified;
    }
    if(guestId != null) {
      data['guest_id'] = guestId;
    }
    // Pour Apple Sign-In : le backend attend obligatoirement id_token (JWT). On envoie
    // l'identity token en priorité, sinon l'authorization code, et on garantit que la clé existe.
    final String? valueForIdToken = (idToken != null && idToken!.isNotEmpty) ? idToken : (token != null && token!.isNotEmpty ? token : null);
    if (valueForIdToken != null) {
      data['id_token'] = valueForIdToken;
    }
    // Certains backends lisent aussi la clé camelCase
    if (valueForIdToken != null && medium == 'apple') {
      data['idToken'] = valueForIdToken;
    }
    return data;
  }
}
