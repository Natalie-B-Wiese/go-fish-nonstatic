require_relative '../card'

# a representation of four cards of the same value
class Book
  attr_reader :value, :rank

  SIZE = 4

  def initialize(rank)
    @rank = rank
    @value = Card.rank_to_value(rank)
  end

  def to_image_name
    "#{Card.rank_to_s(rank).downcase}_of_hearts.png"
  end
end
