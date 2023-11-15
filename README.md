# Firespring Dev Commands
This project is for maintaining your local development environment using a Firespring supported library of commands

### Usage
* To use a released version of the library, add the following to your Gemfile
```
gem 'firespring_dev_commands', '~> 0.0.1'
```

* To use a local version of the library, add the following to your Gemfile
  * This is not common
  * It is mostly used for testing local changes before the gem is released
```
gem 'firespring_dev_commands', path: '/path/to/dev_commands'
```

* Add the following to your Rakefile
```
require 'firespring_dev_commands'
```

* (optional) Add any firespring_dev_command templates you wish to use
```
# Create default tasks
Dev::Template::Docker::Default.new
Dev::Template::Docker::Application.new('foo')
Dev::Template::Docker::Node::Application.new('foo')
```
* If you run `rake -T` now, you should have base rake commands and application rake commands for an app called `foo`

* (optinoal) Add AWS login template commands
```
# Configure AWS accounts and create tasks
Dev::Aws::Account::configure do |c|
  c.root = Dev::Aws::Account::Info.new('Foo Root', '1234')
  c.children = [Dev::Aws::Account::Info.new('Foo Dev', '5678')]
end
Dev::Template::Aws.new
```
* Now you should be able to log in to the 1234 account and switch to your personal role in the 5678 account
* If you specify a "registry" id in the Account configure you will be logged in ECR inside the system docker so you can pull and push images

### Development
* Clone the repo
* Change code
  * Build test image
    * `rake build`
  * Connect to the test image
    * `rake app:sh`
* Ensure ruby lints pass
  * `rake app:ruby:lint` or `rake app:ruby:lint:fix`
* Ensure tests pass
  * `rake app:ruby:test`
* Update the gem version appropriately
  * We use semantic versioning
  * https://semver.org/
* Open a pull request and add reviewers

### Publishing
* After your changes have been approved, run the `rake release` command
  * You will receive an error if you try to re-publish an existing version of the gem
  * Theoretically you could yank an existing version and re-publish if necessary

# Concepts
### Config
* Many of the classes have a configure singleton which can be used to set global configs
  * These configs should then be the default used when instantiating the object
  * The configs should always be over-writable when instantiating the object

### Templates
* The templates should have as little code/logic in them as possible
  * This is to help with re-usability
  * Instead, create the bulk of the logic in the ruby files so that if a user wants to modify it they can re-use those ruby methods in a task of their own making
* Naming of the templates generally follows `rake <thing>:<language (optional)>:action:<modifier (optional)`
  * e.g. `rake build`, `rake app:up`, `rake app:php:test:unit`

### TODOs
* Consider publishing a docker image which you can run the commands in
  * So you don't need ruby on your local system
* Add LOTS of tests to get code coverage to 100%

