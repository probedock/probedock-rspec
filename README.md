# RSpec Probe for Probe Dock

**RSpec formatter to publish test results to [Probe Dock](https://github.com/probedock/probedock).**

[![Gem Version](https://badge.fury.io/rb/probedock-rspec.svg)](http://badge.fury.io/rb/probedock-rspec)
[![Dependency Status](https://gemnasium.com/probedock/probedock-rspec.svg)](https://gemnasium.com/probedock/probedock-rspec)
[![Build Status](https://secure.travis-ci.org/probedock/probedock-rspec.svg)](http://travis-ci.org/probedock/probedock-rspec)
[![Coverage Status](https://coveralls.io/repos/probedock/probedock-rspec/badge.svg)](https://coveralls.io/r/probedock/probedock-rspec?branch=master)
[![License](https://img.shields.io/github/license/probedock/probedock-rspec.svg)](LICENSE.txt)

* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Contributing](#contributing)



<a name="requirements"></a>
## Requirements

* Ruby 2+
* RSpec 3+



<a name="installation"></a>
## Installation

Add it to your Gemfile:

```rb
gem 'probedock-rspec', '~> 0.7.1'
```

Then run `bundle install`.

If you haven't done so already, set up your Probe Dock configuration file(s).
This procedure is described here:

* [Probe Setup Procedure](https://github.com/probedock/probedock-probes#setup)

You must then enable the client in your spec helper file (e.g. `spec/spec_helper.rb`).

```yml
require 'probedock-rspec'

ProbeDockRSpec.configure do |config|

  # Optional category to add to all the tests sent with this client.
  config.project.category = 'RSpec'
end
```

The next time you run your test suite, the RSpec probe will send the results to your Probe Dock server.



<a name="usage"></a>
## Usage

To track a test with a Probe Dock test key, use RSpec metadata:

```rb
it "should work", probedock: { key: 'abcd' } do
  expect(true).to be(true)
end

it(nil, probedock: { key: 'bcde' }){ should validate_presence_of(:name) }
```

You may also define a category, tags and tickets for a test like this:

```rb
it "should work", probedock: { key: 'cdef', category: 'Integration', tags: %w(user-registration validation), tickets: %w(JIRA-1000 JIRA-1012) } do
  expect(2).to be < 3
end
```



## Contributing

* [Fork](https://help.github.com/articles/fork-a-repo)
* Create a topic branch - `git checkout -b my_feature`
* Push to your branch - `git push origin my_feature`
* Create a [pull request](http://help.github.com/pull-requests/) from your branch

Please add a [changelog](CHANGELOG.md) entry with your name for new features and bug fixes.



## License

**probedock-rspec** is licensed under the [MIT License](http://opensource.org/licenses/MIT).
