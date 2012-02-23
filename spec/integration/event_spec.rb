describe Event do
  it "should be valid" do
    event = Event.new
    event.should be_valid
  end
end