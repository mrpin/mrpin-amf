def request_fixture(binary_path)
  data = File.open(File.dirname(__FILE__) + '/../fixtures/request/' + binary_path, 'rb').read
  data.force_encoding('ASCII-8BIT') if data.respond_to?(:force_encoding)
  data
end

def object_fixture(binary_path)
  data = File.open(File.dirname(__FILE__) + '/../fixtures/objects/' + binary_path, 'rb').read
  data.force_encoding('ASCII-8BIT') if data.respond_to?(:force_encoding)
  data
end

def first_object_eq(object_fixture, value)
  input  = object_fixture(object_fixture)
  output = AMF.deserialize(input)

  first_object = output[:objects][0]

  expect(first_object).to eq(value)
end

def get_first_request(object_fixture)
  input  = object_fixture(object_fixture)
  output = AMF.deserialize(input)

  requests = output[:objects]
  requests[0]
end