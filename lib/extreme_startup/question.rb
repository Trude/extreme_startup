# encoding: utf-8
require 'set'
require 'prime'



module ExtremeStartup
  class Question
    class << self
      def generate_uuid
        @uuid_generator ||= UUID.new
        @uuid_generator.generate.to_s[0..7]
      end
    end

    def initialize(player)
      @player = player
    end

    def ask(player)
      url = player.url + '?q=' + URI.escape(self.to_s)
      puts "GET: " + url
      begin
        response = get(url)
        if (response.success?) then
          self.answer = response.to_s
        else
          @problem = "error_response"
        end
      rescue => exception
        puts exception
        @problem = "no_server_response"
      end
    end

    def get(url)
      HTTParty.get(url)
    end

    def result
      if @answer && self.answered_correctly?(answer)
        "correct"
      elsif @answer
        "wrong"
      else
        @problem
      end
    end

    def delay_before_next(delay = 5)
      case result
        when "correct"        then delay
        when "wrong"          then delay*2
        else delay*4
      end
    end

    def was_answered_correctly
      result == "correct"
    end

    def was_answered_wrongly
      result == "wrong"
    end

    def display_result
      "\tquestion: #{self.to_s}\n\tanswer: #{answer}\n\tresult: #{result}"
    end

    def id
      @id ||= Question.generate_uuid
    end

    def to_s
      "#{id}: #{as_text}"
    end

    def answer=(answer)
      @answer = answer.force_encoding("UTF-8")
    end

    def answer
      @answer && @answer.downcase.strip
    end

    def answered_correctly?(answer)
      correct_answer.to_s.downcase.strip == answer
    end

    def points
      10
    end
  end

  class BinaryMathsQuestion < Question
    def initialize(player, *numbers)
      super(player)
      if numbers.any?
        @n1, @n2 = *numbers
      else
        @n1, @n2 = rand(20), rand(20)
      end
    end
  end

  class TernaryMathsQuestion < Question
    def initialize(player, *numbers)
      if numbers.any?
        @n1, @n2, @n3 = *numbers
      else
        @n1, @n2, @n3 = rand(20), rand(20), rand(20)
      end
    end
  end

  class SelectFromListOfNumbersQuestion < Question
    def initialize(player, *numbers)
      if numbers.any?
        @numbers = *numbers
      else
        size = rand(2)
        @numbers = random_numbers[0..size].concat(candidate_numbers.shuffle[0..size]).shuffle
      end
    end

    def random_numbers
      randoms = Set.new
      loop do
        randoms << rand(1000)
        return randoms.to_a if randoms.size >= 5
      end
    end

    def correct_answer
       @numbers.select do |x|
         should_be_selected(x)
       end.join(', ')
     end
  end

  class MaximumQuestion < SelectFromListOfNumbersQuestion
    def as_text
      "which of the following numbers is the largest: " + @numbers.join(', ')
    end
    def points
      40
    end
    private
      def should_be_selected(x)
        x == @numbers.max
      end

      def candidate_numbers
          (1..100).to_a
      end
    end

  class AdditionQuestion < BinaryMathsQuestion
    def as_text
      "what is #{@n1} plus #{@n2}"
    end
  private
    def correct_answer
      @n1 + @n2
    end
  end

  class SubtractionQuestion < BinaryMathsQuestion
    def as_text
      "what is #{@n1} minus #{@n2}"
    end
  private
    def correct_answer
      @n1 - @n2
    end
  end

  class MultiplicationQuestion < BinaryMathsQuestion
    def as_text
      "what is #{@n1} multiplied by #{@n2}"
    end
  private
    def correct_answer
      @n1 * @n2
    end
  end

  class DivisionQuestion < BinaryMathsQuestion
    def as_text
      "what is #{@n1} divided by #{@n2}"
    end
    def points
      80
    end
    def answered_correctly?(answer)
      (Float(answer) * @n2).round(2) == @n1 rescue false
    end
    def correct_answer
      ""
    end
  end

  class AdditionAdditionQuestion < TernaryMathsQuestion
    def as_text
      "what is #{@n1} plus #{@n2} plus #{@n3}"
    end
    def points
      30
    end
  private
    def correct_answer
      @n1 + @n2 + @n3
    end
  end

  class AdditionMultiplicationQuestion < TernaryMathsQuestion
    def as_text
      "what is #{@n1} plus #{@n2} multiplied by #{@n3}"
    end
    def points
      60
    end
  private
    def correct_answer
      @n1 + @n2 * @n3
    end
  end

  class MultiplicationAdditionQuestion < TernaryMathsQuestion
    def as_text
      "what is #{@n1} multiplied by #{@n2} plus #{@n3}"
    end
    def points
      50
    end
  private
    def correct_answer
      @n1 * @n2 + @n3
    end
  end

  class PowerQuestion < BinaryMathsQuestion
    def as_text
      "what is #{@n1} to the power of #{@n2}"
    end
    def points
      20
    end
  private
    def correct_answer
      @n1 ** @n2
    end
  end

  class SquareCubeQuestion < SelectFromListOfNumbersQuestion
    def as_text
      "which of the following numbers is both a square and a cube: " + @numbers.join(', ')
    end
    def points
      60
    end
  private
    def should_be_selected(x)
      is_square(x) and is_cube(x)
    end

    def candidate_numbers
        square_cubes = (1..100).map { |x| x ** 3 }.select{ |x| is_square(x) }
        squares = (1..50).map { |x| x ** 2 }
        square_cubes.concat(squares)
    end

    def is_square(x)
      if (x ==0)
        return true
      end
      (x % (Math.sqrt(x).round(4))) == 0
    end

    def is_cube(x)
      if (x ==0)
        return true
      end
      (x % (Math.cbrt(x).round(4))) == 0
    end
  end

  class PrimesQuestion < SelectFromListOfNumbersQuestion
     def as_text
       "which of the following numbers are primes: " + @numbers.join(', ')
     end
     def points
       60
     end
   private
     def should_be_selected(x)
       Prime.prime? x
     end

     def candidate_numbers
       Prime.take(100)
     end
   end

  class FibonacciQuestion < BinaryMathsQuestion
     def which_number
      return @n1 + 1000 if (@player.correct_answers(self.class) > 25)
      return @n1 + 200 if (@player.correct_answers(self.class) > 15)
      @n1 + 4
    end

    def as_text
      n = which_number
      if (n > 20 && n % 10 == 1)
        return "what is the #{n}st number in the Fibonacci sequence"
      end
      if (n > 20 && n % 10 == 2)
        return "what is the #{n}nd number in the Fibonacci sequence"
      end
      return "what is the #{n}th number in the Fibonacci sequence"
    end
    def points
      50
    end

    def correct_answer
      (@correct_answer ||= calculate)
    end

    def calculate
      n = 1
      n_minus_one = 1
      i = 2
      while i < which_number
        next_n = n+n_minus_one
        n_minus_one = n
        n = next_n
        i += 1
      end
      return n
    end
  end

  class GeneralKnowledgeQuestion < Question
    class << self
      def question_bank
        [
          ["who is the Prime Minister of Great Britain", "David Cameron"],
          ["which city is the Eiffel tower in", "Paris"],
          ["what currency did Spain use before the Euro", "peseta"],
          ["what colour is a banana", "yellow"],
          ["who played James Bond in the film Dr No", "Sean Connery"]
        ]
      end
    end

    def initialize(player)
      question = GeneralKnowledgeQuestion.question_bank.sample
      @question = question[0]
      @correct_answer = question[1]
    end

    def as_text
      @question
    end

    def correct_answer
      @correct_answer
    end
  end

  require 'yaml'
  class AnagramQuestion < Question
    def as_text
      possible_words = [@anagram["correct"]] + @anagram["incorrect"]
      %Q{which of the following is an anagram of "#{@anagram["anagram"]}": #{possible_words.shuffle.join(", ")}}
    end

    def initialize(player, *words)
      if words.any?
        @anagram = {}
        @anagram["anagram"], @anagram["correct"], *@anagram["incorrect"] = words
      else
        anagrams = YAML.load_file(File.join(File.dirname(__FILE__), "anagrams.yaml"))
        @anagram = anagrams.sample
      end
    end

    def correct_answer
      @anagram["correct"]
    end
  end

  class ScrabbleQuestion < Question
    def as_text
      "what is the norwegian scrabble score of #{@word}"
    end

    def initialize(player, word=nil)
      if word
        @word = word
      else
        @word = ["banan", "september", "jordbær", "sau", "ljå", "øye", "sebra", "steria"].sample
      end
    end

    def correct_answer
      @word.chars.inject(0) do |score, letter|
        score += scrabble_scores[letter.downcase]
      end
    end

    private

    def scrabble_scores
      scores = {}
      %w{a d e i l n r s t}.each  {|l| scores[l] = 1 }
      %w{f g k m o}.each          {|l| scores[l] = 2 }
      %w{h}.each                  {|l| scores[l] = 3 }
      %w{b j p u v å}.each        {|l| scores[l] = 4 }
      %w{ø}.each                  {|l| scores[l] = 5 }
      %w{y æ}.each                {|l| scores[l] = 6 }
      %w{w}.each                  {|l| scores[l] = 8 }
      %w{c}.each                  {|l| scores[l] = 10 }
      scores
    end
  end

  class ConversationalQuestion < Question
    def initialize(player, spawn_rate = 80)
      super(player)
      @session = get_session(player, spawn_rate)
    end

    def get(url)
      @session.get(url)
    end

    def answer=(answer)
      @answer = answer
      @session.add_answer(answer)
      @player.answers_for_question(self.class, result)
    end

    def answered_correctly?(answer)
      @session.answered_correctly?
    end

    def as_text
      @question ||= @session.question
    end

    def correct_answer
      @session.correct_answer
    end

    def points
      @session.points
    end

    def penalty
      @session.penalty
    end

    def self.sessions
      @sessions ||= {}
    end

    def get_session(player, spawn_rate)
      sessions = (self.class.sessions[player] ||= [])
      sessions.reject! { |session| session.dead? }
      sessions << create_session if spawn?(sessions, spawn_rate)
      self.class.sessions[player].sample
    end

    def spawn?(sessions, spawn_rate)
      sessions.empty? || (rand(100) < spawn_rate)
    end
  end

  class Conversation
    def get(url)
      response = HTTParty.get(url, :headers => headers)
      return response unless response.success?

      cookie = response.headers['set-cookie']
      if cookie
        cookie_name = cookie.split(/;/).first.partition("=").first
        cookie_value = cookie.split(/;/).first.partition("=").last
        @cookies ||= {}
        @cookies[cookie_name] = cookie_value
      end
      response
    end

    def cookies
      @cookies.collect { |k,v| "#{k}=#{v}" }.join("; ")
    end

    def headers
      @cookies ? { "cookie" => cookies } : {}
    end

    def answered_correctly?
      @answer && correct_answer.strip.to_s == @answer.strip.to_s
    end

    def score
      answered_correctly? ? points : penalty
    end

    def points
      10
    end

    def penalty
      - points / 10
    end
  end

  class RememberMeConversation < Conversation
    def initialize
      @name = %w(abe bob chuck dick evan fred george hob ivan jim pete ric).sample
      @attempts = 0
    end

    def add_answer(answer)
      @answer = answer
      @attempts += 1
    end

    def dead?
      !answered_correctly? || @attempts > 10
    end

    def question
      if answered_correctly?
        return "I was here before. what is my name"
      else
        return "my name is #{@name}. what is my name"
      end
    end

    def correct_answer
      @name
    end

    def points
      30 # + @attempts * 10
    end
  end

  class RememberMeQuestion < ConversationalQuestion
    def create_session
      RememberMeConversation.new
    end
  end

end
