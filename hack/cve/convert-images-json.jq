# Converts a list of images collected for airgapped installation into
# konvoy images.json format that can be submitted into CVE reporter.
# Running this script requires specifying jq argument `NKP_CATALOG_VERSION`.
# Example:
# jq --arg NKP_CATALOG_VERSION v2.1.0 -f .

# parse_image converts docker image reference from single line format to
# structured json object in konvoy images.json format.
def parse_image(i):
  split(":") as $image_and_tag
  | $image_and_tag[0] | split("/") as $parsed
  | {
    scheme: "https",
    registry: $parsed[0],
    image: $parsed[1:] | join("/"),
    tag: $image_and_tag[1],
  }
;

{
  konvoyVersion: $NKP_CATALOG_VERSION,
  images: [
    .[] | parse_image(.)
  ],
}
