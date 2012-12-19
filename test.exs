path = Enum.at!(System.argv(), 0)

passes = :file.list_dir(path) />
         elem(1) />
         Enum.filter(fn(x) -> File.extname(x) == '.pass' end) />
         Enum.sort() />
         Enum.map(fn(x) -> File.join(path, x) end) />
         Enum.map(fn(x) -> [pass: x /> File.basename() /> File.rootname()] ++ Enum.at!(elem(:file.consult(x), 1), 0) end)

files = :file.list_dir(path) />
        elem(1) />
        Enum.filter(fn(x) -> File.extname(x) == '.fl' end) />
        Enum.map(fn(x) -> list_to_binary(x) end) />
        Enum.sort()

IO.puts("Testing #{path}...")
IO.puts("")

File.cd!(path)

results = Enum.map(passes, fn(pass) ->
    Enum.map(files, fn(file) ->
        cmd = pass[:command] />
              list_to_binary() />
              String.replace("<flect>", File.join(["..", "..", "flect"])) />
              String.replace("<file>", file) />
              String.replace("<name>", File.rootname(file)) />
              binary_to_list()

        IO.write("#{file}... ")

        port = Port.open({:spawn, cmd}, [:stream,
                                         :binary,
                                         :exit_status,
                                         :hide])

        recv = fn(recv, port, acc) ->
            receive do
                {^port, {:data, data}} -> recv.(recv, port, acc <> data)
                {^port, {:exit_status, code}} -> {acc, code}
            end
        end

        {text, code} = recv.(recv, port, "")

        exp = case File.read(file <> "." <> pass[:pass] <> ".exp") do
            {:ok, data} ->
                stripped_text = String.strip(text)
                stripped_data = String.strip(data)

                stripped_text == stripped_data
            {:error, :enoent} -> true
        end

        if code == pass[:code] && exp do
            IO.puts("pass (#{inspect(code)})")
            true
        else
            IO.puts("fail (#{inspect(code)})")
            false
        end
    end)
end)

File.cd!(File.join("..", ".."))

results = List.flatten(results)

test_passes = Enum.count(results, fn(x) -> x end)
test_failures = Enum.count(results, fn(x) -> !x end)

IO.puts("")
IO.puts("#{inspect(test_passes)} passes, #{inspect(test_failures)} failures")
IO.puts("")

System.halt(if test_failures > 0, do: 1, else: 0)
