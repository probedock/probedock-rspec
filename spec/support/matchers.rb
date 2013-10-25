
RSpec::Matchers.define :have_elements_matching do |attr,*expected|

  match do |actual|
    elements = actual.send attr
    expected.all?{ |m| elements.any?{ |e| e.match(m) } }
  end

  description do
    "have #{attr} matching #{expected}"
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
