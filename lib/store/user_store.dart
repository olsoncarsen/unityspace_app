import 'dart:typed_data';

import 'package:unityspace/models/user_models.dart';
import 'package:unityspace/service/user_service.dart' as api;
import 'package:wstore/wstore.dart';

class UserStore extends GStore {
  static UserStore? _instance;

  factory UserStore() => _instance ??= UserStore._();

  UserStore._();

  User? user;
  Organization? organization;

  bool get hasLicense {
    final license = organization?.licenseEndDate;
    if (license == null) return false;
    return license.isAfter(DateTime.now());
  }

  bool get hasTrial {
    final trial = organization?.trialEndDate;
    if (trial == null) return false;
    return trial.isAfter(DateTime.now());
  }

  bool get trialNeverStarted {
    return organization?.trialEndDate == null;
  }

  bool get isOrganizationOwner {
    if (user == null || organization == null) return false;
    return organization?.ownerId == user?.id;
  }

  Map<int, OrganizationMember> get organizationMembers {
    final members = organization?.members ?? [];
    return members.fold(<int, OrganizationMember>{}, (map, member) {
      map[member.id] = member;
      return map;
    });
  }

  Future<void> getUserData() async {
    final userData = await api.getUserData();
    final user = User.fromResponse(userData);
    setStore(() {
      this.user = user;
    });
  }

  Future<void> getOrganizationData() async {
    final organizationData = await api.getOrganizationData();
    final organization = Organization.fromResponse(organizationData);
    setStore(() {
      this.organization = organization;
    });
  }

  Future<void> removeUserAvatar() async {
    final userData = await api.removeUserAvatar();
    final user = User.fromResponse(userData);
    _updateUserAtStore(user);
  }

  Future<void> setUserAvatar(final Uint8List avatarImage) async {
    final userData = await api.setUserAvatar(avatarImage);
    final user = User.fromResponse(userData);
    _updateUserAtStore(user);
  }

  Future<void> setUserName(final String userName) async {
    final userData = await api.setUserName(userName);
    final user = User.fromResponse(userData);
    _updateUserAtStore(user);
  }

  Future<void> setUserGitHubLink(final String githubLink) async {
    final userData = await api.setUserGitHubLink(githubLink);
    final user = User.fromResponse(userData);
    _updateUserAtStore(user);
  }

  Future<void> setUserTelegramLink(final String link) async {
    final userData = await api.setUserTelegramLink(link);
    final user = User.fromResponse(userData);
    _updateUserAtStore(user);
  }

  Future<void> setUserBirthday(final DateTime? birthday) async {
    String? birthdayString;
    if (birthday != null) {
      birthdayString = DateTime.utc(
        birthday.year,
        birthday.month,
        birthday.day,
      ).toIso8601String();
    }
    final userData = await api.setUserBirthday(birthdayString);
    final user = User.fromResponse(userData);
    _updateUserAtStore(user);
  }

  void _updateUserAtStore(final User user) {
    setStore(() {
      this.user = user;
      final organizationMembersCount = organization?.members.length ?? 0;
      for (int i = 0; i < organizationMembersCount; i++) {
        final member = organization!.members[i];
        if (member.id == user.id) {
          organization!.members[i] = OrganizationMember.fromUser(user);
          break;
        }
      }
    });
  }

  @override
  void clear() {
    super.clear();
    setStore(() {
      user = null;
      organization = null;
    });
  }
}
