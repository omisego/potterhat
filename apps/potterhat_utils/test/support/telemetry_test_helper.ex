# Copyright 2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule PotterhatUtils.TelemetryTestHelper do
  @moduledoc """
  Helper functions for asserting telemetry events.
  """
  import ExUnit.Callbacks
  import ExUnit.Assertions

  def listen_telemetry(event_name) do
    handler_id = handler_id(event_name)

    :ok =
      :telemetry.attach(
        handler_id,
        event_name,
        &echo_telemetry/4,
        %{
          test_pid: self()
        }
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)
  end

  def assert_telemetry(event_name) do
    received =
      receive do
        {:telemetry_received, event} -> {:ok, event}
      after
        100 -> nil
      end

    case received do
      {:ok, {received_name, _, _, _}} -> assert received_name == event_name
      _ -> flunk("The telemetry event #{inspect(event_name)} was never received.")
    end
  end

  #
  # Private functions
  #

  defp handler_id(event_name) do
    string_event_name =
      event_name
      |> Enum.map(&to_string/1)
      |> Enum.join("_")

    "test_#{string_event_name}_#{:rand.uniform(999_999_999)}"
  end

  defp echo_telemetry(event_name, measurements, meta, config) do
    send(config.test_pid, {:telemetry_received, {event_name, measurements, meta, config}})
  end
end