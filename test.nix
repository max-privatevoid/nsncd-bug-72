{ nixosTest, bubblewrap }:

let
  base = {
    services.nscd.enableNsncd = true;
    users = {
      users = {
        working = {
          isNormalUser = true;
          extraGroups = [ "gworking" ];
        };
        broken = {
          isNormalUser = true;
          extraGroups = [ "gbroken" ];
        };
      };
      groups = {
        gworking.gid = 2147483647;
        gbroken.gid = 2147483648;
      };
    };
  };

  applyPatch = patch: old: {
    patches = (old.patches or []) ++ [ patch ];
  };

  nsncdOverlay = final: prev: {
    nsncd = prev.nsncd.overrideAttrs (applyPatch ./u32.patch);
  };

  sandboxed = "${bubblewrap}/bin/bwrap --bind / / --bind /dev/null /etc/group";
in

nixosTest {
  name = "nsncd-bug-72";
  nodes = {
    stock.imports = [ base ];
    patched.imports = [ base ];
    patched.nixpkgs.overlays = [ nsncdOverlay ];
  };
  testScript = /*python*/ ''
    start_all()

    with subtest("stock cannot see high GIDs"):
      stock.wait_for_unit("nscd.service")
      stock.wait_until_succeeds("${sandboxed} id working | grep gworking")
      stock.fail("${sandboxed} id broken | grep gbroken")

    with subtest("patched can see high GIDs"):
      patched.wait_for_unit("nscd.service")
      patched.wait_until_succeeds("${sandboxed} id working | grep gworking")
      patched.succeed("${sandboxed} id broken | grep gbroken")
  '';
}
