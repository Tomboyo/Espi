defmodule Receiver do
  def receive_loop do
    receive do
      {:basic_deliver, payload, _meta} ->
        payload = :erlang.binary_to_term(payload)
        IO.puts "Received #{inspect(payload)}"
        {id, magnitude} = payload

        cost = floor(2 * magnitude * 1_000)
        :timer.sleep(cost)

        IO.puts "    ... done (#{cost} ms)."
        receive_loop()
    end
  end
end

{:ok, conn} = AMQP.Connection.open()
{:ok, channel} = AMQP.Channel.open(conn)
AMQP.Queue.declare(channel, "my_queue")
AMQP.Basic.consume(channel, "my_queue", nil, no_ack: true)

Receiver.receive_loop()
