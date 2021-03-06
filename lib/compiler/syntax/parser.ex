defmodule Flect.Compiler.Syntax.Parser do
    @moduledoc """
    Contains the parser for Flect source code documents.
    """

    @typep location() :: Flect.Compiler.Syntax.Location.t()
    @typep token() :: Flect.Compiler.Syntax.Token.t()
    @typep ast_node() :: Flect.Compiler.Syntax.Node.t()
    @typep state() :: {[token()], location()}
    @typep return_n() :: {ast_node(), state()}
    @typep return_m() :: {[ast_node()], state()}

    @doc """
    Parses the given list of tokens into a list of
    `Flect.Compiler.Syntax.Node`s representing the module declarations
    (and everything inside those) of the source code document. Returns the
    resulting list or throws a `Flect.Compiler.Syntax.SyntaxError` is the
    source code is malformed.

    `tokens` must be a list of `Flect.Compiler.Syntax.Token`s. `file` must
    be a binary containing the file name (used to report syntax errors).
    """
    @spec parse([Flect.Compiler.Syntax.Token.t()], String.t()) :: [Flect.Compiler.Syntax.Node.t()]
    def parse(tokens, file) do
        loc = if t = Enum.first(tokens), do: t.location(), else: Flect.Compiler.Syntax.Location[file: file]
        do_parse({tokens, loc})
    end

    @spec do_parse(state(), [ast_node()]) :: [ast_node()]
    defp do_parse(state, mods // []) do
        case expect_token(state, [:pub, :priv], "module declaration", true) do
            {_, token, state} ->
                {mod, state} = parse_mod(state, token)
                do_parse(state, [mod | mods])
            :eof -> Enum.reverse(mods)
        end
    end

    @spec parse_simple_name(state()) :: return_n()
    defp parse_simple_name(state) do
        {_, tok, state} = expect_token(state, :identifier, "identifier")
        {new_node(:simple_name, tok.location(), [name: tok]), state}
    end

    @spec parse_qualified_name(state(), {[{atom(), ast_node()}], [token()]}) :: return_n()
    defp parse_qualified_name(state, {names, seps} // {[], []}) do
        {name, state} = parse_simple_name(state)

        case next_token(state) do
            {:colon_colon, tok, state} ->
                parse_qualified_name(state, {[{:name, name} | names], [tok | seps]})
            _ ->
                names = [{:name, name} | names] |> Enum.reverse()
                seps = seps |> Enum.map(fn(x) -> {:separator, x} end) |> Enum.reverse()
                {new_node(:qualified_name, elem(hd(names), 1).location(), seps, names), state}
        end
    end

    @spec parse_mod(state(), token()) :: return_n()
    defp parse_mod(state, visibility) do
        {_, tok_mod, state} = expect_token(state, :mod, "'mod' keyword")
        {name, state} = parse_qualified_name(state)
        {_, tok_open, state} = expect_token(state, :brace_open, "opening brace")
        {decls, state} = parse_decls(state)
        {_, tok_close, state} = expect_token(state, :brace_close, "closing brace")

        tokens = [visibility: visibility,
                  mod_keyword: tok_mod,
                  opening_brace: tok_open,
                  closing_brace: tok_close]

        {new_node(:module_declaration, tok_mod.location(), tokens, [{:name, name} | decls]), state}
    end

    @spec parse_decls(state(),  [{:declaration, ast_node()}]) :: return_m()
    defp parse_decls(state, decls // []) do
        case next_token(state) do
            {v, token, state} when v in [:pub, :priv] ->
                {decl, state} = case expect_token(state, [:fn, :struct, :union, :enum, :type, :trait,
                                                          :impl, :glob, :tls, :const, :macro], "declaration") do
                    {:fn, _, _} -> parse_fn(state, token)
                    {:struct, _, _} -> parse_struct(state, token)
                    {:union, _, _} -> parse_union(state, token)
                    {:enum, _, _} -> parse_enum(state, token)
                    {:type, _, _} -> parse_type(state, token)
                    {:trait, _, _} -> parse_trait(state, token)
                    {:impl, _, _} -> parse_impl(state, token)
                    {:glob, _, _} -> parse_glob(state, token)
                    {:tls, _, _} -> parse_tls(state, token)
                    {:const, _, _} -> parse_const(state, token)
                    {:macro, _, _} -> parse_macro(state, token)
                end

                parse_decls(state, [{:declaration, decl} | decls])
            _ -> {Enum.reverse(decls), state}
        end
    end

    @spec parse_fn(state(), token()) :: return_n()
    defp parse_fn(state, visibility) do
        exit(:todo)
    end

    @spec parse_struct(state(), token()) :: return_n()
    defp parse_struct(state, visibility) do
        {_, tok_struct, state} = expect_token(state, :struct, "structure declaration")
        {name, state} = parse_simple_name(state)
        {_, tok_open, state} = expect_token(state, :brace_open, "opening brace")
        {fields, state} = parse_fields(state);
        {_, tok_close, state} = expect_token(state, :brace_close, "closing brace")

        tokens = [visibility: visibility,
                  struct_keyword: tok_struct,
                  opening_brace: tok_open,
                  closing_brace: tok_close]

        fields = lc field inlist fields, do: {:field, field}

        {new_node(:struct_declaration, tok_struct.location(), tokens, [{:name, name} | fields]), state}
    end

    @spec parse_fields(state(), [ast_node()]) :: return_m()
    defp parse_fields(state, fields // []) do
        case next_token(state) do
            {v, token, state} when v in [:pub, :priv] ->
                {field, state} = parse_field(state, token)
                parse_fields(state, [field | fields])
            _ -> {Enum.reverse(fields), state}
        end
    end

    @spec parse_field(state(), token()) :: return_n()
    defp parse_field(state, visibility) do
        {name, state} = parse_simple_name(state)
        {_, tok_semicolon, state} = expect_token(state, [:semicolon], "semicolon")

        {new_node(:field_declaration, name.location(), [visibility: visibility, semicolon: tok_semicolon], [name: name]), state}
    end

    @spec parse_union(state(), token()) :: return_n()
    defp parse_union(state, visibility) do
        exit(:todo)
    end

    @spec parse_enum(state(), token()) :: return_n()
    defp parse_enum(state, visibility) do
        exit(:todo)
    end

    @spec parse_type(state(), token()) :: return_n()
    defp parse_type(state, visibility) do
        exit(:todo)
    end

    @spec parse_trait(state(), token()) :: return_n()
    defp parse_trait(state, visibility) do
        exit(:todo)
    end

    @spec parse_impl(state(), token()) :: return_n()
    defp parse_impl(state, visibility) do
        exit(:todo)
    end

    @spec parse_glob(state(), token()) :: return_n()
    defp parse_glob(state, visibility) do
        exit(:todo)
    end

    @spec parse_tls(state(), token()) :: return_n()
    defp parse_tls(state, visibility) do
        exit(:todo)
    end

    @spec parse_const(state(), token()) :: return_n()
    defp parse_const(state, visibility) do
        exit(:todo)
    end

    @spec parse_macro(state(), token()) :: return_n()
    defp parse_macro(state, visibility) do
        exit(:todo)
    end

    @spec next_token(state(), boolean()) :: {atom(), token(), state()} | :eof
    defp next_token({tokens, loc}, eof // false) do
        case tokens do
            [h | t] ->
                case h.type() do
                    # TODO: Attach comments to AST nodes.
                    a when a in [:line_comment, :block_comment] -> next_token({t, h.location()}, eof)
                    a -> {a, h, {t, h.location()}}
                end
            [] when eof -> :eof
            _ -> raise_error(loc, "Unexpected end of token stream")
        end
    end

    @spec expect_token(state(), atom() | [atom(), ...], String.t(), boolean()) :: {atom(), token(), state()} | :eof
    defp expect_token(state, type, str, eof // false) do
        case next_token(state, eof) do
            tup = {t, tok, {_, l}} ->
                ok = cond do
                    is_list(type) -> List.member?(type, t)
                    is_atom(type) -> t == type
                end

                if !ok, do: raise_error(l, "Expected #{str}, but got '#{tok.value()}'")

                tup
            # We only get :eof if eof is true.
            :eof -> :eof
        end
    end

    @spec new_node(atom(), location(), [{atom(), token()}, ...], [{atom(), ast_node()}]) :: ast_node()
    defp new_node(type, loc, tokens, children // []) do
        Flect.Compiler.Syntax.Node[type: type,
                                   location: loc,
                                   tokens: tokens,
                                   children: children]
    end

    @spec raise_error(location(), String.t()) :: no_return()
    defp raise_error(loc, msg) do
        raise(Flect.Compiler.Syntax.SyntaxError[error: msg, location: loc])
    end
end
