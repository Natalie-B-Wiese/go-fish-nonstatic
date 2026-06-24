require_relative '../card'

# a representation of four cards of the same value
class Book
  attr_reader :value, :rank

  SIZE = 4

  def initialize(rank)
    @rank = rank
    @value = Card.rank_to_value(rank)
  end
end
