# ship module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'

describe Manufactured::Ship do

  it "should successfully accept and set ship params" do
     type = Manufactured::Ship::SHIP_TYPES.first
     size = Manufactured::Ship::SHIP_SIZES[type]

     ship = Manufactured::Ship.new :id => 'ship1', :user_id => 5,
                                   :type => type.to_s, :size => size,
                                   :solar_system => 'system1'
                                   
     ship.id.should == 'ship1'
     ship.user_id.should == 5
     ship.location.should_not be_nil
     ship.location.x.should == 0
     ship.location.y.should == 0
     ship.location.z.should == 0
     ship.type.should == type
     ship.size.should == size

     ship.parent.should == 'system1'
     ship.parent = 'system2'
     ship.parent.should == 'system2'
  end

  it "should verify validity of ship" do
    ship = Manufactured::Ship.new :id => 'ship1', :user_id => 'tu', :solar_system => Cosmos::SolarSystem.new
    ship.valid?.should be_true

    ship.id = nil
    ship.valid?.should be_false
    ship.id = 'ship1'

    ship.location = nil
    ship.valid?.should be_false
    ship.location = Motel::Location.new

    ship.solar_system = nil
    ship.valid?.should be_false
    ship.solar_system = Cosmos::SolarSystem.new

    ship.user_id = nil
    ship.valid?.should be_false
    ship.user_id = 'tu'

    ship.type = nil
    ship.valid?.should be_false

    ship.type = 'fooz'
    ship.valid?.should be_false
    ship.type = :frigate

    ship.size = 512
    ship.valid?.should be_false
    ship.size = Manufactured::Ship::SHIP_SIZES[:frigate]

    ship.dock_at(2)
    ship.valid?.should be_false
    ship.dock_at(Manufactured::Station.new)

    ship.start_mining(false)
    ship.valid?.should be_false
    ship.start_mining(Cosmos::Asteroid.new)

    ship.notification_callbacks << nil
    ship.valid?.should be_false
    ship.notification_callbacks.clear
    ship.notification_callbacks << Manufactured::Callback.new(:foobar)

    ship.resources[99] = 'false'
    ship.valid?.should be_false
    ship.resources.clear
    ship.resources['gold'] = 500

    ship.valid?.should be_true
  end

  it "should set parent location when setting location" do
    sys1 = Cosmos::SolarSystem.new :location => Motel::Location.new(:id => 1)
    ship = Manufactured::Ship.new :id => 'ship1', :solar_system => sys1
    loc = Motel::Location.new
    ship.location = loc
    loc.parent.should == sys1.location
  end

  it "should be dockable at stations" do
    ship = Manufactured::Ship.new :id => 'ship1'
    station = Manufactured::Station.new :id => 'station1'

    ship.docked?.should be_false
    ship.docked_at.should be_nil

    ship.dock_at(station)
    ship.docked?.should be_true
    ship.docked_at.should == station

    ship.undock
    ship.docked?.should be_false
    ship.docked_at.should be_nil
  end

  it "should be permit mining resource sources" do
    ship   = Manufactured::Ship.new :id => 'ship1'
    res    = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    source = Cosmos::ResourceSource.new :resource => res, :quantity => 50

    ship.mining?.should be_false
    ship.mining.should be_nil

    ship.start_mining(source)
    ship.mining?.should be_true
    ship.mining.should == source

    ship.stop_mining
    ship.mining?.should be_false
    ship.mining.should be_nil
  end

  it "should permit storing resources locally" do
    ship   = Manufactured::Ship.new :id => 'ship1'
    ship.resources.should be_empty
    
    res = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    ship.add_resource res.id, 50
    ship.resources.should_not be_empty
    ship.resources.size.should == 1
    ship.resources[res.id].should == 50

    ship.add_resource res.id, 60
    ship.resources.size.should == 1
    ship.resources[res.id].should == 110

    ship.remove_resource res.id, 40
    ship.resources.size.should == 1
    ship.resources[res.id].should == 70

    ship.remove_resource res.id, 70
    ship.resources.size.should == 1
    ship.resources[res.id].should == 0
  end

  it "should permit retreival of current cargo quantity" do
    ship   = Manufactured::Ship.new :id => 'ship1'
    res1 = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
    res2 = Cosmos::Resource.new :name => 'steel', :type => 'metal'
    ship.add_resource res1.id, 50
    ship.add_resource res1.id, 60
    ship.cargo_quantity.should == 110
  end

  it "should be convertable to json" do
    system1 = Cosmos::SolarSystem.new :name => 'system1'
    location= Motel::Location.new :id => 20, :y => -15
    cb = Manufactured::Callback.new 'attacked', :endpoint => 'foobar'
    s = Manufactured::Ship.new(:id => 'ship42', :user_id => 420,
                               :type => :frigate, :size => 50, 
                               :solar_system => system1,
                               :location => location,
                               :notifications => [cb])

    station = Manufactured::Station.new :id => 'station42'
    s.dock_at(station)

    j = s.to_json
    j.should include('"json_class":"Manufactured::Ship"')
    j.should include('"id":"ship42"')
    j.should include('"user_id":420')
    j.should include('"type":"frigate"')
    j.should include('"size":50')
    j.should include('"json_class":"Manufactured::Callback"')
    j.should include('"type":"attacked"')
    j.should include('"endpoint":"foobar"')
    j.should include('"json_class":"Manufactured::Station"')
    j.should include('"id":"station42"')
    j.should include('"json_class":"Motel::Location"')
    j.should include('"id":20')
    j.should include('"y":-15')
    j.should include('"json_class":"Cosmos::SolarSystem"')
    j.should include('"name":"system1"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Manufactured::Ship","data":{"type":"frigate","user_id":420,"notifications":[{"json_class":"Manufactured::Callback","data":{"type":"attacked","endpoint":"foobar"}}],"solar_system":{"json_class":"Cosmos::SolarSystem","data":{"star":null,"planets":[],"jump_gates":[],"name":"system1","background":"system1","location":{"json_class":"Motel::Location","data":{"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"remote_queue":null,"parent_id":null,"x":0,"y":0,"z":0,"id":null,"restrict_view":true}}}},"size":50,"docked_at":{"json_class":"Manufactured::Station","data":{"type":null,"user_id":null,"solar_system":null,"size":null,"id":"station42","location":{"json_class":"Motel::Location","data":{"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"remote_queue":null,"parent_id":null,"x":0,"y":0,"z":0,"id":null,"restrict_view":true}}}},"id":"ship42","location":{"json_class":"Motel::Location","data":{"restrict_modify":true,"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"remote_queue":null,"parent_id":null,"x":null,"y":-15,"z":null,"id":20,"restrict_view":true}}}}'
    s = JSON.parse(j)

    s.class.should == Manufactured::Ship
    s.id.should == "ship42"
    s.user_id.should == 420
    s.type.should == :frigate
    s.size.should == 50
    s.notification_callbacks.size.should == 1
    s.notification_callbacks.first.type == "attacked"
    s.notification_callbacks.first.endpoint_id.type == "foobar"
    #s.docked_at.should_not be_nil
    #s.docked_at.id.should == 'station42'
    s.location.should_not be_nil
    s.location.y.should == -15
    s.solar_system.should_not be_nil
    s.solar_system.name.should == 'system1'
  end

end
