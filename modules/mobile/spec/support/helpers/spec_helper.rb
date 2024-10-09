# frozen_string_literal: true

UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

VCR.configure do |c|
  c.register_request_matcher :path do |request1, request2|
    request1.parsed_uri.path.sub('vaos-alt', 'vaos') == request2.parsed_uri.path
  end
  c.register_request_matcher :uri do |request1, request2|
    request1.uri.sub('vaos-alt', 'vaos') == request2.uri
  end
end
