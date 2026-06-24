#!/usr/bin/env bash
# Layout-independent rofi Apps search.
#
# Adds a Cyrillic key-position transliteration of each app's Name as a Keyword
# in an override .desktop entry, so rofi's Apps tab (drun, drun-match-fields=all)
# finds Latin-named apps while you type on the RU layout: pressing the keys that
# spell "firefox" on EN produces "ашкуащч" on RU, and that string is now a
# keyword on Firefox. Native Cyrillic app names keep matching as-is, and rofi
# still launches via drun (no Exec re-parsing here).
#
# Regenerated on every home-manager switch. Only removes entries it wrote
# (X-RofiTranslit marker) — never user-authored .desktop files.
set -euo pipefail

# Self-check: the mapping is the one piece of real logic worth guarding.
if [ "${1:-}" = selftest ]; then
  @perl@ -CSDA - <<'PERL'
my %m=(a=>'ф',b=>'и',c=>'с',d=>'в',e=>'у',f=>'а',g=>'п',h=>'р',i=>'ш',j=>'о',
 k=>'л',l=>'д',m=>'ь',n=>'т',o=>'щ',p=>'з',q=>'й',r=>'к',s=>'ы',t=>'е',u=>'г',
 v=>'м',w=>'ц',x=>'ч',y=>'н',z=>'я');
my $s=lc "Firefox"; $s=~s/([a-z])/$m{$1}/g;
die "translit broken: got $s" unless $s eq "ашкуащч";
print "ok\n";
PERL
  exit 0
fi

out="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$out"

# Drop the previous generation so removed/renamed apps don't linger.
if compgen -G "$out/*.desktop" >/dev/null 2>&1; then
  grep -lF "X-RofiTranslit=1" "$out"/*.desktop 2>/dev/null | xargs -r rm -f
fi

# Activation env is minimal, so don't rely on XDG_DATA_DIRS being set/complete —
# always include the Nix profile + system dirs where .desktop files actually live.
me="$(id -un)"
XDG_DATA_DIRS="${XDG_DATA_DIRS:-}:$HOME/.nix-profile/share:/etc/profiles/per-user/$me/share:/run/current-system/sw/share:/usr/share"
export XDG_DATA_DIRS out

@perl@ -CSDA - <<'PERL'
use strict; use warnings;
my $out = $ENV{out};
my %m=(a=>'ф',b=>'и',c=>'с',d=>'в',e=>'у',f=>'а',g=>'п',h=>'р',i=>'ш',j=>'о',
 k=>'л',l=>'д',m=>'ь',n=>'т',o=>'щ',p=>'з',q=>'й',r=>'к',s=>'ы',t=>'е',u=>'г',
 v=>'м',w=>'ц',x=>'ч',y=>'н',z=>'я');
sub ru { my $s=lc shift; $s=~s/([a-z])/$m{$1}/g; $s }

# Existing files in $out are user-authored (ours were just deleted) — never clobber.
my %skip;
if (opendir my $d, $out) { /\.desktop$/ and $skip{$_}=1 for readdir $d }

my %done;  # first match wins = XDG priority order
for my $dir (map { "$_/applications" } split /:/, $ENV{XDG_DATA_DIRS}) {
  opendir my $dh, $dir or next;
  for my $f (sort readdir $dh) {
    next unless $f =~ /\.desktop$/;
    next if $skip{$f} or $done{$f}++;
    open my $in, '<:utf8', "$dir/$f" or next;
    local $/; my $c = <$in>; close $in;
    # First Name= after the [Desktop Entry] header (actions come later).
    my ($name) = $c =~ /^\[Desktop Entry\].*?^Name=([^\n]*)/ms or next;
    my $kw = ru($name);
    next if $kw eq lc $name;  # pure-Cyrillic/symbol name: nothing to add
    if ($c =~ /^\[Desktop Entry\].*?^Keywords=/ms) {
      $c =~ s/(^\[Desktop Entry\].*?^Keywords=[^\n]*)/$1;$kw;/ms;
    } else {
      $c =~ s/^(\[Desktop Entry\][^\n]*\n)/$1Keywords=$kw;\n/m;
    }
    $c =~ s/^(\[Desktop Entry\][^\n]*\n)/${1}X-RofiTranslit=1\n/m;
    open my $w, '>:utf8', "$out/$f" or next;
    print $w $c; close $w;
  }
}
PERL
