# encoding: UTF-8

require 'spec_helper.rb'
require 'rexml/document'
require 'bigdecimal'
require 'rational'

describe 'when serializing' do
  before :each do
    AMF::CLASS_MAPPER.reset
  end

  describe 'AMF3' do
    describe 'simple messages' do
      it 'should serialize a null' do
        expected = object_fixture('amf3-null.bin')
        output   = AMF.serialize(nil)
        expect(output).to eq(expected)
      end

      it 'should serialize a false' do
        expected = object_fixture('amf3-false.bin')
        output   = AMF.serialize(false)
        expect(output).to eq(expected)
      end

      it 'should serialize a true' do
        expected = object_fixture('amf3-true.bin')
        output   = AMF.serialize(true)
        expect(output).to eq(expected)
      end

      it 'should serialize integers' do
        expected = object_fixture('amf3-max.bin')
        input    = AMF::MAX_INTEGER
        output   = AMF.serialize(input)
        expect(output).to eq(expected)

        expected = object_fixture('amf3-0.bin')
        output   = AMF.serialize(0)
        expect(output).to eq(expected)

        expected = object_fixture('amf3-min.bin')
        input    = AMF::MIN_INTEGER
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize large integers' do
        expected = object_fixture('amf3-large-max.bin')
        input    = AMF::MAX_INTEGER + 1
        output   = AMF.serialize(input)
        expect(output).to eq(expected)

        expected = object_fixture('amf3-large-min.bin')
        input    = AMF::MIN_INTEGER - 1
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize floats' do
        expected = object_fixture('amf3-float.bin')
        input    = 3.5
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize BigNums' do
        expected = object_fixture('amf3-bigNum.bin')
        input    = 2**1000
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize float Numeric conformers' do
        expected = object_fixture('amf3-float.bin')
        input    = Rational(7, 2) # 3.5
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize a simple string' do
        expected = object_fixture('amf3-string.bin')
        input    = 'String . String'
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize a frozen string' do
        expected = object_fixture('amf3-string.bin')
        input    = 'String . String'.freeze
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize a symbol as a string' do
        expected = object_fixture('amf3-symbol.bin')
        output   = AMF.serialize(:foo)
        expect(output).to eq(expected)
      end

      it 'should serialize Time objects' do
        expected = object_fixture('amf3-date.bin')
        input    = Time.utc 1970, 1, 1, 0
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize Date objects' do
        expected = object_fixture('amf3-date.bin')
        input    = Date.civil 1970, 1, 1, 0
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize DateTime objects' do
        expected = object_fixture('amf3-date.bin')
        input    = DateTime.civil 1970, 1, 1, 0
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end
    end

    describe 'objects' do
      it 'should serialize an unmapped object as a dynamic anonymous object' do
        class NonMappedObject
          def another_public_property
            'a_public_value'
          end

          attr_accessor :nil_property
          attr_accessor :property_one
          attr_writer :read_only_prop

          def method_with_arg(arg = 'foo')
            arg
          end
        end
        obj              = NonMappedObject.new
        obj.property_one = 'foo'
        obj.nil_property = nil

        expected = object_fixture('amf3-dynamic-object.bin')
        input    = obj
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize a hash as a dynamic anonymous object' do
        hash          = {}
        hash[:answer] = 42
        hash['foo']   = 'bar'

        expected = object_fixture('amf3-hash.bin')
        input    = hash
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize an empty array' do
        expected = object_fixture('amf3-empty-array.bin')
        input    = []
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize an array of primatives' do
        expected = object_fixture('amf3-primitive-array.bin')
        input    = [1, 2, 3, 4, 5]
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize an array of mixed objects' do
        h1 = {:foo_one => 'bar_one'}
        h2 = {:foo_two => ''}
        class SimpleObj
          attr_accessor :foo_three
        end
        so1           = SimpleObj.new
        so1.foo_three = 42

        expected = object_fixture('amf3-mixed-array.bin')
        input    = [h1, h2, so1, {}, [h1, h2, so1], [], 42, '', [], '', {}, 'bar_one', so1]
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end



      it 'should serialize a byte array' do
        expected = object_fixture('amf3-byte-array.bin')
        str      = "\000\003これtest\100"
        str.force_encoding('ASCII-8BIT') if str.respond_to?(:force_encoding)
        input  = StringIO.new(str)
        output = AMF.serialize(input)
        expect(output).to eq(expected)
      end
    end

    describe 'and implementing the AMF Spec' do
      it 'should keep references of duplicate strings' do
        class StringCarrier
          attr_accessor :str
        end
        foo    = 'foo'
        bar    = 'str'
        sc     = StringCarrier.new
        sc.str = foo

        expected = object_fixture('amf3-string-ref.bin')
        input    = [foo, bar, foo, bar, foo, sc]
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should not reference the empty string' do
        expected = object_fixture('amf3-empty-string-ref.bin')
        input    = ''
        output   = AMF.serialize([input, input])
        expect(output).to eq(expected)
      end

      it 'should keep references of duplicate dates' do
        expected = object_fixture('amf3-date-ref.bin')
        input    = Time.utc 1970, 1, 1, 0
        output   = AMF.serialize([input, input])
        expect(output).to eq(expected)
      end

      it 'should keep reference of duplicate objects' do
        class SimpleReferenceableObj
          attr_accessor :foo
        end
        obj1     = SimpleReferenceableObj.new
        obj1.foo = :bar
        obj2     = SimpleReferenceableObj.new
        obj2.foo = obj1.foo

        expected = object_fixture('amf3-object-ref.bin')
        input    = [[obj1, obj2], 'bar', [obj1, obj2]]
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should keep reference of duplicate object traits' do
        obj1     = RubyClass.new
        obj1.foo = 'foo'

        def obj1.encode_amf(serializer)
          serializer.write_object(self, nil, {:class_name => 'org.amf.ASClass', :dynamic => false, :externalizable => false, :members => %w( baz foo )})
        end

        obj2     = RubyClass.new
        obj2.foo = 'bar'

        def obj2.encode_amf(serializer)
          serializer.write_object(self, nil, {:class_name => 'org.amf.ASClass', :dynamic => false, :externalizable => false, :members => %w( baz foo )})
        end

        input = [obj1, obj2]

        expected = object_fixture('amf3-trait-ref.bin')
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should keep references of duplicate arrays' do
        a = [1, 2, 3]
        b = %w{ a b c }

        expected = object_fixture('amf3-array-ref.bin')
        input    = [a, b, a, b]
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should not keep references of duplicate empty arrays unless the object_id matches' do
        a = []
        b = []
        expect(a).to eq(b)
        expect(a.object_id).not_to eq(b.object_id)

        expected = object_fixture('amf3-empty-array-ref.bin')
        input    = [a, b, a, b]
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should keep references of duplicate byte arrays' do
        b = StringIO.new 'ASDF'

        expected = object_fixture('amf3-byte-array-ref.bin')
        input    = [b, b]
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end

      it 'should serialize a deep object graph with circular references' do
        class GraphMember
          attr_accessor :children
          attr_accessor :parent

          def initialize
            self.children = []
          end

          def add_child(child)
            children << child
            child.parent = self
            child
          end
        end

        parent = GraphMember.new
        #level_1_child_1
        parent.add_child(GraphMember.new)
        #level_1_child_2
        parent.add_child(GraphMember.new)

        expected = object_fixture('amf3-graph-member.bin')
        input    = parent
        output   = AMF.serialize(input)
        expect(output).to eq(expected)
      end
    end

    describe 'and handling encodings', if: ''.respond_to?(:force_encoding) do
      it 'should support multiple encodings' do
        shift_str = "\x53\x68\x69\x66\x74\x20\x83\x65\x83\x58\x83\x67".force_encoding('Shift_JIS') # 'Shift テスト'
        utf_str   = "\x55\x54\x46\x20\xe3\x83\x86\xe3\x82\xb9\xe3\x83\x88".force_encoding('UTF-8') # 'UTF テスト'
        output    = AMF.serialize([5, shift_str, utf_str, 5])
        expect(output).to eq(object_fixture('amf3-complex-encoded-string-array.bin'))
      end

      it 'should keep references of duplicate strings with different encodings' do
        # String is 'this is a テスト'
        shift_str = "\x74\x68\x69\x73\x20\x69\x73\x20\x61\x20\x83\x65\x83\x58\x83\x67".force_encoding('Shift_JIS')
        utf_str   = "\x74\x68\x69\x73\x20\x69\x73\x20\x61\x20\xe3\x83\x86\xe3\x82\xb9\xe3\x83\x88".force_encoding('UTF-8')

        expected = object_fixture('amf3-encoded-string-ref.bin')
        output   = AMF.serialize([shift_str, utf_str])
        expect(output).to eq(expected)
      end

      it 'should handle inappropriate UTF-8 characters in byte arrays' do
        str = "\xff\xff\xff".force_encoding('ASCII-8BIT')
        str.freeze # For added amusement
        output = AMF.serialize(StringIO.new(str))
        expect(output).to eq("\x0c\x07\xff\xff\xff".force_encoding('ASCII-8BIT'))
      end
    end
  end
end