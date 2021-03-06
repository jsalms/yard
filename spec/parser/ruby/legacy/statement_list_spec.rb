require File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper')

describe YARD::Parser::Ruby::Legacy::StatementList do
  def stmts(code) YARD::Parser::Ruby::Legacy::StatementList.new(code) end
  def stmt(code) stmts(code).first end

  it "should parse dangling block expressions" do
    s = stmt <<-eof
      if
          foo
        puts 'hi'
      end
eof

    s.tokens.to_s(true).should == "if\n          foo\n        ...\n      end"
    s.tokens.to_s.should == "if\n          foo"
    s.block.to_s.should == "puts 'hi'"

    s = stmt <<-eof
      if foo ||
          bar
        puts 'hi'
      end
eof

    s.tokens.to_s(true).should == "if foo ||\n          bar\n        ...\n      end"
    s.tokens.to_s.should == "if foo ||\n          bar"
    s.block.to_s.should == "puts 'hi'"
  end

  it "should allow semicolons within parentheses" do
    s = stmt "(foo; bar)"

    s.tokens.to_s(true).should == "(foo; bar)"
    s.block.should be_nil
  end
  
  it "should allow for non-block statements" do
    s = stmt "hello_world(1, 2, 3)"
    s.tokens.to_s.should == "hello_world(1, 2, 3)"
    s.block.should be_nil
  end

  it "should allow block statements to be used as part of other block statements" do
    s = stmt "while (foo; bar); foo = 12; end; while"

    s.tokens.to_s(true).should == "while (foo; bar); ... end"
    s.tokens.to_s.should == "while (foo; bar)"
    s.block.to_s.should == "foo = 12"
  end

  it "should allow continued processing after a block" do
    s = stmt "if foo; end.stuff"
    s.tokens.to_s(true).should == "if foo; end.stuff"
    s.block.to_s.should == ""

    s = stmt "if foo; end[stuff]"
    s.tokens.to_s(true).should == "if foo; end[stuff]"
    s.block.to_s.should == ""

    s = stmt "if foo; hi end.map do; 123; end"
    s.tokens.to_s(true).should == "if foo; ... end.map do; 123; end"
    s.block.to_s.should == "hi"
  end

  it "should parse default arguments" do
    s = stmt "def foo(bar, baz = 1, bang = 2); bar; end"
    s.tokens.to_s(true).should == "def foo(bar, baz = 1, bang = 2) ... end"
    s.block.to_s.should == "bar"

    s = stmt "def foo bar, baz = 1, bang = 2; bar; end"
    s.tokens.to_s(true).should == "def foo bar, baz = 1, bang = 2; ... end"
    s.block.to_s.should == "bar"

    s = stmt "def foo bar , baz = 1 , bang = 2; bar; end"
    s.tokens.to_s(true).should == "def foo bar , baz = 1 , bang = 2; ... end"
    s.block.to_s.should == "bar"
  end

  it "should parse complex default arguments" do
    s = stmt "def foo(bar, baz = File.new(1, 2), bang = 3); bar; end"
    s.tokens.to_s(true).should == "def foo(bar, baz = File.new(1, 2), bang = 3) ... end"
    s.block.to_s.should == "bar"

    s = stmt "def foo bar, baz = File.new(1, 2), bang = 3; bar; end"
    s.tokens.to_s(true).should == "def foo bar, baz = File.new(1, 2), bang = 3; ... end"
    s.block.to_s.should == "bar"

    s = stmt "def foo bar , baz = File.new(1, 2) , bang = 3; bar; end"
    s.tokens.to_s(true).should == "def foo bar , baz = File.new(1, 2) , bang = 3; ... end"
    s.block.to_s.should == "bar"
  end

  it "should parse blocks with do/end" do
    s = stmt <<-eof
      foo do
        puts 'hi'
      end
    eof

    s.tokens.to_s(true).should == "foo do\n        ...\n      end"
    s.block.to_s.should == "puts 'hi'"
  end
  
  it "should parse blocks with {}" do
    s = stmt "x { y }"
    s.tokens.to_s(true).should == "x { ... }"
    s.block.to_s.should == "y"

    s = stmt "x() { y }"
    s.tokens.to_s(true).should == "x() { ... }"
    s.block.to_s.should == "y"
  end
  
  it "should parse blocks with begin/end" do
    s = stmt "begin xyz end"
    s.tokens.to_s(true).should == "begin ... end"
    s.block.to_s.should == "xyz"
  end
  
  it "should parse nested blocks" do
    s = stmt "foo(:x) { baz(:y) { skippy } }"
    
    s.tokens.to_s(true).should == "foo(:x) { ... }"
    s.block.to_s.should == "baz(:y) { skippy }"
  end

  it "should not parse hashes as blocks" do
    s = stmt "x({})"
    s.tokens.to_s(true).should == "x({})"
    s.block.to_s.should == ""

    s = stmt "x = {}"
    s.tokens.to_s(true).should == "x = {}"
    s.block.to_s.should == ""

    s = stmt "x(y, {})"
    s.tokens.to_s(true).should == "x(y, {})"
    s.block.to_s.should == ""
  end

  it "should parse hashes in blocks with {}" do
    s = stmt "x {x = {}}"

    s.tokens.to_s(true).should == "x {...}"
    s.block.to_s.should == "x = {}"
  end

  it "should parse blocks with {} in hashes" do
    s = stmt "[:foo, x {}]"

    s.tokens.to_s(true).should == "[:foo, x {}]"
    s.block.to_s.should == ""
  end
  
  it "should handle multiple methods" do
    s = stmt <<-eof
      def %; end
      def b; end
    eof
    s.to_s.should == "def %; end"
  end
  
  it "should handle nested methods" do
    s = stmt <<-eof
      def *(o) def +@; end
        def ~@
        end end
    eof
    s.tokens.to_s(true).should == "def *(o) ... end"
    s.block.to_s.should == "def +@; end\n        def ~@\n        end"

    s = stmts(<<-eof)
      def /(other) 'hi' end
      def method1
        def dynamic; end
      end
    eof
    s[1].to_s.should == "def method1\n        def dynamic; end\n      end"
  end
  
  it "should get comment line numbers" do
    s = stmt <<-eof
      # comment
      # comment
      # comment
      def method; end
    eof
    s.comments.should == ["comment", "comment", "comment"]
    s.comments_range.should == (1..3)

    s = stmt <<-eof

      # comment
      # comment
      def method; end
    eof
    s.comments.should == ["comment", "comment"]
    s.comments_range.should == (2..3)

    s = stmt <<-eof
      # comment
      # comment

      def method; end
    eof
    s.comments.should == ["comment", "comment"]
    s.comments_range.should == (1..2)

    s = stmt <<-eof
      # comment
      def method; end
    eof
    s.comments.should == ["comment"]
    s.comments_range.should == (1..1)

    s = stmt <<-eof
      def method; end # comment
    eof
    s.comments.should == ["comment"]
    s.comments_range.should == (1..1)
  end
end
