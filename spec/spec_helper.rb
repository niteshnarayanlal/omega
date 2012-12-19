# loads and runs all tests for the omega project
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'factory_girl'

CURRENT_DIR=File.dirname(__FILE__)
$: << File.expand_path(CURRENT_DIR + "/../lib")

CLOSE_ENOUGH=0.000001

require 'motel'
require 'cosmos'
require 'manufactured'
require 'users'
require 'omega'

FactoryGirl.find_definitions

RSpec.configure do |config|
  config.before(:all) {
  }
  config.before(:each) {
    Motel::RJRAdapter.init
    Users::RJRAdapter.init
    Cosmos::RJRAdapter.init
    Manufactured::RJRAdapter.init

    TestUser.create.clear_privileges

    Omega::Client::Node.client_username = 'omega-test'
    Omega::Client::Node.client_password = 'tset-agemo'
    Omega::Client::Node.node = RJR::LocalNode.new :node_id => 'omega-test'

    Omega::Client::Node.clear

    # preload all server entities
    FactoryGirl.factories.each { |k,v|
      p = k.instance_variable_get(:@parent)
      FactoryGirl.build(k.name) if p =~ /server_.*/
    }
  }

  config.after(:each) {
    Motel::Runner.instance.clear
  }
  config.after(:all) {
  }
end

class TestUser
  def self.create
    @@test_user = FactoryGirl.build(:test_user)
    return self
  end

  def self.clear_privileges
    @@test_user.roles.first.clear_privileges
    return self
  end

  def self.add_privilege(privilege_id, entity_id = nil)
    @@test_user.roles.first.add_privilege \
      Users::Privilege.new(:id => privilege_id, :entity_id => entity_id)
    return self
  end

  def self.add_role(role_id)
    Omega::Roles::ROLES[role_id].each { |pe|
      self.add_privilege pe[0], pe[1]
    }
    return self
  end

  def self.method_missing(method, *args, &bl)
    @@test_user.send(method, *args, &bl)
  end
end

class TestEntity
  include Omega::Client::RemotelyTrackable
  include Omega::Client::TrackState
  entity_type Manufactured::Ship
  get_method "manufactured::get_entity"

  server_state :test_state,
    { :check => lambda { |e| @toggled ||= false ; @toggled = !@toggled },
      :on    => lambda { |e| @on_toggles_called  = true },
      :off   => lambda { |e| @off_toggles_called = true } }

  def initialize
    @@id ||= 0
    @id = (@@id +=  1)
  end

  def id
    @id
  end

  def attr
    0
  end

  def location(val = nil)
    @location = val unless val.nil?
    @location
  end
end

class TestShip
  include Omega::Client::RemotelyTrackable
  include Omega::Client::TrackState
  include Omega::Client::InSystem
  include Omega::Client::HasLocation
  include Omega::Client::InteractsWithEnvironment

  entity_type Manufactured::Ship
  get_method "manufactured::get_entity"

  attr_reader :test_setup_args
  attr_reader :test_setup_invoked

  server_event :test =>
    { :setup =>
      lambda { |*args|
        @test_setup_args = args
        @test_setup_invoked = true
      }
    }
end

class TestStation
  include Omega::Client::RemotelyTrackable
  include Omega::Client::TrackState
  include Omega::Client::InSystem
  include Omega::Client::HasLocation
  include Omega::Client::InteractsWithEnvironment

  entity_type Manufactured::Station
  get_method "manufactured::get_entity"
end

####################################################

class TestMovementStrategy < Motel::MovementStrategy
   attr_accessor :times_moved

   def initialize(args = {})
     @times_moved = 0
     @step_delay = 1
   end

   def move(loc, elapsed_time)
     @times_moved += 1
   end
end
