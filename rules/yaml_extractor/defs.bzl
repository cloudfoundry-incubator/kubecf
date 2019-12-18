def yaml_extractor(name, src, filter):
    native.genrule(
        name = name,
        cmd = """
            '$(location @jq//:binary)' -r '{filter}' \
                <('$(location @yq//:binary)' read --tojson - < '$(location {src})') \
                | '$(location @yq//:binary)' read - > '$@'
        """.format(
            filter = filter,
            src = src,
        ),
        outs = ["{}.yaml".format(name)],
        srcs = [src],
        tools = [
            "@jq//:binary",
            "@yq//:binary",
        ],
    )
