defrecord Flect.Compiler.Syntax.Node, type: nil,
                                      location: nil,
                                      tokens: [],
                                      named_children: [],
                                      children: [],
                                      data: nil do
    @moduledoc """
    Represents an AST (abstract syntax tree) node.

    `type` is an atom indicating the kind of node. `location` is a
    `Flect.Compiler.Syntax.Location` indicating the node's location in
    the source code document. `tokens` is a list of the
    `Flect.Compiler.Syntax.Token`s that make up this node. `named_children`
    is a keyword list containing all uniquely named children. `children` is
    a list of all children. `data` is an arbitrary term associated with the
    node - it can have different meanings depending on which compiler stage
    the node is being used in.
    """

    record_type(type: atom(),
                location: Flect.Compiler.Syntax.Location.t(),
                tokens: [{atom(), Flect.Compiler.Syntax.Token.t()}, ...],
                named_children: [{atom(), t()}],
                children: [t()],
                data: term())

    @doc """
    Formats the node and all of its children in a user-presentable way.
    Returns the resulting binary.

    `self` is the node record.
    """
    @spec format(t()) :: String.t()
    def format(self) do
        do_format(self, "")
    end

    @spec do_format(t(), String.t()) :: String.t()
    defp do_format(node, indent) do
        loc = fn(loc) ->
            l = integer_to_binary(loc.line())
            c = integer_to_binary(loc.column())

            "<\"" <> loc.file() <> "\", " <> l <> ", " <> c <> ">"
        end

        join = ",\n  " <> indent

        tokens = Enum.map(node.tokens(), fn({key, tok}) ->
            atom_to_binary(key) <> ": \"" <> tok.value() <> "\" " <> loc.(tok.location())
        end)

        children = Enum.map(node.children(), fn(child) ->
            do_format(child, indent <> "  ")
        end)

        named_children = Enum.map(node.named_children(), fn({key, child}) ->
            atom_to_binary(key) <> ": " <> do_format(child, indent <> " ")
        end)

        acc = "(" <> atom_to_binary(node.type()) <> " " <> loc.(node.location()) <> ",\n"
        acc = acc <> indent <> " (" <> Enum.join(tokens, join) <> "),\n"
        acc = acc <> indent <> " (" <> Enum.join(children, join) <> "),\n"
        acc = acc <> indent <> " (" <> Enum.join(named_children, join) <> ")\n"
        acc = acc <> indent <> ")"

        acc
    end
end
