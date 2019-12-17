def yaml_extractor(name, src, filter):
    native.genrule(
        name = name,
        cmd = """
            '$(location @jq//jq)' -r '{filter}' \
                <('$(location @yq//yq)' read --tojson - < '$(location {src})') \
                | '$(location @yq//yq)' read - > '$@'
        """.format(
            filter = filter,
            src = src,
        ),
        outs = ["{}.yaml".format(name)],
        srcs = [src],
        tools = [
            "@jq//jq",
            "@yq//yq",
        ],
    )
