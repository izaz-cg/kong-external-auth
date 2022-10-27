return {
    no_consumer = true,
    fields = {
      url = { required = true, type = "url", default = "http://user.dev.svc.cluster.local:8000" },
      path = { default = "/user/public/verify/user", type = "string" },
      connect_timeout = { default = 10000, type = "number" },
      send_timeout = { default = 60000, type = "number" },
      read_timeout = { default = 60000, type = "number" },
      message_401 = { default = "Session expired, please login again", type = "string" },
      message_403 = { default = "You don't have enough permissions to access", type = "string" },
      message_404 = { default = "Not Found", type = "string" },
      injection_header = { default = "X-CG-User", type = "string" },
      company_injection_header = { default = "X-CG-Company", type = "string" },
      token_header = { default = "authenticationtoken", type = "string" },
      masking_header = { default = "X-Allow", type = "string"},
      new_portfolio_company_id = { default = {"ad8b5a88-637f-49a3-b8af-f341dd9db5fd", "cd97a83f-c44a-44b7-8bd8-2fc27a9fe0d3"}, type = "array" }
    }
  }
