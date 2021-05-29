defmodule Espi.Timeout do
  @moduledoc """
  Server implementation for all :timeout components.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    {:ok, {m, f}} = Keyword.fetch(opts, :callback)
    {:ok, schedule} = Keyword.fetch(opts, :schedule)

    callback = fn args -> apply(m, f, [args]) end

    schedule_timeout(schedule)

    {:ok, %{callback: callback}}
  end

  defp schedule_timeout(schedule) do
    Process.send_after(self(), {:timeout, schedule}, schedule)
  end

  @impl true
  def handle_info({:timeout, schedule}, state = %{callback: callback}) do
    schedule_timeout(schedule)
    callback.(nil)
    {:noreply, state}
  end
end
