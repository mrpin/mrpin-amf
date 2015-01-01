require 'spec_helper.rb'

describe RocketAMF::ClassMapping do
  before :each do
    RocketAMF::ClassMapping.reset
    RocketAMF::ClassMapping.define do |m|
      m.map as: 'ASClass', ruby: 'ClassMappingTest'
    end
    @mapper = RocketAMF::ClassMapping.new
  end

  describe 'class name mapping' do
    it 'should allow resetting of mappings back to defaults' do
      expect(@mapper.get_as_class_name('ClassMappingTest')).not_to be_nil

      RocketAMF::ClassMapping.reset

      @mapper = RocketAMF::ClassMapping.new
      expect(@mapper.get_as_class_name('ClassMappingTest')).to be_nil
      expect(@mapper.get_as_class_name('RocketAMF::Types::AcknowledgeMessage')).not_to be_nil
    end

    it 'should return AS class name for ruby objects' do
      expect(@mapper.get_as_class_name(ClassMappingTest.new)).to eq('ASClass')
      expect(@mapper.get_as_class_name('ClassMappingTest')).to eq('ASClass')
      expect(@mapper.get_as_class_name(RocketAMF::Types::TypedHash.new('ClassMappingTest'))).to eq('ASClass')
      expect(@mapper.get_as_class_name('BadClass')).to be_nil
    end

    it 'should instantiate a ruby class' do
      expect(@mapper.get_ruby_obj('ASClass')).to be_a(ClassMappingTest)
    end

    it 'should properly instantiate namespaced classes' do
      RocketAMF::ClassMapping.mappings.map as: 'ASClass', ruby: 'ANamespace::TestRubyClass'
      @mapper = RocketAMF::ClassMapping.new

      expect(@mapper.get_ruby_obj('ASClass')).to be_a(ANamespace::TestRubyClass)
    end

    it 'should return a hash with original type if not mapped' do
      obj = @mapper.get_ruby_obj('UnmappedClass')

      expect(obj).to be_a(RocketAMF::Types::TypedHash)
      expect(obj.type).to eq('UnmappedClass')
    end

    it 'should map special classes from AS by default' do
      as_classes =
          %w(
              flex.messaging.messages.AcknowledgeMessage
              flex.messaging.messages.CommandMessage
              flex.messaging.messages.RemotingMessage
            )

      as_classes.each do |as_class|
        expect(@mapper.get_ruby_obj(as_class)).not_to be_a(RocketAMF::Types::TypedHash)
      end
    end

    it 'should map special classes from ruby by default' do
      ruby_classes =
          %w(
              RocketAMF::Types::AcknowledgeMessage
              RocketAMF::Types::ErrorMessage
            )

      ruby_classes.each do |obj|
        expect(@mapper.get_as_class_name(obj)).not_to be_nil
      end
    end

    it 'should allow config modification' do
      RocketAMF::ClassMapping.mappings.map as: 'SecondClass', ruby: 'ClassMappingTest'
      @mapper = RocketAMF::ClassMapping.new

      expect(@mapper.get_as_class_name(ClassMappingTest.new)).to eq('SecondClass')
    end
  end

  describe 'ruby object populator' do
    it 'should populate a ruby class' do
      obj = @mapper.populate_ruby_obj ClassMappingTest.new, {:prop_a => 'Data'}
      expect(obj.prop_a).to eq('Data')
    end

    it 'should populate a typed hash' do
      obj = @mapper.populate_ruby_obj RocketAMF::Types::TypedHash.new('UnmappedClass'), {prop_a: 'Data'}
      expect(obj[:prop_a]).to eq('Data')
    end
  end

  describe 'property extractor' do
    it 'should extract hash properties' do
      hash  = {a: 'test1', 'b' => 'test2'}
      props = @mapper.props_for_serialization(hash)
      expect(props).to eq({'a' => 'test1', 'b' => 'test2'})
    end

    it 'should extract object properties' do
      obj        = ClassMappingTest.new
      obj.prop_a = 'Test A'

      hash = @mapper.props_for_serialization obj
      expect(hash).to eq({'prop_a' => 'Test A', 'prop_b' => nil})
    end

    it 'should extract inherited object properties' do
      obj        = ClassMappingTest2.new
      obj.prop_a = 'Test A'
      obj.prop_c = 'Test C'

      hash = @mapper.props_for_serialization obj
      expect(hash).to eq({'prop_a' => 'Test A', 'prop_b' => nil, 'prop_c' => 'Test C'})
    end
  end
end