import '../model/invitation.dart';
import '../model/member_profile_data.dart';

class OnboardingSelection {
  final Invitation? invitation;
  final MemberProfileData? memberProfile;

  const OnboardingSelection._({
    this.invitation,
    this.memberProfile,
  });

  factory OnboardingSelection.invitation(Invitation invitation) {
    return OnboardingSelection._(invitation: invitation);
  }

  factory OnboardingSelection.memberProfile(MemberProfileData profile) {
    return OnboardingSelection._(memberProfile: profile);
  }

  bool get hasInvitation => invitation != null;
  bool get hasMemberProfile => memberProfile != null;
}
