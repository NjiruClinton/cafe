defmodule CafeWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      summary("phoenix.endpoint.start.system_time", unit: {:native, :millisecond}),
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("cafe.order.placed.total_cents"),
      counter("cafe.order.placed.count"),
      last_value("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("cafe.repo.query.total_time", unit: {:native, :millisecond}),
      summary("cafe.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("cafe.repo.query.query_time", unit: {:native, :millisecond}),
      summary("cafe.repo.query.queue_time", unit: {:native, :millisecond}),
      summary("cafe.repo.query.idle_time", unit: {:native, :millisecond})
    ]
  end

  defp periodic_measurements do
    [
      {__MODULE__, :dispatch_memory, []}
    ]
  end

  def dispatch_memory do
    :telemetry.execute([:vm, :memory], :erlang.memory())
  end
end
