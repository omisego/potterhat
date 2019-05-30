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

defmodule PotterhatNodeTest do
  use ExUnit.Case
  import PotterhatNode.EthereumTestHelper
  alias PotterhatNode.Node
  alias PotterhatNode.Node.RPCResponse

  doctest PotterhatNode

  @node_config %PotterhatNode.NodeConfig{
    id: :test_node_start_link,
    label: "Test PotterhatNode.start_link/1 GenServer",
    client: :geth,
    rpc: "http://localhost",
    ws: "ws://localhost",
    priority: 1000
  }

  setup do
    {:ok, rpc_url, websocket_url} = start_mock_node()

    config =
      @node_config
      |> Map.put(:id, String.to_atom("#{@node_config.id}_#{:rand.uniform(999999999)}"))
      |> Map.put(:rpc, rpc_url)
      |> Map.put(:ws, websocket_url)

    {:ok, %{
      config: config
    }}
  end

  describe "start_link/1" do
    test "returns a pid", meta do
      {res, pid} = Node.start_link(meta.config)

      assert res == :ok
      assert is_pid(pid)

      # This stops the node before the mock websocket server goes down.
      :ok = GenServer.stop(pid)
    end

    test "starts a GenServer with the given config", meta do
      {:ok, pid} = Node.start_link(meta.config)

      assert GenServer.call(pid, :get_label) == meta.config.label
      assert GenServer.call(pid, :get_priority) == meta.config.priority

      # This stops the node before the mock websocket server goes down.
      :ok = GenServer.stop(pid)
    end
  end

  describe "stop/1" do
    test "stops the node when given a node's pid", meta do
      {:ok, pid} = Node.start_link(meta.config)
      res = Node.stop(pid)

      assert res == :ok
      refute Process.alive?(pid)
    end
  end

  describe "get_label/1" do
    test "returns the node's label", meta do
      {:ok, pid} = Node.start_link(meta.config)
      assert Node.get_label(pid) == meta.config.label
    end
  end

  describe "get_priority/1" do
    test "returns the node's priority", meta do
      {:ok, pid} = Node.start_link(meta.config)
      assert Node.get_priority(pid) == meta.config.priority
    end
  end

  describe "subscribe/2" do
    test "subscribes the given pid", meta do
      {:ok, pid} = Node.start_link(meta.config)
      subscriber = spawn(fn -> :noop end)

      refute subscriber in Node.get_subscribers(pid)
      res = Node.subscribe(pid, subscriber)

      assert res == :ok
      assert subscriber in Node.get_subscribers(pid)
    end

    test "returns {:error, :already_subscribed} if the given pid is already subscribed", meta do
      {:ok, pid} = Node.start_link(meta.config)
      subscriber = spawn(fn -> :noop end)

      # 1st subscription should pass
      :ok = Node.subscribe(pid, subscriber)
      assert subscriber in Node.get_subscribers(pid)

      # 2nd subscription should fail
      assert Node.subscribe(pid, subscriber) == {:error, :already_subscribed}
    end
  end

  describe "unsubscribe/2" do
    test "unsubscribes the given pid", meta do
      {:ok, pid} = Node.start_link(meta.config)
      subscriber = spawn(fn -> :noop end)

      # Prepare the node subscription
      :ok = Node.subscribe(pid, subscriber)
      assert subscriber in Node.get_subscribers(pid)

      # Actual unsubscription here
      res = Node.unsubscribe(pid, subscriber)

      assert res == :ok
      refute subscriber in Node.get_subscribers(pid)
    end

    test "returns {:error, :not_subscribed} if the given pid is not subscribed", meta do
      {:ok, pid} = Node.start_link(meta.config)
      subscriber = spawn(fn -> :noop end)

      refute subscriber in Node.get_subscribers(pid)
      assert Node.unsubscribe(pid, subscriber) == {:error, :not_subscribed}
    end
  end

  describe "get_subscribers/1" do
    test "returns the list of subscribers", meta do
      {:ok, pid} = Node.start_link(meta.config)
      subscriber1 = spawn(fn -> :noop end)
      subscriber2 = spawn(fn -> :noop end)
      subscriber3 = spawn(fn -> :noop end)

      :ok = Node.subscribe(pid, subscriber1)
      :ok = Node.subscribe(pid, subscriber2)
      :ok = Node.subscribe(pid, subscriber3)

      subscribers = Node.get_subscribers(pid)

      assert Enum.member?(subscribers, subscriber1)
      assert Enum.member?(subscribers, subscriber2)
      assert Enum.member?(subscribers, subscriber3)
    end
  end

  describe "rpc_request/3" do
    test "returns a Response struct", meta do
      {:ok, pid} = Node.start_link(meta.config)

      body = %{}
      headers = %{}

      {res, response} = Node.rpc_request(pid, body, headers)

      assert res == :ok
      assert %RPCResponse{} = response
    end
  end
end