defmodule Publisher do
  def publish(channel, id) do
    payload = {id, :rand.uniform()}
    IO.puts "Publishing #{inspect(payload)}"
    AMQP.Basic.publish(channel, "", "my_queue", :erlang.term_to_binary(payload))
  end

  def publish_loop(channel, time, id \\ 0) do
    publish(channel, id)
    :timer.sleep(time)
    publish_loop(channel, time, id + 1)
  end
end

{:ok, conn} = AMQP.Connection.open()
{:ok, channel} = AMQP.Channel.open(conn)
AMQP.Queue.declare(channel, "my_queue")

Publisher.publish_loop(channel, 1_000)
