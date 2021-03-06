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

defmodule PotterhatNode.Application do
  @moduledoc false
  use Application
  alias PotterhatUtils.TelemetrySubscriber

  def start(_type, _args) do
    _ = DeferredConfig.populate(:potterhat_node)
    :ok = TelemetrySubscriber.attach_from_config(:potterhat_node)

    children = [PotterhatNode.ActiveNodes | nodes()]

    opts = [strategy: :one_for_one, name: PotterhatNode.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp nodes do
    Enum.map(PotterhatNode.all(), fn config ->
      config = Map.put(config, :node_registry, PotterhatNode.ActiveNodes)
      id = Map.fetch!(config, :id)

      Supervisor.child_spec({PotterhatNode.Node, config}, id: id)
    end)
  end
end
