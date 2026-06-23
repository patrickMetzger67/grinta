import '../model/invitation.dart';
import '../model/player.dart';

class OnboardingSelection {
  final Invitation? invitation;
  final Player? memberProfile;

  const OnboardingSelection._({
    this.invitation,
    this.memberProfile,
  });

  factory OnboardingSelection.invitation(Invitation invitation) {
    return OnboardingSelection._(invitation: invitation);
  }

  factory OnboardingSelection.memberProfile(Player profile) {
    return OnboardingSelection._(memberProfile: profile);
  }

  bool get hasInvitation => invitation != null;
  bool get hasMemberProfile => memberProfile != null;
}
