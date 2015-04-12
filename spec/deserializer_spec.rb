# encoding: UTF-8

require 'spec_helper.rb'

describe 'when deserializing' do
  before :each do
    AMF.class_mapper.reset
  end

  describe 'AMF3' do
    it 'should update source pos if source is a StringIO object' do
      input = StringIO.new(object_fixture('simple/amf3-null.bin'))
      expect(input.pos).to eq(0)

      AMF.deserialize(input)

      expect(input.pos).to eq(1)
    end

    describe 'simple messages' do
      it 'should deserialize a null' do
        first_object_eq('simple/amf3-null.bin', nil)
      end

      it 'should deserialize a false' do
        first_object_eq('simple/amf3-false.bin', false)
      end

      it 'should deserialize a true' do
        first_object_eq('simple/amf3-true.bin', true)
      end

      it 'should deserialize integers' do
        first_object_eq('simple/amf3-max.bin', AMF::MAX_INTEGER)
        first_object_eq('simple/amf3-0.bin', 0)
        first_object_eq('simple/amf3-min.bin', AMF::MIN_INTEGER)
      end

      it 'should deserialize large integers' do
        first_object_eq('simple/amf3-large-max.bin', AMF::MAX_INTEGER + 1.0)
        first_object_eq('simple/amf3-large-min.bin', AMF::MIN_INTEGER - 1.0)
      end

      it 'should deserialize BigNums' do
        first_object_eq('simple/amf3-bignum.bin', 2.0**1000)
      end

      it 'should deserialize a simple string' do
        first_object_eq('simple/amf3-string.bin', 'String . String')
      end

      it 'should deserialize a symbol as a string' do
        first_object_eq('simple/amf3-symbol.bin', 'foo')
      end

    end

    describe 'objects' do

      it 'should deserialize dates' do
        first_object_eq('complex/amf3-date.bin', Time.at(0))
      end

      it 'should deserialize an unmapped object as a dynamic anonymous object' do

        value =
            {
                'property_one'            => 'foo',
                'nil_property'            => nil,
                'another_public_property' => 'a_public_value'
            }

        request = get_first_request('complex/amf3-dynamic-object.bin')

        expect(request).to match(value)
        expect(request.class_type).to eq('')
      end

      it 'should deserialize a mapped object as a mapped ruby class instance' do
        AMF.class_mapper.register_class_alias('RubyClass', 'org.amf.ASClass')

        request = get_first_request('complex/amf3-typed-object.bin')

        expect(request).to be_a(RubyClass)
        expect(request.foo).to eq('bar')
        expect(request.baz).to eq(nil)
      end

      it 'should deserialize a hash as a dynamic anonymous object' do
        first_object_eq('complex/amf3-hash.bin', {'foo' => 'bar', 'answer' => 42})
      end

      it 'should deserialize an empty array' do
        request = get_first_request('complex/amf3-empty-array.bin')
        expect(request).to match_array([])
      end

      it 'should deserialize an array of primitives' do
        request = get_first_request('complex/amf3-primitive-array.bin')
        expect(request).to match_array([1, 2, 3, 4, 5])
      end

      it 'should deserialize an associative array' do
        request = get_first_request('complex/amf3-associative-array.bin')
        expect(request).to match({0 => 'bar1', 1 => 'bar2', 2 => 'bar3', 'asdf' => 'fdsa', 'foo' => 'bar', '42' => 'bar'})
      end

      it 'should deserialize an array of mixed objects' do
        request = get_first_request('complex/amf3-mixed-array.bin')

        h1  = {'foo_one' => 'bar_one'}
        h2  = {'foo_two' => ''}
        so1 = {'foo_three' => 42}
        expect(request).to match_array([h1, h2, so1, {}, [h1, h2, so1], [], 42, '', [], '', {}, 'bar_one', so1])
      end

      it 'should deserialize a byte array' do
        request = get_first_request('complex/amf3-byte-array.bin')

        expect(request).to be_a(StringIO)
        expected = "\000\003これtest\100"
        expected.force_encoding('ASCII-8BIT') if expected.respond_to?(:force_encoding)
        expect(request.string).to eq(expected)
      end

      it 'should deserialize an empty dictionary' do
        request = get_first_request('complex/amf3-empty-dictionary.bin')
        expect(request).to match({})
      end

      it 'should deserialize a dictionary' do
        request = get_first_request('complex/amf3-dictionary.bin')

        keys = request.keys
        expect(keys.length).to eq(2)
        obj_key, str_key = keys[0].is_a?(AMF::HashWithType) ? [keys[0], keys[1]] : [keys[1], keys[0]]

        expect(obj_key.class_type).to eq('org.amf.ASClass')
        expect(request[obj_key]).to eq('asdf2')
        expect(str_key).to eq('bar')
        expect(request[str_key]).to eq('asdf1')
      end
    end

    describe 'and implementing the AMF references' do
      it 'should keep references of duplicate strings' do
        output = get_first_request('references/amf3-string-ref.bin')

        foo = 'foo'
        bar = 'str'
        expect(output).to match_array([foo, bar, foo, bar, foo, {'str' => 'foo'}])
      end

      it 'should not reference the empty string' do
        output = get_first_request('references/amf3-empty-string-ref.bin')
        expect(output).to match_array(['', ''])
      end

      it 'should keep references of duplicate dates' do
        output = get_first_request('references/amf3-date-ref.bin')

        expect(output[0]).to eq(Time.at(0))
        expect(output[0]).to eq(output[1])
        # Expected object:
        # [DateTime.parse '1/1/1970', DateTime.parse '1/1/1970']
      end

      it 'should keep reference of duplicate objects' do
        output = get_first_request('references/amf3-object-ref.bin')

        obj1 = {'foo' => 'bar'}
        obj2 = {'foo' => obj1['foo']}

        expect(output).to match_array([[obj1, obj2], 'bar', [obj1, obj2]])
      end

      it 'should keep reference of duplicate object traits' do
        AMF.class_mapper.register_class_alias('RubyClass', 'org.amf.ASClass')

        output = get_first_request('references/amf3-trait-ref.bin')

        expect(output[0].foo).to eq('foo')
        expect(output[0].class).to eq(RubyClass)

        expect(output[1].foo).to eq('bar')
        expect(output[1].class).to eq(RubyClass)
      end

      it 'should keep references of duplicate arrays' do
        output = get_first_request('references/amf3-array-ref.bin')

        a = [1, 2, 3]
        b = %w{ a b c }
        expect(output).to match_array([a, b, a, b])
      end

      it 'should not keep references of duplicate empty arrays unless the object_id matches' do
        output = get_first_request('references/amf3-empty-array-ref.bin')

        a = []
        b = []
        expect(output).to match_array([a, b, a, b])
      end

      it 'should keep references of duplicate byte arrays' do
        output = get_first_request('references/amf3-byte-array-ref.bin')

        expect(output[0].object_id).to eq(output[1].object_id)
        expect(output[0].string).to eq('ASDF')
      end

      it 'should deserialize a deep object graph with circular references' do

        output = get_first_request('references/amf3-graph-member.bin')

        expect(output['children'][0]['parent']).to eq(output)
        expect(output['parent']).to eq(nil)
        expect(output['children'].length).to eq(2)
        # Expected object:
        # parent = Hash.new
        # child1 = Hash.new
        # child1[:parent] = parent
        # child1[:children] = []
        # child2 = Hash.new
        # child2[:parent] = parent
        # child2[:children] = []
        # parent[:parent] = nil
        # parent[:children] = [child1, child2]
      end
    end
  end
end