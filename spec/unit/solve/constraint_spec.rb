require 'spec_helper'

RSpec::Matchers.define :satisfies do |*args|
  match do |constraint|
    constraint.satisfies?(*args).should be_true
  end
end

describe Solve::Constraint do
  let(:valid_string) { ">= 0.0.0" }
  let(:invalid_string) { "x23u7089213.*" }

  describe "ClassMethods" do
    subject { Solve::Constraint }

    describe "::new" do
      it "returns a new instance of Constraint" do
        subject.new(valid_string).should be_a(Solve::Constraint)
      end

      it "assigns the parsed operator to the operator attribute" do
        subject.new(valid_string).operator.should eql(">=")
      end

      it "assigns the parsed operator to the operator attribute with no separation between operator and version" do
        subject.new(">=0.0.0").operator.should eql(">=")
      end

      it "assigns the parsed version string as an instance of Version to the version attribute" do
        result = subject.new(valid_string)

        result.version.should be_a(Solve::Version)
        result.version.to_s.should eql("0.0.0")
      end

      context "given a string that does not match the Constraint REGEXP" do
        it "raises an InvalidConstraintFormat error" do
          lambda {
            subject.new(invalid_string)
          }.should raise_error(Solve::Errors::InvalidConstraintFormat)
        end
      end

      context "given a nil value" do
        it "raises an InvalidConstraintFormat error" do
          lambda {
            subject.new(nil)
          }.should raise_error(Solve::Errors::InvalidConstraintFormat)
        end
      end

      context "given a string containing only a major and minor version" do
        it "has a nil value for patch" do
          subject.new("~> 1.2").patch.should be_nil
        end
      end
    end

    describe "::split" do
      it "returns an array containing two items" do
        subject.split(valid_string).should have(2).items
      end

      it "returns the operator at index 0" do
        subject.split(valid_string)[0].should eql(">=")
      end

      it "returns the version string at index 1" do
        subject.split(valid_string)[1].should eql("0.0.0")
      end

      context "given a string that does not match the Constraint REGEXP" do
        it "returns nil" do
          subject.split(invalid_string).should be_nil
        end
      end

      context "given a string that does not contain an operator" do
        it "returns a constraint constraint with a default operator (=)" do
          subject.split("1.0.0")[0].should eql("=")
        end
      end
    end
  end

  describe "#satisfies?", :focus do
    subject { Solve::Constraint.new("= 1.0.0") }

    it { should satisfies("1.0.0") }

    it "accepts a Version for version" do
      should satisfies(Solve::Version.new("1.0.0"))
    end

    context "strictly greater than (>)" do
      subject { Solve::Constraint.new("> 1.0.0-alpha") }

      it { should satisfies("2.0.0") }
      it { should satisfies("1.0.0") }
      it { should_not satisfies("1.0.0-alpha") }
    end

    context "strictly less than (<)" do
      subject { Solve::Constraint.new("< 1.0.0+build.20") }

      it { should satisfies("0.1.0") }
      it { should satisfies("1.0.0") }
      it { should_not satisfies("1.0.0+build.21") }
    end

    context "strictly equal to (=)" do
      subject { Solve::Constraint.new("= 1.0.0") }

      it { should_not satisfies("0.9.9+build") }
      it { should satisfies("1.0.0") }
      it { should_not satisfies("1.0.1") }
      it { should_not satisfies("1.0.0-alpha") }
    end

    context "greater than or equal to (>=)" do
      subject { Solve::Constraint.new(">= 1.0.0") }

      it { should_not satisfies("0.9.9+build") }
      it { should_not satisfies("1.0.0-alpha") }
      it { should satisfies("1.0.0") }
      it { should satisfies("1.0.1") }
      it { should satisfies("2.0.0") }
    end

    context "greater than or equal to (<=)" do
      subject { Solve::Constraint.new("<= 1.0.0") }

      it { should satisfies("0.9.9+build") }
      it { should satisfies("1.0.0-alpha") }
      it { should satisfies("1.0.0") }
      it { should_not satisfies("1.0.0+build") }
      it { should_not satisfies("1.0.1") }
      it { should_not satisfies("2.0.0") }
    end

    %w[~> ~].each do |operator|
      describe "aproximately (#{operator})" do
        context "when the last value in the constraint is for minor" do
          subject { Solve::Constraint.new("#{operator} 1.2") }

          it { should_not satisfies("1.1.0") }
          it { should_not satisfies("1.2.0-alpha") }
          it { should satisfies("1.2.0") }
          it { should satisfies("1.2.3") }
          it { should satisfies("1.2.3+build") }
          it { should_not satisfies("2.0.0-0") }
          it { should_not satisfies("2.0.0") }
        end

        context "when the last value in the constraint is for minor" do
          subject { Solve::Constraint.new("#{operator} 1.2.3") }

          it { should_not satisfies("1.1.0") }
          it { should_not satisfies("1.2.3-alpha") }
          it { should_not satisfies("1.2.2") }
          it { should satisfies("1.2.3") }
          it { should satisfies("1.2.5+build") }
          it { should_not satisfies("1.3.0-0") }
          it { should_not satisfies("1.3.0") }
        end

        context "when the last value in the constraint is for pre_release with a last numeric identifier" do
          subject { Solve::Constraint.new("#{operator} 1.2.3-4") }

          it { should_not satisfies("1.2.3") }
          it { should satisfies("1.2.3-4") }
          it { should satisfies("1.2.3-10") }
          it { should satisfies("1.2.3-10.5+build.33") }
          it { should_not satisfies("1.2.3--") }
          it { should_not satisfies("1.2.3-alpha") }
          it { should_not satisfies("1.2.3") }
          it { should_not satisfies("1.2.4") }
          it { should_not satisfies("1.3.0") }
        end

        context "when the last value in the constraint is for pre_release with a last non-numeric identifier" do
          subject { Solve::Constraint.new("#{operator} 1.2.3-alpha") }

          it { should_not satisfies("1.2.3-4") }
          it { should_not satisfies("1.2.3--") }
          it { should satisfies("1.2.3-alpha") }
          it { should satisfies("1.2.3-alpha.0") }
          it { should satisfies("1.2.3-beta") }
          it { should satisfies("1.2.3-omega") }
          it { should satisfies("1.2.3-omega.4") }
          it { should_not satisfies("1.2.3") }
          it { should_not satisfies("1.3.0") }
        end

        context "when the last value in the constraint is for build with a last numeric identifier and a pre-release" do
          subject { Solve::Constraint.new("#{operator} 1.2.3-alpha+5") }

          it { should_not satisfies("1.2.3-alpha") }
          it { should_not satisfies("1.2.3-alpha.4") }
          it { should_not satisfies("1.2.3-alpha.4+4") }
          it { should satisfies("1.2.3-alpha+5") }
          it { should satisfies("1.2.3-alpha+5.5") }
          it { should satisfies("1.2.3-alpha+10") }
          it { should_not satisfies("1.2.3-alpha+-") }
          it { should_not satisfies("1.2.3-alpha+build") }
          it { should_not satisfies("1.2.3-beta") }
          it { should_not satisfies("1.2.3") }
          it { should_not satisfies("1.3.0") }
        end

        context "when the last value in the constraint is for build with a last non-numeric identifier and a pre-release" do
          subject { Solve::Constraint.new("#{operator} 1.2.3-alpha+build") }

          it { should_not satisfies("1.2.3-alpha") }
          it { should_not satisfies("1.2.3-alpha.4") }
          it { should_not satisfies("1.2.3-alpha.4+4") }
          it { should satisfies("1.2.3-alpha+build") }
          it { should satisfies("1.2.3-alpha+build.5") }
          it { should satisfies("1.2.3-alpha+preview") }
          it { should satisfies("1.2.3-alpha+zzz") }
          it { should_not satisfies("1.2.3-alphb") }
          it { should_not satisfies("1.2.3-beta") }
          it { should_not satisfies("1.2.3") }
          it { should_not satisfies("1.3.0") }
        end

        context "when the last value in the constraint is for build with a last numeric identifier" do
          subject { Solve::Constraint.new("#{operator} 1.2.3+5") }

          it { should_not satisfies("1.2.3") }
          it { should_not satisfies("1.2.3-alpha") }
          it { should_not satisfies("1.2.3+4") }
          it { should satisfies("1.2.3+5") }
          it { should satisfies("1.2.3+99") }
          it { should_not satisfies("1.2.3+5.build") }
          it { should_not satisfies("1.2.3+-") }
          it { should_not satisfies("1.2.3+build") }
          it { should_not satisfies("1.2.4") }
          it { should_not satisfies("1.3.0") }
        end

        context "when the last value in the constraint is for build with a last non-numeric identifier" do
          subject { Solve::Constraint.new("#{operator} 1.2.3+build") }

          it { should_not satisfies("1.2.3-alpha") }
          it { should_not satisfies("1.2.3") }
          it { should_not satisfies("1.2.3+5") }
          it { should satisfies("1.2.3+build") }
          it { should satisfies("1.2.3+build.5") }
          it { should satisfies("1.2.3+preview") }
          it { should satisfies("1.2.3+zzz") }
          it { should_not satisfies("1.2.4-0") }
          it { should_not satisfies("1.2.4") }
          it { should_not satisfies("1.2.5") }
          it { should_not satisfies("1.3.0") }
        end
      end
    end
  end

  describe "#eql?" do

    subject { Solve::Constraint.new("= 1.0.0") }

    it "returns true if the other object is a Solve::Constraint with the same operator and version" do
      other = Solve::Constraint.new("= 1.0.0")
      subject.should eql(other)
    end

    it "returns false if the other object is a Solve::Constraint with the same operator and different version" do
      other = Solve::Constraint.new("= 9.9.9")
      subject.should_not eql(other)
    end

    it "returns false if the other object is a Solve::Constraint with the same version and different operator" do
      other = Solve::Constraint.new("> 1.0.0")
      subject.should_not eql(other)
    end

    it "returns false if the other object is not a Solve::Constraint" do
      other = "chicken"
      subject.should_not eql(other)
    end
  end
end
