# Probe Dock RSpec

**RSpec probe for [Probe Dock](https://github.com/probedock/probedock).**

[![Gem Version](https://badge.fury.io/rb/probedock-rspec.svg)](http://badge.fury.io/rb/probedock-rspec)
[![Dependency Status](https://gemnasium.com/probedock/probedock-rspec.svg)](https://gemnasium.com/probedock/probedock-rspec)
[![Build Status](https://secure.travis-ci.org/probedock/probedock-rspec.svg)](http://travis-ci.org/probedock/probedock-rspec)
[![Coverage Status](https://coveralls.io/repos/probedock/probedock-rspec/badge.svg)](https://coveralls.io/r/probedock/probedock-rspec?branch=master)
[![License](https://img.shields.io/github/license/probedock/probedock-rspec.svg)](LICENSE.txt)

## Requirements

* RSpec 3+

## Installation

In your Gemfile:

```rb
gem 'probedock-rspec', '~> 0.5.5'
```

Manually:

    gem install probedock-rspec

## Usage

If you haven't done it already, follow the [setup procedure](#setup) below.

To track a test with a Probe Dock test key, use RSpec metadata:

```rb
it "should work", probedock: { key: 'abcdefghijkl' } do
  expect(true).to be(true)
end

it(nil, probedock: { key: 'bcdefghijklm' }){ should validate_presence_of(:name) }
```

<a name="setup"></a>
## Setup

You must first set up the configuration file(s) for the project.
This procedure is described here:

* [Probe Setup Procedure](https://github.com/probedock/probedock-clients#setup-procedure)

You must then enable the client in your spec helper file (e.g. `spec/spec_helper.rb`).

```yml
require 'probedock-rspec'

ProbeDockRSpec.configure do |config|

  # Optional category to add to all the tests sent with this client.
  config.project.category = 'RSpec'
end
```

The next time you run your test suite, the RSpec probe will send the results to your Probe Dock server.

## Contributing

* [Fork](https://help.github.com/articles/fork-a-repo)
* Create a topic branch - `git checkout -b my_feature`
* Push to your branch - `git push origin my_feature`
* Create a [pull request](http://help.github.com/pull-requests/) from your branch

Please add a [changelog](CHANGELOG.md) entry with your name for new features and bug fixes.

## License

Probe Dock RSpec is licensed under the [MIT License](http://opensource.org/licenses/MIT).
See [LICENSE.txt](LICENSE.txt) for the full license.
