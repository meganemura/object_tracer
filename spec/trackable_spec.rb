require "spec_helper"

class Student
  def initialize(name, age)
    @name = name
    @age = age
  end

  def self.foo; end

  def name
    @name
  end

  def age
    @age
  end

  def age=(age)
    @age = age
  end
end

class School
  def initialize(name)
    @name = name
  end

  def name
    @name
  end
end

RSpec.describe TappingDevice::Trackable do
  include described_class

  describe "#tap_initialization_of!" do
    before do
      stop_tapping!(Student)
    end

    after do
      stop_tapping!(Student)
    end

    it "tracks Student's initialization" do
      count = 0
      tap_initialization_of!(Student) do |options|
        count += 1
      end

      Student.new("Stan", 18)
      Student.new("Jane", 23)

      expect(count).to eq(2)
    end
    it "doesn't track School's initialization" do
      count = 0
      tap_initialization_of!(Student) do |options|
        count += 1
      end

      School.new("A school")

      expect(count).to eq(0)
    end
    it "doesn't track non-initialization method calls" do
      count = 0
      tap_initialization_of!(Student) do |options|
        count += 1
      end

      Student.foo

      expect(count).to eq(0)
    end
  end

  describe "#tap_calls_on!" do
    it "tracks method calls on the tapped object" do
      stan = Student.new("Stan", 18)
      jane = Student.new("Jane", 23)

      calls = []
      tap_calls_on!(stan) do |payload|
        calls << [payload[:receiver].object_id, payload[:method_name], payload[:return_value]]
      end

      stan.name
      stan.age
      jane.name
      jane.age

      expect(calls).to match_array(
        [
          [stan.object_id, :name, "Stan"],
          [stan.object_id, :age, 18]
        ]
      )
    end
    it "supports multiple tappings" do
      stan = Student.new("Stan", 18)

      count_1 = 0
      count_2 = 0

      tap_calls_on!(stan) { count_1 += 1 }
      tap_calls_on!(stan) { count_2 -= 1 }

      stan.name

      expect(count_1).to eq(1)
      expect(count_2).to eq(-1)
    end
    it "tracks alias" do
      c = Class.new(Student)
      c.class_eval do
        alias :alias_name :name
      end
      stan = c.new("Stan", 18)

      names = []
      tap_calls_on!(stan) do |payload|
        names << payload[:method_name]
      end

      stan.alias_name

      expect(names).to match_array([:alias_name])
    end

    describe "yield parameters" do
      it "detects correct arguments" do
        stan = Student.new("Stan", 18)

        arguments = []

        tap_calls_on!(stan) do |payload|
          arguments = payload[:arguments]
        end

        stan.age = (25)

        expect(arguments).to eq([[:age, 25]])
      end
      it "returns correct filepath and line number" do
        stan = Student.new("Stan", 18)

        filepath = ""
        line_number = 0

        tap_calls_on!(stan) do |payload|
          filepath = payload[:filepath]
          line_number = payload[:line_number]
        end

        line_mark = __LINE__
        stan.age

        expect(filepath).to eq(__FILE__)
        expect(line_number).to eq((line_mark+1).to_s)
      end
    end

    describe "options: exclude_from" do
      it "skips calls that matches the pattern" do
      stan = Student.new("Stan", 18)
      count = 0
      tap_calls_on!(stan, filter_by_paths: [/spec/]) { count += 1 }

      stan.name

      expect(count).to eq(0)
      end
    end
  end

  describe "#stop_tapping!" do
    it "stopps tapping" do
      count = 0
      tap_initialization_of!(Student) do |options|
        count += 1
      end

      Student.new("Stan", 18)

      stop_tapping!(Student)

      Student.new("Jane", 23)

      expect(count).to eq(1)
    end
    it "stops multiple tappings" do
      stan = Student.new("Stan", 18)

      count_1 = 0
      count_2 = 0

      tap_calls_on!(stan) { count_1 += 1 }
      tap_calls_on!(stan) { count_2 -= 1 }

      stan.name

      expect(count_1).to eq(1)
      expect(count_2).to eq(-1)

      stop_tapping!(stan)

      stan.name

      expect(count_1).to eq(1)
      expect(count_2).to eq(-1)
    end
  end
end
