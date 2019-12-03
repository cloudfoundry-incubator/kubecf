# The Naming Of Docker Images in kubecf.

When running a kubecf instance, all of the job containers in the pods
for the instance groups use a docker image. This image provides that job and
the associated packages.

The names of these docker images are structured like so:

    docker.io/cfcontainerization/nats:opensuse-42.3-36.g03b4653-30.80-7.0.0_362.g9610e90b-26
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Registry                     Role Tag

The tag is further structured as:

    opensuse-42.3-36.g03b4653-30.80-7.0.0_362.g9610e90b-26
    ~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~
    Stemcell OS   Stemcell version                      Role version

The various components above come from a number of places in the
Chart, chart values, deployment manifest, etc. When an element can be
provided by multiple places, the first place (in the order given below)
with a defined value (i.e. not nil) is used.

|Element               |Origin                                |
|---                   |---                                   |
|Role                  |`instance_groups.[].name`             |
|Registry              |`releases.(role).url`                 |
|                      |`releases.defaults.url`               |
|Role version          |`releases.(role).version`             |
|                      |`releases.defaults.version`           |
|Stemcell OS           |`releases.(role).stemcell.os`         |
|                      |`releases.defaults.stemcell.os`       |
|Stemcell version      |`releases.(role).stemcell.version`    |
|                      |`releases.defaults.stemcell.version`  |

__Attention__: The stemcell information put into the Chart / manifest
has to match the stemcell baked into the docker image by the CI image
builder at the time of building.

This information is easiest to extract from the tag for the used
docker image.

Some, but not all, of this information can also be extracted from the
labels of the used docker image. For image __foo__, invoke:

    docker inspect -f '{{ index .Config.Labels "stemcell-version" }}' foo
    docker inspect -f '{{ index .Config.Labels "stemcell-flavor" }}' foo

The __flavor__ plus the part of the __version__ up to the first dash
character (`-`) provides the stemcell OS, and the remainder of the
version provides a prefix for the stemcell version.

For example, the version and flavor strings

    42.3-36.g03b4653-30.80
    opensuse

yield __opensuse-42.3__ and __36.g03b4653-30.80__ for os and version
prefix. Below, the tag structure again, with the labeling information
added:

    stemcell-flavor
    |        stemcell-version
    ~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~
    opensuse-42.3-36.g03b4653-30.80-7.0.0_362.g9610e90b-26
    ~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~
    Stemcell OS   Stemcell version                      Role version
