{
  flake.lib.ext = {
    volume = "ext";
    path = "/ext";

    # Volume UUID: a property of the volume, so it survives wiping the Mac.
    # Set once, after creating the volume:
    #   diskutil eraseDisk APFS ext GPT /dev/diskN
    #   diskutil info -plist /Volumes/ext | plutil -extract VolumeUUID raw -
    uuid = "A50C22EB-BC7D-4385-B426-B2701BEC9491";
  };
}
