require_relative 'question'
require_relative 'questions/webshop_conversation'
require_relative 'questions/flight_time'


module ExtremeStartup
  class QuestionFactory
    attr_reader :round

    def initialize
      @round = 1
      @question_types = [
        AdditionQuestion,
        MaximumQuestion,
        MultiplicationQuestion,
        SquareCubeQuestion,
        GeneralKnowledgeQuestion,
        PrimesQuestion,
        SubtractionQuestion,
        FibonacciQuestion,
        PowerQuestion,
        AdditionAdditionQuestion,
        AdditionMultiplicationQuestion,
        MultiplicationAdditionQuestion,
        AnagramQuestion,
        ScrabbleQuestion
      ]
    end

    def next_question(player)
      window_end = (@round * 2 - 1)
      window_start = [0, window_end - 4].max
      available_question_types = @question_types[window_start..window_end]
      available_question_types.sample.new(player)
    end

    def advance_round
      @round += 1
    end

  end

  class WarmupQuestion < Question
    def initialize(player)
      @player = player
    end

    def correct_answer
      @player.name
    end

    def as_text
      "what is your name"
    end
  end

  class GatedQuestionFactory
    def initialize(question_sets)
      @question_sets = question_sets
      @player_question_set_index = Hash.new(0)
    end
    def next_question(player)
      available_questions(player).sample.new(player)
    end
    def advance_round
    end
    def advance_player(player)
      index = @player_question_set_index[player]
      question_set = @question_sets[index]
      while index < @question_sets.length-1 and has_answered_all_questions(player, question_set)
        @player_question_set_index[player] += 1
        index = @player_question_set_index[player]
        question_set = @question_sets[index]
      end
    end
    def available_questions(player)
      advance_player(player)
      @question_sets[@player_question_set_index[player]]
    end
    def has_answered_all_questions(player, question_set)
      question_set.count { |q| player.correct_answers(q) == 0 } == 0
    end
  end

  class WarmupQuestionFactory
    def next_question(player)
      WarmupQuestion.new(player)
    end

    def advance_round
      raise("please just restart the server")
    end
  end

  # TODO This should have several question sets, but it didn't advance to the last one!

  class WorkshopQuestionFactory < GatedQuestionFactory
    def initialize
      super([
          [RememberMeQuestion,
          ExtremeStartup::Questions::WebshopQuestion,
          ExtremeStartup::Questions::WebshopQuestion,
          ExtremeStartup::Questions::WebshopQuestion,
          ExtremeStartup::Questions::WebshopQuestion,
          ExtremeStartup::Questions::FlightTime,
          ExtremeStartup::Questions::FlightTime,
          ExtremeStartup::Questions::FlightTime,
          DivisionQuestion,
          AdditionQuestion,
          MaximumQuestion,
          MultiplicationQuestion,
          SquareCubeQuestion,
          GeneralKnowledgeQuestion,
          PrimesQuestion,
          SubtractionQuestion,
          FibonacciQuestion,
          PowerQuestion,
          AdditionAdditionQuestion,
          AdditionMultiplicationQuestion,
          MultiplicationAdditionQuestion
        ]])
    end
  end

end