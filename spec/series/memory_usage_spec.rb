describe 'Memory Usage', redis: :real do
  it 'uses ziplist encoding' do
    IntSeries.new('sliced').rpush((1..100_000).to_a).slice_keys.each { |key|
      redis.object(:encoding, key).should == 'ziplist'
    }
  end
end