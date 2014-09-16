﻿require 'rubygems'
require_relative 'lib/extreme_startup/web_server'
include ExtremeStartup
include ExtremeStartup::Questions


warmup_round = [WarmupQuestion]
simple_round = [AdditionQuestion,MaximumQuestion,RememberMeQuestion,GeneralKnowledgeQuestion]
medium_round = [MultiplicationQuestion, PrimesQuestion, SubtractionQuestion, DivisionQuestion]
medium_plus_round = [PowerQuestion, AnagramQuestion, ScrabbleQuestion]
advanced_round = [WebshopQuestion, SquareCubeQuestion]
hard_round   = [WebshopQuestion] * 2 + [FibonacciQuestion, AdditionMultiplicationQuestion, MultiplicationAdditionQuestion,AdditionAdditionQuestion]


# WebServer.settings.default_question_delay = 1
WebServer.settings.question_factory = ExtremeStartup::GatedQuestionFactory.new([
  warmup_round,
  simple_round,
  simple_round + medium_round,
  medium_round + medium_plus_round + advanced_round,
  medium_plus_round + advanced_round + hard_round
])
WebServer.run!