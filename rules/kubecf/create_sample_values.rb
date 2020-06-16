#!/usr/bin/env ruby

# This script creates a sample values.yaml (with most values commented out) from
# a given values.yaml.

# Usage:
# create_sample_values.rb input-values.yaml [output-values.yaml]

# The input values.yaml can have comments before mapping keys; they are detected
# based on indenting.  Any inputs with a comment including the word "REQUIRED"
# (in all upper case) will be retained as uncommented.  Any inputs with a
# comment including the words "HIDDEN" (in all upper case) will be
# omitted from the output.

# If the output file is not given, the result is printed on standard out.

# If the input file is not given, tests are run instead.  If the environment
# variable `DEBUG` is set, and the input file is given, internal debugging
# information is printed (to standard output) instead of the adjusted result.

require 'yaml'

class Position
    def initialize(line, column)
        @line = line
        @column = column
    end
    attr_reader :line, :column
    def <=>(other)
        [line, column] <=> [other.line, other.column]
    end
    def <(other)
        (self <=> other) < 0
    end
    def >(other)
        (self <=> other) > 0
    end
    def ==(other)
        (self <=> other) == 0
    end
    def to_s
        "#{line},#{column}"
    end
    def -@
        return Position.new(-line, -column)
    end
end

class Psych::Nodes::Node
    # We want a bunch of fields on Node to hold state with.
    attr_accessor :previous_node # Head comment lives between this node & previous
    attr_accessor :next_node # Line comment lives between this node & next
    attr_accessor :depth # top level is 1
    attr_accessor :parent_node, :required
    attr_writer :start_pos, :end_pos
    attr_accessor :line_map # for debugging
    attr_accessor :head_comment, :line_comment

    def start_pos
        @start_pos ||= Position.new(start_line, start_column)
    end

    def end_pos
        @end_pos ||= Position.new(end_line, end_column)
    end

    def has_children?
        !(children.nil? || children.empty?)
    end

    def comment
        [head_comment, line_comment].compact.reject(&:empty?).join("\n")
    end

    # These two functions are used to assert preconditions:
    # state(sym) flags a node as having had an operation done.
    def state(sym)
        @state ||= Hash.new
        @state[sym] = true
    end
    # state?(sym, ...) asserts that an operation had already been done to a node
    def state?(*syms)
        @state ||= Hash.new
        syms.each do |sym|
            unless @state[sym]
                states = @state.keys.sort.join(' ')
                fail "Missing state #{sym} (#{states}: #{self})"
            end
        end
    end

    def to_s(previous = nil)
        color = Hash.new do |h, k|
            h[k] = "\e[#{(previous == false ? '2;' : '')}#{k}m"
        end
        parts = []
        parts << sprintf(%Q(#{color[37]}<%-8s ), self::class.name.split(':').last)
        parts << sprintf(%Q(#{color[36]}@%-10s), "#{start_pos}-#{end_pos}")
        parts << %Q(#{color[35]}d=#{depth})
        parts << case required
        when true then "#{color[32]}R"
        when false then "#{color[31]}N"
        else "#{color[37]}~"
        end
        parts << "#{color[37]}#{value.inspect}" if respond_to?(:value)
        parts << "#{color[33]}#{comment.gsub("\n", '|')}"
        parts << "#{color["1;34"]}^" if parent_node.nil?
        parts << "#{color["2;37"]}p=#{previous_node&.to_s(false)}" if previous
        return parts.join(' ') + "#{color[37]}>\e[0m"
    end
end

# Adjust node ends, such that containers end at the position of their last
# child.  That is, comments and empty space are not counted as part of the
# container.
def adjust_node_ends(nodes)
    adjust_node = lambda do |node|
        next unless node.has_children?
        max_end_pos = node.children.map do |child|
            adjust_node.call child
            child.end_pos
        end.max
        if max_end_pos > node.end_pos
            fail "Invalid end pos #{node} -> #{max_end_pos}"
        end
        node.end_pos = max_end_pos
    end

    # Adjust node ends, starting from each top level node
    nodes.each do |node|
        node.state? :parent_nodes
        adjust_node.call(node) unless node.parent_node
        node.state :adjust_ends
    end
end

def determine_node_parents(nodes)
    nodes.each do |node|
        node.children&.each do |child|
            child.parent_node = node
            # assert for sanity
            fail 'child starts before parent' if (child.start_pos <=> node.start_pos) < 0
            fail 'child ends after parent' if (child.end_pos <=> node.end_pos) > 0
        end
        node.state :parent_nodes
    end
end

def determine_node_depths(nodes)
    def set_node_depth(node, depth)
        node.depth = depth
        node.children&.each do |child|
            set_node_depth child, depth + 1
        end
        node.state :depths
    end
    nodes.each do |node|
        node.state? :parent_nodes
        next unless node.parent_node.nil?
        set_node_depth node, 1
    end
end

# Determine the node structurally before and after each node.
# Note that this is not bijective: a given node is not necessarily the next node
# of its previous node.
def determine_sibling_nodes(nodes)

    # Structure    previous    next
    # A:           ~           B
    #   B:         A           C
    #     - C      B           D
    #     - D      C           E
    #   E:         B           F
    #     - F      E           G
    #     - G      F           ~

    # Determine the previous node.
    # There are a few cases:
    # ( before this ) - simple case: previous node is obvious.
    # ( parent ( this ) ) - previous node is the parent.
    # ( before ( child ) this ) - previous node is parent of the previous-in-sequence
    nodes.each_cons(2) do |before, node|
        node.state? :sorted, :depths
        unless before.nil?
            before = before.parent_node while before.depth > node.depth
            node.previous_node = before
        end
    end
    # Determine the next node.  This has no special cases:
    # ( node after ) - simple case.
    # ( node ( child ) ) - the next node is the child.
    # ( parent ( node ) after ) - the next node is the one after
    nodes.each_cons(2) do |node, after|
        node.state? :sorted, :depths
        node.next_node = after
    end

    nodes.each { |node| node.state :siblings }
end

def text_in_range(lines, start_pos, end_pos)
    if start_pos.line == end_pos.line
        return [lines[start_pos.line][start_pos.column...end_pos.column]]
    end
    start_line = lines[start_pos.line]&.dup || ''
    start_line[0...start_pos.column] = ''
    end_line = lines[end_pos.line]&.dup || ''
    end_line[end_pos.column...end_line.length] = ''
    middle_lines = lines[start_pos.line+1...end_pos.line] || []
    [start_line] + middle_lines + [end_line]
end

def determine_comments(nodes, lines)
    nodes.each do |node|
        node.state? :siblings

        # Determine the head comment
        previous_end_pos = case node.previous_node
        when nil then Position.new(0, 0)
        when node.parent_node then node.parent_node.start_pos
        else node.previous_node.end_pos
        end
        text = text_in_range(lines, previous_end_pos, node.start_pos)
        node.head_comment = text.join("\n")

        # Determine the line comment
        # Line comments only apply to items that start and end on the same line.
        next if node.start_pos.line != node.end_pos.line
        line = node.start_pos.line
        # If multiple nodes end on a given line, then the line comment belongs
        # to the first node to end on that line.
        prev = node.previous_node
        next if prev && prev.end_pos.line == line
        # Otherwise, the line comment begins after the last node to end on this
        # line.
        last_line_node = node
        while last_line_node.next_node
            break if last_line_node.next_node.end_pos.line != line
            last_line_node = last_line_node.next_node
        end
        node.line_comment = lines[line][last_line_node.end_pos.column..-1]

        node.state :comment
    end
end

# Move comments appropriate for children
def move_comments(nodes)
    nodes.each do |node|
        case node
        when Psych::Nodes::Mapping
            # If a mapping (using block style) has a comment, and the first
            # key/value pair is on the same line, assume the comment was
            # intended for that key instead.
            next unless node.has_children? && node.children.length >= 2
            key, value = node.children.first(2)
            next unless key.head_comment.empty?
            next unless key.start_pos == node.start_pos
            next unless key.start_pos.line == value.start_pos.line
            key.head_comment = node.head_comment
            node.head_comment = ''
        end
    end
end

def mark_required_nodes(nodes)
    # Walk the nodes, marking things as required or not
    nodes.each { |n| n.required = true if /\bREQUIRED\b/ =~ n.comment }
    nodes.each { |n| n.required = false if /\bHIDDEN\b/ =~ n.comment }

    # Fix any mappings such that the required state is consistent between keys
    # and values of mappings.  This assume that the nodes are in sorted order.
    def fix_mapping_key_required(nodes)
        nodes.reverse.each do |node|
            node.state? :sorted
            next unless node.is_a? Psych::Nodes::Mapping
            node.children.each_slice(2) do |k, v|
                k.required = v.required if k.required.nil?
                v.required = k.required
            end
        end
    end

    fix_mapping_key_required nodes

    # Walk all nodes, depth-first post-order; if the required state of a node is
    # unknown, set it to be hidden if all children are hidden.
    nodes.reverse.each do |node|
        next if node.required
        next unless node.has_children?
        fix_mapping_key_required [node]
        case node
        when Psych::Nodes::Mapping
            keys = node.children.each_slice(2).map(&:first)
            if node.required.nil? && keys.all? { |k| k.required == false }
                node.required = false
            end
        when Psych::Nodes::Sequence
            if node.required.nil? && node.children.all? { |c| c.required == false }
                node.required = false
            end
        end
    end

    # For every required node, mark all children as required if they otherwise have
    # no state.
    nodes.each do |node|
        next unless node.required
        node.children&.each do |child|
            child.required = true if child.required.nil?
        end
    end

    # Walk all nodes, depth-first post-order; if the required state if a node is
    # unknown, set it to required if any child is required.  This ensures that we
    # will print out a correct structure.  Also for any sequences, if _any_ of
    # the children are required, mark all of them as required (since it makes no
    # sense to have only some children be required).
    nodes.reverse.each do |node|
        next unless node.has_children?
        node.required = true if node.children.any? &:required
        if node.is_a? Psych::Nodes::Sequence
            node.children.each { |child| child.required = true } if node.required
        end
    end

    # Walk all nodes, and mark any children of hidden nodes as hidden.
    nodes.each do |node|
        next unless node.required == false
        node.children.each { |child| child.required = false } if node.has_children?
    end

    fix_mapping_key_required nodes

    nodes.each { |node| node.state :required }
end

def adjust_lines(lines, nodes)
    # Whether we want to keep each line
    line_map = Hash.new { |h, k| h[k] = nil }
    set_adjust_lines = lambda do |node|
        node.state :adjust_lines
        node.children&.each { |n| set_adjust_lines.call(n) }
    end
    adjust_node = lambda do |node|
        node.state? :parent_nodes, :required, :adjust_ends
        case node.required
        when true
            (node.start_pos.line..node.end_pos.line).each do |line|
                line_map[line] = true
            end
        when false
            (node.start_pos.line..node.end_pos.line).each do |line|
                line_map[line] = false
            end
            # We need to look backwards to delete any comments
            start_pos = node.parent_node&.start_pos || Position.new(0, 0)
            (start_pos.line...node.start_pos.line).reverse_each do |index|
                break unless /^\s*#/ =~ lines[index]
                line_map[index] = false
            end
        when nil
            (node.start_pos.line..node.end_pos.line).each do |line|
                line_map[line] = nil
            end
        end
        # We always need to call the children, as we may have e.g.
        # non-configurable children inside of required nodes.
        node.children&.each do |child|
            adjust_node.call child
        end
        set_adjust_lines.call node
    end
    nodes.each do |node|
        adjust_node.call node if node.parent_node.nil? # only look at roots
    end
    nodes.each do |node|
        node.state? :adjust_lines
    end
    lines.each_with_index.reverse_each do |line, index|
        case line_map[index]
        when true
            nil # no change
        when false
            lines.delete_at index
        else
            next if line.strip.empty? || /^\s*#/ =~ line
            /(?<indent>\s*)(?<contents>.*?)$/ =~ line
            line[0..-1] = "#{indent}# #{contents}\n"
        end
    end
    nodes.each { |n| n.line_map = line_map }
end

def pretty_print(lines, nodes)
    lines = lines.map(&:dup) + ['']
    nodes.each { |n| puts n.to_s(true) }
    nodes.reverse.each do |node|
        node.state? :required
        next unless node.is_a? Psych::Nodes::Scalar
        case node.required
        when true
            start = "\e[0;1;32m"
        when false
            start = "\e[0;1;31m"
        else
            start = "\e[0m"
        end
        lines[node.end_line][node.end_column...node.end_column] = "\e[0m"
        lines[node.start_line][node.start_column...node.start_column] = start
    end
    lines.pop
    num_length = lines.length.to_s.length
    printf "%*s 012345678901234567890123456789\n", num_length, ''
    lines.each_with_index do |line, index|
        printf '%*s %s', num_length, index, line
    end
    printf "%*s 012345678901234567890123456789\n", num_length, ''
end

def process(text, output=STDOUT, test_case=nil)
    doc = Psych.parse(text)
    # All nodes to look at, sorted such that the parent node is before the children,
    # and siblings are sorted by position in the document.
    nodes = doc.children.flat_map { |c| c.each.to_a }
    determine_node_parents nodes
    determine_node_depths nodes
    adjust_node_ends nodes
    nodes.sort_by! { |n| [n.start_pos, -n.end_pos] }
    nodes.each { |node| node.state :sorted }
    determine_sibling_nodes nodes
    determine_comments nodes, text.lines
    move_comments nodes
    mark_required_nodes nodes

    lines = text.lines.map(&:dup)
    original_lines = lines.map(&:dup)
    adjust_lines lines, nodes

    if test_case.nil?
        if ENV.has_key? 'DEBUG'
            pretty_print original_lines, nodes
        else
            output.puts lines
        end
        return
    end

    passed = true

    unless test_case['nodes'].is_a? Array
        test_case['nodes'] = [test_case['nodes']].compact
    end
    test_case['nodes'].each do |expect|
        fail_marker = Class.new(Exception)
        fail_test = Proc.new do |msg|
            pretty_print original_lines, nodes
            puts "\e[0;1;31m#{msg}\e[0m"
            raise fail_marker.new
        end
        begin
            if expect.has_key? 'scalar'
                node = nodes.find do |n|
                    n.respond_to?(:value) && n.value == expect['scalar']
                end
            elsif expect.has_key? 'type'
                node = nodes.find do |n|
                    n.class.name.downcase.split(':').last == expect['type'].downcase
                end
            else
                fail_test.call "Don't know how to check assertion #{expect.inspect}"
            end
            fail_test.call("could not find node #{expect.inspect}") unless node
            if expect.has_key? 'required'
                unless node.required.eql? expect['required']
                    fail_test.call "Invalid required state: #{expect.inspect} vs #{node.required.inspect}"
                end
            end
        rescue fail_marker
            passed = false
        end
    end

    if test_case.has_key? 'expect'
        expect_lines = test_case['expect'].lines
        if lines != expect_lines
            pretty_print original_lines, nodes
            puts "line map: #{Hash[nodes.first.line_map.to_a.sort]}"
            (0...[expect_lines.length, lines.length].max).each do |index|
                expect = expect_lines[index]
                actual = lines[index]
                if expect == actual
                    puts "=#{expect}"
                else
                    puts "-#{expect.inspect}"
                    puts "+#{actual.inspect}"
                end
            end
            passed = false
        end
    end
    passed
end

unless ARGV.empty?
    output = ARGV.length > 1 ? File.open(ARGV.last, 'w') : STDOUT
    process File.read(ARGV.first), output
    exit
end

# Test cases are in YAML to deal with indenting multi-line strings better
test_cases = YAML.load %q(
    - text: |
        # REQUIRED
        required: true
      nodes: { scalar: required, require: true }
      expect: |
        # REQUIRED
        required: true
    - text: |
        # HIDDEN
        erased: false
      nodes: { scalar: erased, required: false }
      expect: ''
    - text: |
        # whatever
        commented: nil
      nodes: { scalar: commented, required: ~ }
      expect: |
        # whatever
        # commented: nil
    - text: |
        top:
            # This whole mapping is REQUIRED because of the different start
            { foo: bar, baz: quux }
      nodes: { type: mapping, required: true }
      expect: |
        top:
            # This whole mapping is REQUIRED because of the different start
            { foo: bar, baz: quux }
    - text: |
        top:
            # This whole mapping is HIDDEN for the same reason
            { foo: bar, baz: quux }
      nodes: { type: mapping, required: false }
      expect: ''
    - text: |
        top:
          nested:
              # REQUIRED
              key: value
              # HIDDEN
              k:
                child: value
      nodes:
      - { scalar: nested, require: true }
      - { scalar: k, require: false }
      expect: |
        top:
          nested:
              # REQUIRED
              key: value
    - text: |
        top:
          xx:
            nested:
                # HIDDEN
                key: value
                # ALSO HIDDEN
                k: v
      nodes: { scalar: top, require: false }
      expect: ''
    - text: |
        sequence:
        - 1
        # REQUIRED
        - 2
      nodes:
        { scalar: sequence, required: true }
      expect: |
        sequence:
        - 1
        # REQUIRED
        - 2
    - text: |
        # Testing previous node handling
        top:
            nested:
                more:
                    key: value
            # REQUIRED
            required: true
      nodes: { scalar: required, required: true }
      expect: |
        # Testing previous node handling
        top:
            # nested:
                # more:
                    # key: value
            # REQUIRED
            required: true
    - text: |
        thing: required # this is REQUIRED
      nodes: { scalar: thing, required: true }
      expect: |
        thing: required # this is REQUIRED
    - text: |
        thing: |
          This is not really # REQUIRED
          because it's all inside the scalar
      nodes: { scalar: thing, required: ~ }
      expect: |
        # thing: |
          # This is not really # REQUIRED
          # because it's all inside the scalar
    - text: |
        thing: "# NOT REQUIRED"
      nodes: { scalar: thing, required: ~ }
      expect: |
        # thing: "# NOT REQUIRED"
    - text: |
        { mapping: [ value ] } # HIDDEN
      nodes: { type: mapping, required: false }
      expect: ''
)

passed = true
test_cases.each do |test_case|
    if test_cases.any? { |c| c['focus'] }
        next unless test_case['focus']
    end
    passed = false unless process(test_case['text'], STDOUT, test_case)
end
exit 1 unless passed
puts "All tests passed" if passed
