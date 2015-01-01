# encoding: UTF-8

require 'spec_helper.rb'

describe 'when deserializing' do
  before :each do
    RocketAMF::CLASS_MAPPER.reset
  end

  describe 'AMF3' do
    it 'should update source pos if source is a StringIO object' do
      input = StringIO.new(object_fixture('amf3-null.bin'))
      expect(input.pos).to eq(0)

      RocketAMF.deserialize(input)

      expect(input.pos).to eq(1)
    end

    describe 'simple messages' do
      it 'should deserialize a null' do
        first_request_eq('amf3-null.bin', nil)
      end

      it 'should deserialize a false' do
        first_request_eq('amf3-false.bin', false)
      end

      it 'should deserialize a true' do
        first_request_eq('amf3-true.bin', true)
      end

      it 'should deserialize integers' do
        first_request_eq('amf3-max.bin', RocketAMF::MAX_INTEGER)
        first_request_eq('amf3-0.bin', 0)
        first_request_eq('amf3-min.bin', RocketAMF::MIN_INTEGER)
      end

      it 'should deserialize large integers' do
        first_request_eq('amf3-large-max.bin', RocketAMF::MAX_INTEGER + 1.0)
        first_request_eq('amf3-large-min.bin', RocketAMF::MIN_INTEGER - 1.0)
      end

      it 'should deserialize BigNums' do
        first_request_eq('amf3-bignum.bin', 2.0**1000)
      end

      it 'should deserialize a simple string' do
        first_request_eq('amf3-string.bin', 'String . String')
      end

      it 'should deserialize a symbol as a string' do
        first_request_eq('amf3-symbol.bin', 'foo')
      end

      it 'should deserialize dates' do
        first_request_eq('amf3-date.bin', Time.at(0))
      end

      it 'should deserialize XML' do
        # XMLDocument tag
        first_request_eq('amf3-xml-doc.bin', '<parent><child prop="test" /></parent>')

        # XML tag
        first_request_eq('amf3-xml.bin', '<parent><child prop="test"/></parent>')
      end
    end

    describe 'objects' do
      it 'should deserialize an unmapped object as a dynamic anonymous object' do

        value =
            {
                'property_one'            => 'foo',
                'nil_property'            => nil,
                'another_public_property' => 'a_public_value'
            }

        request = get_first_request('amf3-dynamic-object.bin')

        expect(request).to match(value)
        expect(request.type).to eq('')
      end

      it 'should deserialize a mapped object as a mapped ruby class instance' do
        RocketAMF::CLASS_MAPPER.define { |m| m.map :as => 'org.amf.ASClass', ruby: 'RubyClass' }

        request = get_first_request('amf3-typed-object.bin')

        expect(request).to be_a(RubyClass)
        expect(request.foo).to eq('bar')
        expect(request.baz).to eq(nil)
      end

      it 'should deserialize externalizable objects' do
        RocketAMF::CLASS_MAPPER.define { |m| m.map :as => 'ExternalizableTest', ruby: 'ExternalizableTest' }

        request = get_first_request('amf3-externalizable.bin')

        expect(request.length).to eq(2)
        expect(request[0].one).to eq(5)
        expect(request[1].two).to eq(5)
      end

      it 'should deserialize a hash as a dynamic anonymous object' do
        first_request_eq('amf3-hash.bin', {'foo' => 'bar', 'answer' => 42})
      end

      it 'should deserialize an empty array' do
        request = get_first_request('amf3-empty-array.bin')
        expect(request).to match_array([])
      end

      it 'should deserialize an array of primitives' do
        request = get_first_request('amf3-primitive-array.bin')
        expect(request).to match_array([1, 2, 3, 4, 5])
      end

      it 'should deserialize an associative array' do
        request = get_first_request('amf3-associative-array.bin')
        expect(request).to match({0 => 'bar1', 1 => 'bar2', 2 => 'bar3', 'asdf' => 'fdsa', 'foo' => 'bar', '42' => 'bar'})
      end

      it 'should deserialize an array of mixed objects' do
        request = get_first_request('amf3-mixed-array.bin')

        h1  = {'foo_one' => 'bar_one'}
        h2  = {'foo_two' => ''}
        so1 = {'foo_three' => 42}
        expect(request).to match_array([h1, h2, so1, {}, [h1, h2, so1], [], 42, '', [], '', {}, 'bar_one', so1])
      end

      it 'should deserialize an array collection as an array' do
        request = get_first_request('amf3-array-collection.bin')

        expect(request.class).to eq(Array)
        expect(request).to match_array(%w( foo bar ))
      end

      it 'should deserialize a complex set of array collections' do
        RocketAMF::CLASS_MAPPER.define { |m| m.map :as => 'org.amf.ASClass', ruby: 'RubyClass' }

        request = get_first_request('amf3-complex-array-collection.bin')

        expect(request[0]).to match_array(%w( foo bar ))
        expect(request[1][0]).to be_a(RubyClass)
        expect(request[1][1]).to be_a(RubyClass)
        expect(request[2]).to eq(request[1])
      end

      it 'should deserialize a byte array' do
        request = get_first_request('amf3-byte-array.bin')

        expect(request).to be_a(StringIO)
        expected = "\000\003これtest\100"
        expected.force_encoding('ASCII-8BIT') if expected.respond_to?(:force_encoding)
        expect(request.string).to eq(expected)
      end

      it 'should deserialize an empty dictionary' do
        request = get_first_request('amf3-empty-dictionary.bin')
        expect(request).to match({})
      end

      it 'should deserialize a dictionary' do
        request = get_first_request('amf3-dictionary.bin')

        keys = request.keys
        expect(keys.length).to eq(2)
        obj_key, str_key = keys[0].is_a?(RocketAMF::Types::TypedHash) ? [keys[0], keys[1]] : [keys[1], keys[0]]

        expect(obj_key.type).to eq('org.amf.ASClass')
        expect(request[obj_key]).to eq('asdf2')
        expect(str_key).to eq('bar')
        expect(request[str_key]).to eq('asdf1')
      end

      it 'should deserialize Vector.<int>' do
        request = get_first_request('amf3-vector-int.bin')
        expect(request).to match_array([4, -20, 12])
      end

      it 'should deserialize Vector.<uint>' do
        request = get_first_request('amf3-vector-uint.bin')
        expect(request).to match_array([4, 20, 12])
      end

      it 'should deserialize Vector.<Number>' do
        output = get_first_request('amf3-vector-double.bin')
        expect(output).to match_array([4.3, -20.6])
      end

      it 'should deserialize Vector.<Object>' do
        output = get_first_request('amf3-vector-object.bin')

        expect(output[0]['foo']).to eq('foo')
        expect(output[1].type).to eq('org.amf.ASClass')
        expect(output[2]['foo']).to eq('baz')
      end
    end

    describe 'and implementing the AMF Spec' do
      it 'should keep references of duplicate strings' do
        output = get_first_request('amf3-string-ref.bin')

        foo = 'foo'
        bar = 'str'
        expect(output).to match_array([foo, bar, foo, bar, foo, {'str' => 'foo'}])
      end

      it 'should not reference the empty string' do
        output = get_first_request('amf3-empty-string-ref.bin')
        expect(output).to match_array(['', ''])
      end

      it 'should keep references of duplicate dates' do
        output = get_first_request('amf3-date-ref.bin')

        expect(output[0]).to eq(Time.at(0))
        expect(output[0]).to eq(output[1])
        # Expected object:
        # [DateTime.parse '1/1/1970', DateTime.parse '1/1/1970']
      end

      it 'should keep reference of duplicate objects' do
        output = get_first_request('amf3-object-ref.bin')

        obj1 = {'foo' => 'bar'}
        obj2 = {'foo' => obj1['foo']}

        expect(output).to match_array([[obj1, obj2], 'bar', [obj1, obj2]])
      end

      it 'should keep reference of duplicate object traits' do
        RocketAMF::CLASS_MAPPER.define { |m| m.map :as => 'org.amf.ASClass', ruby: 'RubyClass' }

        output = get_first_request('amf3-trait-ref.bin')

        expect(output[0].foo).to eq('foo')
        expect(output[1].foo).to eq('bar')
      end

      it 'should keep references of duplicate arrays' do
        output = get_first_request('amf3-array-ref.bin')

        a = [1, 2, 3]
        b = %w{ a b c }
        expect(output).to match_array([a, b, a, b])
      end

      it 'should not keep references of duplicate empty arrays unless the object_id matches' do
        output = get_first_request('amf3-empty-array-ref.bin')

        a = []
        b = []
        expect(output).to match_array([a, b, a, b])
      end

      it 'should keep references of duplicate XML and XMLDocuments' do
        request = get_first_request('amf3-xml-ref.bin')
        expect(request).to match_array(['<parent><child prop="test"/></parent>', '<parent><child prop="test"/></parent>'])
      end

      it 'should keep references of duplicate byte arrays' do
        output = get_first_request('amf3-byte-array-ref.bin')

        expect(output[0].object_id).to eq(output[1].object_id)
        expect(output[0].string).to eq('ASDF')
      end

      it 'should deserialize a deep object graph with circular references' do

        output = get_first_request('amf3-graph-member.bin')

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