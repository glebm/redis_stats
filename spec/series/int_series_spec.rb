require 'spec_helper'

describe 'IntSeries' do
  before do
    Redis.current = MockRedis.new
  end

  it 'works like a basic list (1 slice)' do
    series = IntSeries.new('ints', list_slice_size: 4)
    series << 1 << 2 << 3 << 4
    series.length.should == 4
    series.to_a.should == %w(1 2 3 4)
  end

  it 'works like a basic list (3 slices)' do
    series = IntSeries.new('ints', list_slice_size: 2)
    series << 'a' << 'b' << 'c' << 'd' << 'e'
    series.from.should == 0
    series.to.should == 5
    series.length.should == 5
    series.to_a.should == %w(a b c d e)
  end


  it 'extends from and to' do
    series = IntSeries.new('ints', list_slice_size: 2)
    series[-5] = 1
    series.to_a.should == %w(1)
    series.from.should == -5
    series.to.should == -4
    series[3] = 1
    series.to_a.should == %w(1 0 0 0 0 0 0 0 1)
    series.from.should == -5
    series.to.should == 4

  end

  it 'provides zeros for missing data' do
    series    = IntSeries.new('ints', list_slice_size: 2)
    series[1] = 1
    series[5] = 3
    series.from.should == 1
    series.to.should == 6
    series.size.should == 5
    series.to_a.should == %w(1 0 0 0 3)
  end

  it 'provides zeros for missing data when extending backwards' do
    series = IntSeries.new('ints', list_slice_size: 2)
    series << 1 << 2 << 3
    series[-1] = -1
    series[-3] = -3
    series[-2] = -2
    series.length.should == 6
    series.from.should == -3
    series.to.should == 3
    series.to_a.should == %w(-3 -2 -1 1 2 3)
  end
end