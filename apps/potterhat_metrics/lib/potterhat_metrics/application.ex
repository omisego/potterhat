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

defmodule PotterhatMetrics.Application do
  @moduledoc false
  use Application
  alias PotterhatUtils.TelemetrySubscriber

  def start(_type, _args) do
    _ = DeferredConfig.populate(:vmstats)
    _ = DeferredConfig.populate(:potterhat_metrics)
    _ = DeferredConfig.populate(:statix)

    :ok = TelemetrySubscriber.attach_from_config(:potterhat_metrics)
    interval_ms = Application.get_env(:potterhat_metrics, :interval_ms)

    children = [
      # :vmstats needs to be started manually, otherwise it'll attempt to start before
      # deferred_config is populated. See:
      # https://elixirforum.com/t/automatically-starting-applications-in-the-correct-order/15571/8
      %{id: :vmstats, start: {:vmstats, :start, [:normal, []]}},
      {PotterhatMetrics.Collector, [interval_ms: interval_ms]}
    ]

    opts = [strategy: :one_for_one, name: PotterhatMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
