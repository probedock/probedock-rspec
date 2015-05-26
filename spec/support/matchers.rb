RSpec::Matchers.define :have_elements_matching do |attr,*expected|

  match do |actual|
    elements = actual.send attr
    expected.all?{ |m| elements.any?{ |e| e.match(m) } }
  end

  description do
    "have #{attr} matching #{expected}"
  end
end

RSpec::Matchers.define :have_server_configuration do |expected|

  match do |actual|
    attrs = %i(name api_url api_token project_api_id)
    @actual_config = attrs.inject({}){ |memo,k| memo[k] = actual.send(k); memo }
    @actual_config == attrs.inject({}){ |memo,k| memo[k] = expected[k] ? expected[k].to_s : nil; memo }
  end

  description do
    "have server configuration #{expected.inspect}"
  end
end

=begin
RSpec::Matchers.define :include_matching do |*expected|

  match do |actual|
    expected.all?{ |e| actual.any?{ |a| a.match(e) } }
  end

  description do
    "include an element matching #{expected}"
  end
end
=end
