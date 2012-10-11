require '../spec_helper'

describe Event do

  let(:valid_parameters) { {:name => "MyEvent", :page_layout => "standard"} }

  it "should be valid" do
    event = Event.new(valid_parameters)
    event.should be_valid
  end
end