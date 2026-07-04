require "kemal"
require "pg"
require "db"

# DB pooling for performance
DB_URL = ENV["DATABASE_URL"]? || "postgresql://localhost:5432/profiling"
APPDB = DB.open(DB_URL)

class CONTENT
  UTF8  = "; charset=UTF-8"
  JSON  = "application/json"
  PLAIN = "text/plain"
  HTML  = "text/html" + UTF8
end

module Clock
  @@formatted = HTTP.format_time(Time.local)

  def self.formatted
    @@formatted
  end

  spawn do
    loop do
      sleep 1.second
      @@formatted = HTTP.format_time(Time.local)
    end
  end
end

private def set_user(user)
  result = APPDB.exec("UPDATE users SET firstName = $1 WHERE id = $2", user[:firstName], user[:id])
  result.rows_affected > 0
end

before_all do |env|
  env.response.headers["Server"] = "Kemal"
  env.response.headers["Date"] = Clock.formatted
end

# Root Endpoint HTML
get "/users" do |env|
  env.response.content_type = CONTENT::HTML
  env.response.print "<!DOCTYPE html><html><head><title>Users</title></head><body><table><tr><th>id</th><th>name</th></tr>"

  APPDB.query_each("SELECT id, firstName FROM users") do |rs|
    id = rs.read(Int32)
    first_name = HTML.escape(rs.read(String))
    env.response.print "<tr><td>#{id}</td><td>#{first_name}</td></tr>"
  end

  env.response.print "</table></body></html>"
end

# Json Endpoint: Database Updates
# {"firstName": "Serdar", "Id": 12312}
post "/webhook" do |env|
  name = env.params.json["firstName"].as(String)
  id = env.params.json["Id"].as(Int64).to_i32
  success = set_user({id: id, firstName: name})
  env.response.content_type = CONTENT::JSON
  %({"success":#{success}})
end

Kemal.config do |cfg|
  cfg.serve_static = false
  cfg.logging = false
  cfg.powered_by_header = false
end

Kemal.run { |cfg| cfg.server.not_nil!.bind_tcp(cfg.host_binding, cfg.port, reuse_port: true) }
