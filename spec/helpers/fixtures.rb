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

def first_request_eq(object_fixture, value)
  input  = object_fixture(object_fixture)
  output = RocketAMF.deserialize(input)

  request = output[:requests][0]

  expect(request).to eq(value)
end

def get_first_request(object_fixture)
  input  = object_fixture(object_fixture)
  output = RocketAMF.deserialize(input)

  requests = output[:requests]
  requests[0]
end