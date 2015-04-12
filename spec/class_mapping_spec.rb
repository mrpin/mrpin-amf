require 'spec_helper.rb'

describe AMF::ClassMapper do
  before :each do
    AMF::ClassMapper.reset
    AMF::ClassMapper.register_class_alias('ClassMappingTest', 'ASClass')

    @mapper = AMF::ClassMapper.new
  end

  describe 'class name mapping' do
    it 'should allow resetting of mappings back to defaults' do
      expect(@mapper.get_class_name_remote(ClassMappingTest.new)).not_to be_nil

      AMF::ClassMapper.reset

      @mapper = AMF::ClassMapper.new
      expect(@mapper.get_class_name_remote(ClassMappingTest.new)).to be_nil
    end

    it 'should return AS class name for ruby objects' do
      expect(@mapper.get_class_name_remote(ClassMappingTest.new)).to eq('ASClass')
      expect(@mapper.get_class_name_remote(AMF::HashWithType.new('ClassMappingTest'))).to eq('ASClass')
      expect(@mapper.get_class_name_remote('BadClass')).to be_nil
    end

    it 'should instantiate a ruby class' do
      expect(@mapper.create_object('ASClass')).to be_a(ClassMappingTest)
    end

    it 'should properly instantiate namespaced classes' do
      AMF::ClassMapper.register_class_alias('ANamespace::TestRubyClass', 'ASClass')
      @mapper = AMF::ClassMapper.new

      expect(@mapper.create_object('ASClass')).to be_a(ANamespace::TestRubyClass)
    end

    it 'should return a hash with original type if not mapped' do
      obj = @mapper.create_object('UnmappedClass')

      expect(obj).to be_a(AMF::HashWithType)
      expect(obj.class_type).to eq('UnmappedClass')
    end

    it 'should map special classes from AS by default' do
      as_classes =
          %w( )

      as_classes.each do |as_class|
        expect(@mapper.create_object(as_class)).not_to be_a(AMF::Types::HashWithType)
      end
    end

    it 'should allow config modification' do
      AMF::ClassMapper.register_class_alias('ClassMappingTest', 'SecondClass')
      @mapper = AMF::ClassMapper.new

      expect(@mapper.get_class_name_remote(ClassMappingTest.new)).to eq('SecondClass')
    end
  end

  describe 'ruby object populator' do
    it 'should populate a ruby class' do
      obj = @mapper.object_deserialize ClassMappingTest.new, {:prop_a => 'Data'}
      expect(obj.prop_a).to eq('Data')
    end

    it 'should populate a typed hash' do
      obj = @mapper.object_deserialize AMF::HashWithType.new('UnmappedClass'), {prop_a: 'Data'}
      expect(obj[:prop_a]).to eq('Data')
    end
  end

  describe 'property extractor' do
    it 'should extract hash properties' do
      hash  = {a: 'test1', 'b' => 'test2'}
      props = @mapper.object_serialize(hash)
      expect(props).to eq({'a' => 'test1', 'b' => 'test2'})
    end

    it 'should extract object properties' do
      obj        = ClassMappingTest.new
      obj.prop_a = 'Test A'

      hash = @mapper.object_serialize obj
      expect(hash).to eq({'prop_a' => 'Test A', 'prop_b' => nil})
    end

    it 'should extract inherited object properties' do
      obj        = ClassMappingTest2.new
      obj.prop_a = 'Test A'
      obj.prop_c = 'Test C'

      hash = @mapper.object_serialize obj
      expect(hash).to eq({'prop_a' => 'Test A', 'prop_b' => nil, 'prop_c' => 'Test C'})
    end
  end
end