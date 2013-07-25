module Solve
  require_relative 'solve/artifact'
  require_relative 'solve/constraint'
  require_relative 'solve/demand'
  require_relative 'solve/dependency'
  require_relative 'solve/gem_version'
  require_relative 'solve/errors'
  require_relative 'solve/graph'
  require_relative 'solve/solver'
  require_relative 'solve/version'

  class << self
    # A quick solve. Given the "world" as we know it (the graph) and a list of
    # requirements (demands) which must be met. Return me the best solution of
    # artifacts and verisons that I should use.
    #
    # If a ui object is passed in, the resolution will be traced
    #
    # @param [Solve::Graph] graph
    # @param [Array<Solve::Demand>, Array<String, String>] demands
    #
    # @option options [#say] :ui (nil) a ui object for output
    # @option options [Boolean] :sorted (false) should the output be a sorted list rather than a Hash
    #
    # @raise [NoSolutionError]
    #
    # @return [Hash]
    def it!(graph, demands, options = {})
      Solver.new(graph, demands, options[:ui]).resolve(options)
    end
  end
end
