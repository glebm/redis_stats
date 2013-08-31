require 'spec_helper'

describe DaySeries, redis: :real do
  let!(:today) { Date.today }

  it 'works' do
    s = DaySeries.new('daily-r')

    s[today] = 1
    s.to_a.should == %w(1)
    s.from.should == today
    s.to.should == today + 1
    s.size.should == 1
    s << 2
    s.to.should == today + 2
    s.to_a.should == %w(1 2)
  end

end