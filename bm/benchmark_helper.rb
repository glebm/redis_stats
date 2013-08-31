require 'gnuplot'
require 'benchmark'

module BenchmarkHelper
  extend self
  def plot(x, *ys, &block)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        block.call(plot)
        ys.each do |y|
          plot.data << Gnuplot::DataSet.new([x, y]) do |ds|
            ds.with = "linespoints"
            ds.notitle
          end
        end
      end
    end
  end
end