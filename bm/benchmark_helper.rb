require 'gnuplot'

module BenchmarkHelper
  extend self
  def plot(x, *ys)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal 'png'
        plot.output 'plot.png'
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