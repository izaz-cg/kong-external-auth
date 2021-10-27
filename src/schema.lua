return {
  no_consumer = true,
  fields = {
    url = { required = true, type = "url" },
    path = { default = "/verify/user", type = "string" },
    connect_timeout = { default = 10000, type = "number" },
    send_timeout = { default = 60000, type = "number" },
    read_timeout = { default = 60000, type = "number" },
    message_401 = { default = "Unauthorized", type = "string" },
    message_403 = { default = "You don't have enough permissions to access", type = "string" },
    message_404 = { default = "Not Found", type = "string" },
    injection_header = { default = "cg-user", type = "string" },
    token_header = { default = "authenticationtoken", type = "string" }
  }
}
