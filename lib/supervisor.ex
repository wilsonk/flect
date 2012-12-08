defmodule Flect.Supervisor do
    use Supervisor.Behaviour

    @spec start_link(Flect.Config.t()) :: {:ok, pid()}
    def start_link(cfg) do
        {:ok, _} = :supervisor.start_link(__MODULE__, [cfg])
    end

    @spec init(Flect.Config.t()) :: term()
    def init(cfg) do
        supervise([worker(Flect.Worker, cfg, [restart: :temporary,
                                              shutdown: :infinity])], [strategy: :one_for_one])
    end
end
