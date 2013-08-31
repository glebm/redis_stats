require 'gnuplot'
require 'benchmark'

module BenchmarkHelper
  extend self
  def plot(x, *ys, &block)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        block.call(plot)
        ys.each do |y|
          plot.data << Gnuplot::DataSet.new([x, y[:data]]) do |ds|
            ds.with = "linespoints"
            ds.title = y[:title] || y[:label]
          end
        end
      end
    end
  end
end