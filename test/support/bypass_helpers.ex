defmodule Column.Test.BypassHelpers do
  @moduledoc "Helpers for Bypass-based HTTP mocking."

  import ExUnit.Assertions

  @doc "Stub a Bypass endpoint returning JSON."
  def stub_json(bypass, method, path, status, body) do
    Bypass.expect_once(bypass, method, path, fn conn ->
      assert_auth(conn)

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(status, Jason.encode!(body))
    end)
  end

  @doc "Stub a Bypass endpoint returning JSON, also captures request body."
  def stub_json_with_body(bypass, method, path, status, response_body, on_request \\ nil) do
    Bypass.expect_once(bypass, method, path, fn conn ->
      assert_auth(conn)
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      if on_request, do: on_request.(body)

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(status, Jason.encode!(response_body))
    end)
  end

  @doc "Returns a %Column.Config{} pointing at the Bypass server."
  def bypass_config(bypass) do
    %Column.Config{
      api_key: "test_bypass_key",
      base_url: "http://localhost:#{bypass.port}",
      max_retries: 0,
      timeout: 5_000,
      recv_timeout: 5_000
    }
  end

  defp assert_auth(conn) do
    auth = Plug.Conn.get_req_header(conn, "authorization")
    assert auth != [], "Expected Authorization header"
  end
end
