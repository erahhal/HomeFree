{
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  openldap,
  coreutils,
  gnused,
  gnugrep,
  lib,
}:
stdenv.mkDerivation {
  name = "ldap-auth-sh";

  src = fetchFromGitHub {
    owner = "efficiosoft";
    repo = "ldap-auth-sh";
    rev = "93b2c00413942908139e37c7432a12bcb705ac87";
    sha256 = "1pymp6ki353aqkigr89g7hg5x1mny68m31c3inxf1zr26n5s2kz8";
  };

  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/etc
    cat > $out/etc/home-assistant.cfg << 'EOF'
    CLIENT="ldapsearch"
    SERVER="ldap://localhost:3389"
    USERDN="cn=$(ldap_dn_escape "$username"),ou=users,dc=ldap,dc=goauthentik,dc=io"
    PW=$password

    BASEDN="dc=ldap,dc=goauthentik,dc=io"
    SCOPE="subtree"
    FILTER="(&(objectClass=user)(sAMAccountName=$(ldap_dn_escape "$username")))"
    # USERNAME_PATTERN='^[a-z|A-Z|0-9|_|-|.|@]+$'
    on_auth_success() {
      # print the meta entries for use in HA
      if echo "$output" | grep -qE '^(dn|DN):: '; then
          # ldapsearch base64 encodes non-ascii
          output=$(echo "$output" | sed -n -e "s/^\(dn\|DN\)\s*::\s*\(.*\)$/\2/p" | base64 -d)
      else
          output=$(echo "$output" | sed -n -e "s/^\(dn\|DN\)\s*:\s*\(.*\)$/\2/p")
      fi

      name=$(echo "$output" | sed -nr 's/^cn=([^,]+).*/\1/Ip')
      [ -z "$name" ] || echo "name=$name"
    }
    on_auth_failure() {
      echo "$output"
    }
    EOF
    install -D -m755 ldap-auth.sh $out/bin/ldap-auth.sh
    wrapProgram $out/bin/ldap-auth.sh \
      --prefix PATH : ${
        lib.makeBinPath [
          openldap
          coreutils
          gnused
          gnugrep
        ]
      } \
      --add-flags "$out/etc/home-assistant.cfg"
  '';
}

