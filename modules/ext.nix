{
  flake.lib.ext = let
    path = "/ext";
  in {
    volume = "ext";
    inherit path;

    # The one root that may be deleted without losing anything: everything
    # under it is refetched or rebuilt by the tool that owns it. Whatever sits
    # beside it on the volume is there because no other copy exists.
    cache = "${path}/cache";

    # Volume UUID: a property of the volume, so it survives wiping the Mac.
    # Set once, after creating the volume:
    #   diskutil eraseDisk APFS ext GPT /dev/diskN
    #   diskutil info -plist /Volumes/ext | plutil -extract VolumeUUID raw -
    uuid = "A50C22EB-BC7D-4385-B426-B2701BEC9491";
  };
}
