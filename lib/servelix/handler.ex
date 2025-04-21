defmodule Servelix.Handler do
  require Logger

  def handle(request) do
    request
    |> parse
    |> rewrite_request
    |> log
    |> route
    |> emojify
    |> track
    |> format_response
  end

  def emojify(%{status: 200, resp_body: resp_body} = conv) do
    %{ conv | resp_body: "👍 #{resp_body} 👍" }
  end

  def emojify(conv), do: conv

  def track(%{ status: 404, path: path } = conv) do
   Logger.warn("Warning: no \"#{path}\" defined in the project")
   conv
  end

  def track(conv), do: conv

  def rewrite_request(%{ path: path } = conv) do
    regex = ~r{\/(?<things>\w+)\?id=(?<id>\d+)}
    captured_variables = Regex.named_captures(regex, path)
    rewrite_path(conv, captured_variables)
  end

  def rewrite_path(conv, %{ "id" => id, "things" => things }) do
    %{ conv | path: "/#{things}/#{id}" }
  end

  def rewrite_path(conv, nil), do: conv

  def rewrite_request(%{ path: "/another_things" } = conv) do
    %{ conv | path: "/other_things" }
  end

  def rewrite_request(conv), do: conv

  def log(conv), do: IO.inspect(conv)

  def parse(request) do
    [method, path, _] =
      request
      |> String.split("\n")
      |> List.first
      |> String.split

    %{ method: method,
       path: path,
       resp_body: "",
       status: nil
     }
  end

  def route(%{ method: "GET", path: "/things/" <> id } = conv) do
    %{ conv | status: 200, resp_body: "Thing #{id}" }
  end

  def route(%{ method: "DELETE", path: "/things/" <> _id } = conv) do
    %{ conv | status: 403, resp_body: "Can not delete things" }
  end

  def route(%{ method: "GET", path: "/things" } = conv) do
    %{ conv | status: 200, resp_body: "Things response body" }
  end

  def route(%{ method: "GET", path: "/other_things" } = conv) do
    %{ conv | status: 200, resp_body: "Other things response body" }
  end

  def route(%{ path: path } = conv) do
    %{ conv | status: 404, resp_body: "No #{path} found!" }
  end

  def format_response(conv) do
    """
    HTTP/1.1 #{conv.status} #{status_reason(conv.status)}
    Content-Type: text/html
    Content-Length: #{byte_size(conv.resp_body)}

    #{conv.resp_body}
    """
  end

  defp status_reason(code) do
    %{
      200 => "OK",
      201 => "Created",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      500 => "Internal Server Error"
    }[code]
  end
end

request = """
GET /things HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servelix.Handler.handle(request)

IO.puts response

request = """
GET /things/2 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servelix.Handler.handle(request)

IO.puts response

request = """
GET /animals?id=3 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servelix.Handler.handle(request)

IO.puts response

request = """
DELETE /things?id=3 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servelix.Handler.handle(request)

IO.puts response

request = """
GET /other_things HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servelix.Handler.handle(request)

IO.puts response

request = """
GET /another_things HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servelix.Handler.handle(request)

IO.puts response

request = """
GET /invalid HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servelix.Handler.handle(request)

IO.puts response
