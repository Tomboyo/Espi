defmodule Espi.RabbitQueue do
  defmodule Server do
    use GenServer

    def start_link(opts) do
      GenServer.start_link(__MODULE__, opts)
    end

    @impl true
    def init(opts) do
      {:ok, {m, f}} = Keyword.fetch(opts, :impl)

      schedule_timeout()

      # {:ok, conn} = AMQP.Connection.open()
      # {:ok, channel} = AMQP.Channel.open(conn)
      # AMQP.Queue.declare(channel, "my_queue")
      # AMQP.Basic.consume(channel, "my_queue", nil, no_ack: true)

      {:ok, %{impl: fn a -> apply(m, f, a) end}}
      # {:ok, {conn, channel, fn a -> apply(m, f, a) end}}
    end

    defp schedule_timeout() do
      Process.send_after(self(), {:timeout, :os.system_time(:millisecond)}, 1_000)
    end

    @impl true
    def handle_info({:timeout, millis}, state = %{impl: impl}) do
      schedule_timeout()
      impl.([millis])
      {:noreply, state}
    end

    # @impl true
    # def handle_info(x = {:basic_deliver, _payload, _meta}, state = {_, _, impl}) do
    #   impl.([x])
    #   {:noreply, state}
    # end
  end
end
